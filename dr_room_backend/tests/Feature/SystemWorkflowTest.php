<?php

namespace Tests\Feature;

use App\Models\Coupon;
use App\Models\Driver;
use App\Models\Lab;
use App\Models\LabResult;
use App\Models\LabTest;
use App\Models\Nurse;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SystemWorkflowTest extends TestCase
{
    use RefreshDatabase;

    private function bearer(string $token): self
    {
        $this->app['auth']->forgetGuards();
        return $this->withToken($token);
    }

    private function createAdmin(): User
    {
        return User::create([
            'name' => 'Admin',
            'phone' => '07500000000',
            'email' => 'admin@drroom.com',
            'role' => 'admin',
            'status' => 'approved',
            'password' => Hash::make('admin123456'),
        ]);
    }

    private function createPatient(): User
    {
        return User::create([
            'name' => 'Patient',
            'phone' => '07501112222',
            'email' => 'patient@drroom.com',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('user123456'),
        ]);
    }

    public function test_patient_otp_login_and_coupon_validation_on_order(): void
    {
        $patient = $this->createPatient();

        $this->postJson('/api/login', [
            'phone' => '07501112222',
            'password' => 'user123456',
        ])->assertOk();

        $verify = $this->postJson('/api/verify-otp', [
            'phone' => '07501112222',
            'otp_code' => '1234',
        ])->assertOk();

        $token = $verify->json('access_token');
        $this->assertNotEmpty($token);

        Coupon::create([
            'code' => 'EXPIRED10',
            'title' => 'Expired',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'min_order_amount' => 0,
            'expires_at' => now()->subDay(),
            'is_active' => true,
        ]);

        // Expired coupon must be rejected with 422
        $this->withToken($token)->postJson('/api/orders', [
            'service_type' => 'pharmacy',
            'subtotal' => 20000,
            'extra_fee' => 2000,
            'total_price' => 20000,
            'coupon_code' => 'EXPIRED10',
            'payment_method' => 'cash',
            'items' => [['name' => 'Panadol', 'price' => 20000, 'quantity' => 1]],
        ])->assertStatus(422);

        Coupon::create([
            'code' => 'SAVE20',
            'title' => 'Valid 20%',
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'min_order_amount' => 10000,
            'is_active' => true,
        ]);

        // Valid coupon recalculates and applies discount accurately
        $okOrder = $this->withToken($token)->postJson('/api/orders', [
            'service_type' => 'pharmacy',
            'subtotal' => 20000,
            'extra_fee' => 2000,
            'total_price' => 999999, // server enforces subtotal + extra_fee - discount
            'coupon_code' => 'SAVE20',
            'payment_method' => 'cash',
            'items' => [['name' => 'Panadol', 'price' => 20000, 'quantity' => 1]],
        ])->assertStatus(201);

        $orderId = $okOrder->json('order.id');
        $order = Order::findOrFail($orderId);
        $this->assertEquals(4000.0, (float) $order->discount_amount);
        $this->assertEquals(18000.0, (float) $order->total_price);
        $this->assertEquals(1, Coupon::where('code', 'SAVE20')->value('used_count'));
        $this->assertEquals($patient->id, $order->patient_id);
    }

    public function test_driver_delivery_for_pharmacy_and_lab_sample_lifecycles(): void
    {
        $admin = $this->createAdmin();
        $patient = $this->createPatient();

        $labUser = User::create([
            'name' => 'Erbil Lab',
            'phone' => '07503330001',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('lab123456'),
        ]);
        $lab = Lab::create([
            'user_id' => $labUser->id,
            'city' => 'Erbil',
            'location' => '60m',
            'about_us' => 'Complete profile',
            'is_approved' => true,
        ]);

        // Register pending driver via web portal
        $this->post('/delivery/register', [
            'name' => 'Driver One',
            'phone' => '07508881111',
            'password' => 'driver123456',
            'password_confirmation' => 'driver123456',
            'city' => 'Erbil',
            'applicant_role' => 'courier',
            'vehicle_type' => 'motorcycle',
            'service_scope' => 'both',
            'agree_terms' => '1',
        ])->assertRedirect();

        $driverUser = User::where('phone', '07508881111')->firstOrFail();
        $this->assertEquals('pending', $driverUser->status);

        // Clear web session from /delivery/register before Admin API call
        Auth::guard('web')->logout();
        $this->flushSession();
        $adminToken = $admin->createToken('admin-test')->plainTextToken;
        $this->bearer($adminToken)
            ->patchJson("/api/admin/drivers/{$driverUser->id}/approve")
            ->assertOk();

        // Driver signs in directly without OTP
        $login = $this->postJson('/api/login', [
            'phone' => '07508881111',
            'password' => 'driver123456',
            'check_direct' => true,
        ])->assertOk()->assertJsonPath('direct_login', true);

        $driverToken = $login->json('access_token');

        $this->bearer($driverToken)->postJson('/api/driver/duty', ['duty_status' => 'available'])->assertOk();
        $this->bearer($driverToken)->postJson('/api/driver/location', ['lat' => 36.19, 'lng' => 44.01])->assertOk();

        // Patient places Pharmacy order & Lab order
        $patientToken = $patient->createToken('patient-test')->plainTextToken;
        $pharmOrder = $this->bearer($patientToken)->postJson('/api/orders', [
            'service_type' => 'pharmacy',
            'subtotal' => 15000,
            'extra_fee' => 3000,
            'total_price' => 18000,
            'payment_method' => 'cash',
            'items' => [['name' => 'Med A', 'price' => 15000, 'quantity' => 1]],
        ])->assertStatus(201)->json('order.id');

        $labOrder = $this->bearer($patientToken)->postJson('/api/orders', [
            'service_type' => 'lab_test',
            'subtotal' => 25000,
            'extra_fee' => 5000,
            'total_price' => 30000,
            'payment_method' => 'cash',
            'items' => [['name' => 'CBC', 'price' => 25000, 'quantity' => 1, 'extra_data' => ['lab_id' => $lab->id]]],
        ])->assertStatus(201)->json('order.id');

        // Driver completes Pharmacy order -> order & transaction become completed
        $this->bearer($driverToken)->postJson("/api/driver/orders/{$pharmOrder}/claim")->assertOk();
        foreach (['picked_up', 'on_the_way', 'arrived', 'delivered'] as $st) {
            $this->bearer($driverToken)->postJson("/api/driver/orders/{$pharmOrder}/status", ['delivery_status' => $st])->assertOk();
        }
        $this->assertEquals('completed', Order::findOrFail($pharmOrder)->status);
        $this->assertEquals('completed', Transaction::where('payable_id', $pharmOrder)->value('status'));

        // Double delivery guard
        $this->bearer($driverToken)->postJson("/api/driver/orders/{$pharmOrder}/status", ['delivery_status' => 'delivered'])->assertStatus(422);

        // Driver delivers Lab sample -> delivery_status=delivered, order remains in_progress for Lab
        $this->bearer($driverToken)->postJson("/api/driver/orders/{$labOrder}/claim")->assertOk();
        foreach (['picked_up', 'on_the_way', 'arrived', 'delivered'] as $st) {
            $this->bearer($driverToken)->postJson("/api/driver/orders/{$labOrder}/status", ['delivery_status' => $st])->assertOk();
        }

        $labOrderModel = Order::findOrFail($labOrder);
        $this->assertEquals('delivered', $labOrderModel->delivery_status);
        $this->assertEquals('in_progress', $labOrderModel->status);

        // Driver dashboard moves delivered lab order to completed_orders and frees driver duty
        $dash = $this->bearer($driverToken)->getJson('/api/driver/dashboard')->assertOk();
        $this->assertCount(0, $dash->json('data.active_orders'));
        $this->assertCount(2, $dash->json('data.completed_orders'));
        $this->assertEquals('available', Driver::where('user_id', $driverUser->id)->value('duty_status'));
    }

    public function test_lab_multi_tenancy_and_result_completion_flow(): void
    {
        $patient = $this->createPatient();

        $labAUser = User::create([
            'name' => 'Lab A',
            'phone' => '07504440001',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('lab123456'),
        ]);
        $labA = Lab::create([
            'user_id' => $labAUser->id,
            'city' => 'Erbil',
            'location' => 'Erbil A',
            'about_us' => 'Lab A Bio',
            'is_approved' => true,
        ]);

        $labBUser = User::create([
            'name' => 'Lab B',
            'phone' => '07504440002',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('lab123456'),
        ]);
        Lab::create([
            'user_id' => $labBUser->id,
            'city' => 'Erbil',
            'location' => 'Erbil B',
            'about_us' => 'Lab B Bio',
            'is_approved' => true,
        ]);

        $orderId = $this->actingAs($patient, 'sanctum')->postJson('/api/orders', [
            'service_type' => 'lab_test',
            'subtotal' => 20000,
            'extra_fee' => 0,
            'total_price' => 20000,
            'payment_method' => 'cash',
            'items' => [['name' => 'CBC', 'price' => 20000, 'quantity' => 1, 'extra_data' => ['lab_id' => $labA->id]]],
        ])->assertStatus(201)->json('order.id');

        // Lab B cannot see or mutate Lab A's assigned order
        $this->actingAs($labBUser, 'web')
            ->patch("/lab/orders/{$orderId}/status", ['status' => 'confirmed'])
            ->assertStatus(403);

        // Lab A creates test, updates status, publishes result -> completes order & transaction
        $test = LabTest::create([
            'lab_id' => $labA->id,
            'name' => 'CBC',
            'price' => 20000,
            'type' => 'blood',
            'is_active' => true,
        ]);

        $this->actingAs($labAUser, 'web')
            ->get('/lab/patients')
            ->assertOk()
            ->assertSee('CBC');

        $this->actingAs($labAUser, 'web')
            ->post('/lab/results', [
                'patient_id' => $patient->id,
                'order_id' => $orderId,
                'test_id' => $test->id,
                'result_value' => 'Normal',
                'status' => 'completed',
            ])->assertRedirect();

        $this->assertEquals('completed', Order::findOrFail($orderId)->status);
        $this->assertEquals('completed', Transaction::where('payable_id', $orderId)->value('status'));
        $this->assertDatabaseHas('lab_results', ['lab_id' => $labA->id, 'patient_id' => $patient->id, 'status' => 'completed']);
    }

    public function test_nurse_home_nursing_visibility_atomic_accept_and_completion(): void
    {
        $patient = $this->createPatient();

        $nurseAUser = User::create([
            'name' => 'Nurse A',
            'phone' => '07505550001',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('nurse123456'),
        ]);
        Nurse::create(['user_id' => $nurseAUser->id, 'specialty' => 'Home Care', 'fee' => 25000, 'is_approved' => true]);

        $nurseBUser = User::create([
            'name' => 'Nurse B',
            'phone' => '07505550002',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('nurse123456'),
        ]);
        Nurse::create(['user_id' => $nurseBUser->id, 'specialty' => 'Home Care', 'fee' => 25000, 'is_approved' => true]);

        // Patient places a home_nursing order (previously invisible in Nurse Web Dashboard!)
        $orderId = $this->actingAs($patient, 'sanctum')->postJson('/api/orders', [
            'service_type' => 'home_nursing',
            'subtotal' => 25000,
            'extra_fee' => 0,
            'total_price' => 25000,
            'payment_method' => 'cash',
            'items' => [['name' => 'IV Cannula', 'price' => 25000, 'quantity' => 1]],
        ])->assertStatus(201)->json('order.id');

        $this->actingAs($nurseAUser, 'web')
            ->get('/nurse/dashboard')
            ->assertOk();

        // Nurse A accepts unassigned home_nursing request
        $this->actingAs($nurseAUser, 'web')
            ->post("/nurse/appointments/{$orderId}/accept")
            ->assertRedirect();

        $this->assertEquals($nurseAUser->id, Order::findOrFail($orderId)->assigned_nurse_id);

        // Nurse B cannot steal or update Nurse A's request
        $this->actingAs($nurseBUser, 'web')
            ->patch("/nurse/appointments/{$orderId}/status", ['status' => 'completed'])
            ->assertStatus(403);

        // Nurse A completes appointment -> transaction settles
        $this->actingAs($nurseAUser, 'web')
            ->patch("/nurse/appointments/{$orderId}/status", ['status' => 'completed'])
            ->assertRedirect();

        $this->assertEquals('completed', Order::findOrFail($orderId)->status);
        $this->assertEquals('completed', Transaction::where('payable_id', $orderId)->value('status'));
    }
}

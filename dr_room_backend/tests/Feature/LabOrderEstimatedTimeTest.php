<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Lab;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LabOrderEstimatedTimeTest extends TestCase
{
    use RefreshDatabase;

    public function test_lab_can_set_estimated_time_with_status_and_api_returns_localized_labels(): void
    {
        $patient = User::create([
            'name' => 'Patient One',
            'phone' => '07501119999',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('user123456'),
        ]);

        $labUser = User::create([
            'name' => 'Test Lab',
            'phone' => '07503339999',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('lab123456'),
        ]);

        Lab::create([
            'user_id' => $labUser->id,
            'city' => 'Erbil',
            'location' => '60m',
            'about_us' => 'Complete profile',
            'is_approved' => true,
        ]);

        $order = Order::create([
            'patient_id' => $patient->id,
            'service_type' => 'lab',
            'subtotal' => 25000,
            'extra_fee' => 0,
            'total_price' => 25000,
            'status' => 'pending',
            'payment_method' => 'cash',
            'assigned_lab_id' => $labUser->id,
        ]);

        // Lab sets status to in_progress along with 90 minutes estimated duration
        $this->actingAs($labUser, 'web')
            ->patch(route('lab.orders.update_status', $order), [
                'status' => 'in_progress',
                'estimated_duration_minutes' => 90,
            ])
            ->assertRedirect();

        $order->refresh();
        $this->assertSame('in_progress', $order->status);
        $this->assertSame(90, $order->estimated_duration_minutes);
        $this->assertNotNull($order->estimated_ready_at);

        // Notification message mentions estimated time
        $notif = AppNotification::where('user_id', $patient->id)->latest('id')->first();
        $this->assertNotNull($notif);
        $this->assertStringContainsString('1 کاتژمێر و 30 خولەک', $notif->message);
        $this->assertStringContainsString('1 hr 30 min', $notif->message_en);

        // Switch from web lab session to patient Sanctum token
        Auth::guard('web')->logout();
        $this->flushSession();
        $this->app['auth']->forgetGuards();

        // API /orders and /orders/{id} return localized estimated time fields
        $patientToken = $patient->createToken('patient-app')->plainTextToken;

        $ordersRes = $this->withToken($patientToken)
            ->withHeaders(['Accept-Language' => 'en'])
            ->getJson('/api/orders?lang=en')
            ->assertOk()
            ->assertJsonPath('data.0.id', $order->id)
            ->assertJsonPath('data.0.estimated_duration_minutes', 90)
            ->assertJsonPath('data.0.estimated_duration_label', '1 hr 30 min')
            ->assertJsonPath('data.0.estimated_duration_labels.ckb', '1 کاتژمێر و 30 خولەک')
            ->assertJsonPath('data.0.estimated_duration_labels.kmr', '1 دەمژمێر و 30 خولەک')
            ->assertJsonPath('data.0.estimated_duration_labels.ar', '1 ساعة و 30 دقيقة')
            ->assertJsonPath('data.0.estimated_duration_labels.en', '1 hr 30 min');

        $remSecs = $ordersRes->json('data.0.estimated_remaining_seconds');
        $this->assertIsInt($remSecs);
        $this->assertGreaterThan(5300, $remSecs);
        $this->assertLessThanOrEqual(5400, $remSecs);

        $this->withToken($patientToken)
            ->withHeaders(['Accept-Language' => 'ckb'])
            ->getJson("/api/orders/{$order->id}?lang=ckb")
            ->assertOk()
            ->assertJsonPath('data.estimated_duration_minutes', 90)
            ->assertJsonPath('data.estimated_duration_label', '1 کاتژمێر و 30 خولەک');

        $this->app['auth']->forgetGuards();

        // Updating status without sending estimated_duration_minutes keeps duration, and completed clears estimated_ready_at
        $this->actingAs($labUser, 'web')
            ->patch(route('lab.orders.update_status', $order), [
                'status' => 'completed',
            ])
            ->assertRedirect();

        $order->refresh();
        $this->assertSame('completed', $order->status);
        $this->assertSame(90, $order->estimated_duration_minutes);
        $this->assertNull($order->estimated_ready_at);
    }
}

<?php

namespace Tests\Feature;

use App\Models\Driver;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DriverEarningsResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_driver_profile_and_earnings_reset_syncs_with_driver_dashboard(): void
    {
        $admin = User::create([
            'name' => 'Admin',
            'phone' => '07500000000',
            'email' => 'admin@drroom.com',
            'role' => 'admin',
            'status' => 'approved',
            'password' => Hash::make('admin123456'),
        ]);

        $patient = User::create([
            'name' => 'Patient A',
            'phone' => '07501112222',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('user123456'),
        ]);

        $driverUser = User::create([
            'name' => 'Driver One',
            'phone' => '07509998877',
            'role' => 'driver',
            'status' => 'approved',
            'password' => Hash::make('driver123456'),
        ]);

        $driver = Driver::create([
            'user_id' => $driverUser->id,
            'city' => 'هەولێر',
            'duty_status' => 'available',
            'completed_deliveries' => 2,
            'total_earnings' => 5500,
        ]);

        Order::create([
            'patient_id' => $patient->id,
            'assigned_driver_id' => $driverUser->id,
            'service_type' => 'lab_test',
            'subtotal' => 10900,
            'extra_fee' => 2500,
            'total_price' => 13400,
            'delivery_fee' => 2500,
            'payment_method' => 'cash',
            'status' => 'in_progress',
            'delivery_status' => 'delivered',
            'driver_delivered_at' => now()->subMinutes(10),
        ]);

        Order::create([
            'patient_id' => $patient->id,
            'assigned_driver_id' => $driverUser->id,
            'service_type' => 'pharmacy',
            'subtotal' => 20000,
            'extra_fee' => 3000,
            'total_price' => 23000,
            'delivery_fee' => 3000,
            'payment_method' => 'fib',
            'status' => 'completed',
            'delivery_status' => 'delivered',
            'driver_delivered_at' => now()->subMinutes(5),
        ]);

        $adminToken = $admin->createToken('admin')->plainTextToken;
        $driverToken = $driverUser->createToken('driver')->plainTextToken;

        // 1. Admin views driver profile before reset
        $this->withToken($adminToken)
            ->getJson("/api/admin/drivers/{$driverUser->id}/profile")
            ->assertOk()
            ->assertJsonPath('data.finance.total_deliveries', 2)
            ->assertJsonPath('data.finance.total_earnings', 5500)
            ->assertJsonPath('data.finance.cash_total_count', 1)
            ->assertJsonPath('data.finance.cash_total_collected', 13400)
            ->assertJsonPath('data.finance.online_total_count', 1);

        // 2. Driver dashboard sees the same pre-reset figures
        $this->app['auth']->forgetGuards();
        $this->withToken($driverToken)
            ->getJson('/api/driver/dashboard')
            ->assertOk()
            ->assertJsonPath('data.stats.total_deliveries', 2)
            ->assertJsonPath('data.stats.total_earnings', 5500)
            ->assertJsonPath('data.stats.cash_total_collected', 13400)
            ->assertJsonPath('data.completed_orders.0.is_settled', false);

        // 3. Admin resets driver earnings & cash
        $this->app['auth']->forgetGuards();
        $this->withToken($adminToken)
            ->postJson("/api/admin/drivers/{$driverUser->id}/reset-earnings")
            ->assertOk()
            ->assertJsonPath('reset_before.cash_total_collected', 13400)
            ->assertJsonPath('finance.total_deliveries', 0)
            ->assertJsonPath('finance.total_earnings', 0)
            ->assertJsonPath('finance.cash_total_collected', 0)
            ->assertJsonPath('finance.lifetime_deliveries', 2)
            ->assertJsonPath('finance.lifetime_cash_collected', 13400);

        // 4. Driver dashboard immediately shows 0 and marks older orders settled
        $this->app['auth']->forgetGuards();
        $this->withToken($driverToken)
            ->getJson('/api/driver/dashboard')
            ->assertOk()
            ->assertJsonPath('data.stats.total_deliveries', 0)
            ->assertJsonPath('data.stats.total_earnings', 0)
            ->assertJsonPath('data.stats.cash_total_collected', 0)
            ->assertJsonPath('data.completed_orders.0.is_settled', true);

        // 5. A new cash order delivered after reset counts from 0
        Carbon::setTestNow(now()->addSeconds(5));
        Order::create([
            'patient_id' => $patient->id,
            'assigned_driver_id' => $driverUser->id,
            'service_type' => 'lab_test',
            'subtotal' => 15000,
            'extra_fee' => 2500,
            'total_price' => 17500,
            'delivery_fee' => 2500,
            'payment_method' => 'cash',
            'status' => 'in_progress',
            'delivery_status' => 'delivered',
            'driver_delivered_at' => now(),
        ]);
        Carbon::setTestNow();

        $this->app['auth']->forgetGuards();
        $this->withToken($driverToken)
            ->getJson('/api/driver/dashboard')
            ->assertOk()
            ->assertJsonPath('data.stats.total_deliveries', 1)
            ->assertJsonPath('data.stats.total_earnings', 2500)
            ->assertJsonPath('data.stats.cash_total_collected', 17500);
    }
}

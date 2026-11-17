<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class DriverApprovalNotificationTest extends TestCase
{
    use RefreshDatabase;

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

    private function createPendingDriver(): User
    {
        $user = User::create([
            'name' => 'tester',
            'phone' => '07512596050',
            'role' => 'driver',
            'status' => 'pending',
            'password' => Hash::make('driver123456'),
        ]);

        Driver::create([
            'user_id' => $user->id,
            'city' => 'هەولێر',
            'duty_status' => 'offline',
        ]);

        return $user;
    }

    public function test_approving_driver_sends_custom_sms_and_creates_notification(): void
    {
        config([
            'services.otpiq.key' => 'test-otpiq-key',
            'services.otpiq.provider' => 'auto',
            'services.otpiq.sender_id' => 'DrRoom',
        ]);

        Http::fake([
            'https://api.otpiq.com/api/sms' => Http::response(['message' => 'sent'], 200),
        ]);

        $admin = $this->createAdmin();
        $driver = $this->createPendingDriver();
        $token = $admin->createToken('admin-test')->plainTextToken;

        $response = $this->withToken($token)
            ->patchJson("/api/admin/drivers/{$driver->id}/approve");

        $response->assertOk()
            ->assertJsonPath('sms_sent', true)
            ->assertJsonPath('sms_error', null)
            ->assertJsonPath('user.status', 'approved');

        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $driver->id,
            'type' => 'system',
        ]);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://api.otpiq.com/api/sms'
                && $request['phoneNumber'] === '9647512596050'
                && $request['smsType'] === 'custom'
                && $request['senderId'] === 'DrRoom'
                && str_contains($request['customMessage'], 'tester')
                && str_contains($request['customMessage'], 'پەسەندکرا');
        });
    }

    public function test_approving_driver_still_succeeds_if_sms_provider_fails(): void
    {
        config([
            'services.otpiq.key' => 'test-otpiq-key',
            'services.otpiq.provider' => 'sms',
            'services.otpiq.sender_id' => null,
        ]);

        Http::fake([
            'https://api.otpiq.com/api/sms' => Http::response(['error' => 'Sender ID required'], 400),
        ]);

        $admin = $this->createAdmin();
        $driver = $this->createPendingDriver();
        $token = $admin->createToken('admin-test')->plainTextToken;

        $response = $this->withToken($token)
            ->patchJson("/api/admin/drivers/{$driver->id}/approve");

        $response->assertOk()
            ->assertJsonPath('sms_sent', false)
            ->assertJsonPath('sms_error', 'Sender ID required')
            ->assertJsonPath('user.status', 'approved');

        $this->assertSame('approved', $driver->fresh()->status);
        $this->assertSame(1, AppNotification::where('user_id', $driver->id)->count());
    }
}

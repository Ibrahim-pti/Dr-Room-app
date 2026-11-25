<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminSettingsEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private function createUser(string $role, ?array $permissions = null): User
    {
        return User::create([
            'name' => ucfirst($role) . ' User',
            'phone' => '0750' . rand(1000000, 9999999),
            'email' => $role . rand(100, 999) . '@drroom.com',
            'role' => $role,
            'status' => 'approved',
            'permissions' => $permissions,
            'password' => Hash::make('password123'),
        ]);
    }

    public function test_all_admin_settings_menu_endpoints_respond_properly(): void
    {
        $admin = $this->createUser('admin');

        // 1. Report Settings
        $this->actingAs($admin)->getJson('/api/admin/report-settings')->assertOk();
        $this->actingAs($admin)->postJson('/api/admin/report-settings', [
            'header_title' => 'Dr Room Test Header',
            'show_watermark' => true,
            'show_stamp' => true,
            'show_signature' => false,
        ])->assertOk();

        // 2. Service Fee (Admin write + Public read sync)
        $this->actingAs($admin)->postJson('/api/admin/service-fee', [
            'is_enabled' => true,
            'is_free' => false,
            'amount' => 2500,
            'has_discount' => true,
            'discount_percent' => 20,
            'discount_amount' => 0,
            'note' => 'Updated fee',
        ])->assertOk();

        $this->getJson('/api/service-fee')
            ->assertOk()
            ->assertJsonPath('data.amount', 2500)
            ->assertJsonPath('data.discount_percent', 20);

        // 3. Commission
        $this->actingAs($admin)->getJson('/api/admin/commission/settings')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/commission/summary')->assertOk();

        // 4. Lab Results Monitor
        $this->actingAs($admin)->getJson('/api/admin/lab-results')->assertOk();

        // 5. Reviews
        $this->actingAs($admin)->getJson('/api/admin/reviews')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/reviews?min_rating=2')->assertOk();

        // 6. Emergency Contacts
        $createEmergency = $this->actingAs($admin)->postJson('/api/admin/emergency-contacts', [
            'title' => 'West Emergency',
            'phone' => '122',
            'icon_type' => 'ambulance',
            'is_primary' => true,
            'is_active' => true,
        ])->assertCreated();
        $emId = $createEmergency->json('contact.id') ?? $createEmergency->json('data.id') ?? $createEmergency->json('id');
        $this->actingAs($admin)->getJson('/api/admin/emergency-contacts')->assertOk();
        if ($emId) {
            $this->actingAs($admin)->patchJson("/api/admin/emergency-contacts/{$emId}/toggle")->assertOk();
            $this->actingAs($admin)->deleteJson("/api/admin/emergency-contacts/{$emId}")->assertOk();
        }

        // 7. Budget & Expenses
        $expRes = $this->actingAs($admin)->postJson('/api/admin/expenses', [
            'title' => 'Lab Kits',
            'category' => 'lab_supplies',
            'amount' => 50000,
            'expense_date' => '2026-11-25',
            'notes' => 'Monthly stock',
        ])->assertCreated();
        $expId = $expRes->json('data.id');
        $this->actingAs($admin)->postJson('/api/admin/expenses/budget', [
            'amount' => 300000,
            'year' => 2026,
            'month' => 11,
        ])->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/expenses?year=2026&month=11')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/expenses/summary?year=2026&month=11')
            ->assertOk()
            ->assertJsonPath('data.monthly_budget', 300000);
        $this->actingAs($admin)->putJson("/api/admin/expenses/{$expId}", [
            'title' => 'Lab Kits Updated',
            'category' => 'lab_supplies',
            'amount' => 55000,
            'expense_date' => '2026-11-25',
        ])->assertOk();
        $this->actingAs($admin)->deleteJson("/api/admin/expenses/{$expId}")->assertOk();

        // 8. Patients, Recruitment Options, Staff, Activity Logs
        $this->actingAs($admin)->getJson('/api/admin/patients')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/recruitment-options')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/staff')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/staff/meta')->assertOk();
        $this->actingAs($admin)->getJson('/api/admin/activity-logs')->assertOk();
    }

    public function test_staff_permissions_enforced_for_activity_logs_and_content(): void
    {
        $logOnlyStaff = $this->createUser('staff', ['view_logs']);
        $noLogStaff = $this->createUser('staff', ['manage_staff']);

        $this->actingAs($logOnlyStaff)->getJson('/api/admin/activity-logs')->assertOk();
        $this->actingAs($noLogStaff)->getJson('/api/admin/activity-logs')->assertForbidden();
        $this->actingAs($noLogStaff)->getJson('/api/admin/staff')->assertOk();
    }
}

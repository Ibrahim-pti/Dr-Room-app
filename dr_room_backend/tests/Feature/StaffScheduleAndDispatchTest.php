<?php

namespace Tests\Feature;

use App\Models\Driver;
use App\Models\Order;
use App\Models\ProviderSchedule;
use App\Models\User;
use App\Services\DriverDispatchService;
use App\Services\ProviderSlotService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class StaffScheduleAndDispatchTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function createAdmin(): User
    {
        return User::create([
            'name' => 'Admin',
            'phone' => '07500000001',
            'role' => 'admin',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);
    }

    private function createPatient(): User
    {
        return User::create([
            'name' => 'Patient One',
            'phone' => '07501111111',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);
    }

    private function createApprovedStaff(
        string $name,
        string $phone,
        string $applicantRole,
        string $shift,
        string $workDays,
        string $duty = 'available',
        string $scope = 'lab_sample'
    ): User {
        $user = User::create([
            'name' => $name,
            'phone' => $phone,
            'role' => 'driver',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);

        Driver::create([
            'user_id' => $user->id,
            'city' => 'هەولێر',
            'vehicle_type' => 'car',
            'service_scope' => $scope,
            'duty_status' => $duty,
            'applicant_role' => $applicantRole,
            'availability_shift' => $shift,
            'work_days' => $workDays,
            'current_lat' => 36.1911,
            'current_lng' => 44.0092,
        ]);

        ProviderSlotService::seedFromDriverProfile($user->id, $shift, $workDays);

        return $user;
    }

    public function test_website_shifts_seed_correctly_and_timezone_enforces_baghdad_shift(): void
    {
        $admin = $this->createAdmin();

        $morningStaff = $this->createApprovedStaff('Morning Staff', '07502220001', 'phlebotomist', 'morning', 'weekdays');
        $eveningStaff = $this->createApprovedStaff('Evening Staff', '07502220002', 'phlebotomist', 'evening', 'part_time');

        // At 10:00 Asia/Baghdad on Thursday: morning is ON shift, evening is OFF shift
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 10, 0, 0, 'Asia/Baghdad')->utc());
        $this->assertTrue(ProviderSlotService::isOnShift($morningStaff->id));
        $this->assertFalse(ProviderSlotService::isOnShift($eveningStaff->id));

        // At 23:15 Asia/Baghdad on Thursday (20:15 UTC): BOTH are OFF shift!
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 23, 15, 0, 'Asia/Baghdad')->utc());
        $this->assertFalse(ProviderSlotService::isOnShift($morningStaff->id));
        $this->assertFalse(ProviderSlotService::isOnShift($eveningStaff->id));

        // Verify Admin Staff Schedule summary payload
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 15, 0, 0, 'Asia/Baghdad')->utc());
        $res = $this->actingAs($admin)->getJson('/api/admin/schedules/providers?type=driver');
        $res->assertOk()->assertJsonPath('success', true);

        $rows = collect($res->json('data'))->keyBy('id');
        $this->assertEquals('08:00', $rows[$morningStaff->id]['start_time']);
        $this->assertEquals('14:00', $rows[$morningStaff->id]['end_time']);
        $this->assertEquals(6, $rows[$morningStaff->id]['active_days']);
        $this->assertFalse($rows[$morningStaff->id]['is_on_shift_now']);
        $this->assertTrue($rows[$morningStaff->id]['schedule_matches_website']);

        $this->assertEquals('14:00', $rows[$eveningStaff->id]['start_time']);
        $this->assertEquals('22:00', $rows[$eveningStaff->id]['end_time']);
        $this->assertEquals(3, $rows[$eveningStaff->id]['active_days']);
        $this->assertTrue($rows[$eveningStaff->id]['is_on_shift_now']);
    }

    public function test_scheduled_half_hour_lab_order_dispatches_to_matching_on_shift_driver(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 9, 0, 0, 'Asia/Baghdad')->utc());
        $patient = $this->createPatient();

        $morningDriver = $this->createApprovedStaff('Morning Lab', '07503330001', 'phlebotomist', 'morning', 'daily');
        $eveningDriver = $this->createApprovedStaff('Evening Lab', '07503330002', 'phlebotomist', 'evening', 'daily');

        // Tomorrow (Friday) 14:30 Asia/Baghdad -> Morning driver ends at 14:00, Evening driver works 14:00-22:00
        $scheduledStr = '2026-11-27 14:30';

        // Pool availability for lab must include evening hours from the evening phlebotomist
        $availRes = $this->getJson('/api/schedules/availability?type=lab&days=2');
        $availRes->assertOk();
        $friday = collect($availRes->json('data.days'))->firstWhere('date', '2026-11-27');
        $this->assertNotNull($friday);
        $this->assertFalse($friday['closed']);

        $order = Order::create([
            'patient_id' => $patient->id,
            'service_type' => 'lab',
            'subtotal' => 25000,
            'extra_fee' => 2500,
            'total_price' => 27500,
            'status' => 'pending',
            'scheduled_at' => ProviderSlotService::parseWallClock($scheduledStr),
            'patient_details' => ['collection_method' => 'home', 'lat' => 36.1911, 'lng' => 44.0092],
            'location_details' => ['address' => 'Erbil 100m'],
        ]);

        $assigned = app(DriverDispatchService::class)->dispatchNearest($order);
        $this->assertNotNull($assigned);
        $this->assertSame($eveningDriver->id, $assigned->id);
        $this->assertNotSame($morningDriver->id, $assigned->id);
    }

    public function test_admin_and_driver_schedule_edits_sync_everywhere(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 10, 0, 0, 'Asia/Baghdad')->utc());
        $admin = $this->createAdmin();
        $staff = $this->createApprovedStaff('Field Nurse', '07504440001', 'mobile_nurse', 'full_flex', 'daily', 'available', 'both');

        // Admin shortens Thursday to 09:00-13:00
        $week = ProviderSlotService::week($staff->id, 'driver');
        foreach ($week as &$day) {
            if ($day['day_of_week'] === 'Thursday') {
                $day['start_time'] = '09:00';
                $day['end_time'] = '13:00';
            }
        }
        unset($day);

        $this->actingAs($admin)
            ->postJson("/api/admin/schedules/driver/{$staff->id}", ['schedules' => $week])
            ->assertOk()
            ->assertJsonPath('success', true);

        // Admin summary reflects customized schedule (schedule_matches_website = false)
        $summaryRes = $this->actingAs($admin)->getJson('/api/admin/schedules/providers?type=driver');
        $summaryRow = collect($summaryRes->json('data'))->firstWhere('id', $staff->id);
        $this->assertFalse($summaryRow['schedule_matches_website']);

        // Driver sees exact same updated Thursday hours in Driver App endpoint
        $driverRes = $this->actingAs($staff)->getJson('/api/driver/schedule');
        $driverRes->assertOk();
        $thursday = collect($driverRes->json('data.week'))->firstWhere('day_of_week', 'Thursday');
        $this->assertEquals('09:00', $thursday['start_time']);
        $this->assertEquals('13:00', $thursday['end_time']);

        // Driver toggles Friday off from Driver App
        $driverWeek = $driverRes->json('data.week');
        foreach ($driverWeek as &$row) {
            if ($row['day_of_week'] === 'Friday') {
                $row['is_available'] = false;
            }
        }
        unset($row);

        $this->actingAs($staff)
            ->postJson('/api/driver/schedule', ['schedules' => $driverWeek])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertFalse(
            (bool) ProviderSchedule::where('user_id', $staff->id)->where('day_of_week', 'Friday')->value('is_available')
        );
    }

    public function test_mobile_nurse_claim_appears_in_upcoming_schedule(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 11, 26, 10, 0, 0, 'Asia/Baghdad')->utc());
        $patient = $this->createPatient();
        $mobileNurse = $this->createApprovedStaff('Mobile Nurse', '07505550001', 'mobile_nurse', 'full_flex', 'daily', 'available', 'both');

        $order = Order::create([
            'patient_id' => $patient->id,
            'service_type' => 'nursing',
            'subtotal' => 15000,
            'total_price' => 15000,
            'status' => 'pending',
            'scheduled_at' => ProviderSlotService::parseWallClock('2026-11-26 16:00'),
            'patient_details' => ['lat' => 36.1911, 'lng' => 44.0092],
            'location_details' => ['address' => 'Ankawa'],
        ]);

        $this->actingAs($mobileNurse)
            ->postJson("/api/driver/orders/{$order->id}/claim")
            ->assertOk();

        $sched = $this->actingAs($mobileNurse)->getJson('/api/driver/schedule')->assertOk();
        $upcoming = collect($sched->json('data.upcoming'));
        $this->assertTrue($upcoming->contains(fn ($u) => $u['id'] === $order->id && $u['scheduled_at'] === '2026-11-26 16:00'));
    }
}

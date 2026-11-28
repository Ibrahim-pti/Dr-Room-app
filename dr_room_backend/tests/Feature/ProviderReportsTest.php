<?php

namespace Tests\Feature;

use App\Models\Lab;
use App\Models\LabTest;
use App\Models\Nurse;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProviderReportsTest extends TestCase
{
    use RefreshDatabase;

    public function test_nurse_dashboard_and_reports_compute_monthly_accounting_accurately(): void
    {
        $nurseUser = User::create([
            'name' => 'پەرستار ئازاد',
            'phone' => '07501112233',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);

        Nurse::create([
            'user_id' => $nurseUser->id,
            'phone' => '07501112233',
            'specialty' => 'General Care',
            'city' => 'Erbil',
            'is_approved' => true,
            'is_available' => true,
        ]);

        $patientOne = User::create([
            'name' => 'نەخۆش یەکەم',
            'phone' => '07509990001',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('patient123'),
        ]);

        $patientTwo = User::create([
            'name' => 'نەخۆش دووەم',
            'phone' => '07509990002',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('patient123'),
        ]);

        $nowLocal = now('Asia/Baghdad');
        $currentMonth = $nowLocal->format('Y-m');
        $lastMonth = $nowLocal->copy()->startOfMonth()->subDay();
        $lastMonthKey = $lastMonth->format('Y-m');

        // Completed order 1 in current month: 2 cannulas (total 40,000, commission 4,000, net 36,000, cash)
        $order1 = Order::create([
            'patient_id' => $patientOne->id,
            'assigned_nurse_id' => $nurseUser->id,
            'service_type' => 'nursing',
            'subtotal' => 40000,
            'extra_fee' => 0,
            'total_price' => 40000,
            'commission_amount' => 4000,
            'provider_net_amount' => 36000,
            'status' => 'completed',
            'payment_method' => 'cash',
        ]);
        $order1->created_at = $nowLocal->copy()->utc();
        $order1->save();

        OrderItem::create([
            'order_id' => $order1->id,
            'item_name' => 'دانانی کانیۆلا',
            'price' => 20000,
            'quantity' => 2,
        ]);

        // Completed order 2 in current month (same month, different patient): 1 injection (25,000, net 22,500, online)
        $order2 = Order::create([
            'patient_id' => $patientTwo->id,
            'assigned_nurse_id' => $nurseUser->id,
            'service_type' => 'nursing',
            'subtotal' => 25000,
            'extra_fee' => 0,
            'total_price' => 25000,
            'commission_amount' => 2500,
            'provider_net_amount' => 22500,
            'status' => 'completed',
            'payment_method' => 'online',
        ]);
        $order2->created_at = $nowLocal->copy()->utc();
        $order2->save();

        OrderItem::create([
            'order_id' => $order2->id,
            'item_name' => 'لێدانی دەرزی',
            'price' => 25000,
            'quantity' => 1,
        ]);

        // Active order in current month (not revenue yet)
        $order3 = Order::create([
            'patient_id' => $patientOne->id,
            'assigned_nurse_id' => $nurseUser->id,
            'service_type' => 'nursing',
            'subtotal' => 15000,
            'extra_fee' => 0,
            'total_price' => 15000,
            'status' => 'on_the_way',
            'payment_method' => 'cash',
        ]);
        $order3->created_at = $nowLocal->copy()->utc();
        $order3->save();

        // Previous month completed order: 1 dressing (30,000, net 27,000)
        $prevOrder = Order::create([
            'patient_id' => $patientTwo->id,
            'assigned_nurse_id' => $nurseUser->id,
            'service_type' => 'nursing',
            'subtotal' => 30000,
            'extra_fee' => 0,
            'total_price' => 30000,
            'commission_amount' => 3000,
            'provider_net_amount' => 27000,
            'status' => 'completed',
            'payment_method' => 'cash',
        ]);
        $prevOrder->created_at = $lastMonth->copy()->utc();
        $prevOrder->save();

        OrderItem::create([
            'order_id' => $prevOrder->id,
            'item_name' => 'پانسمانی برین',
            'price' => 30000,
            'quantity' => 1,
        ]);

        // Nurse Dashboard shows current month net revenue (36,000 + 22,500 = 58,500)
        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.dashboard'))
            ->assertOk()
            ->assertSee('پوختەی حساباتی ئەم مانگە')
            ->assertSee('58,500')
            ->assertSee(route('nurse.reports.index'), false);

        // Nurse Reports (current month default): net 58,500, gross 65,000, items = 3 (2+1), completed = 2 / 3
        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.reports.index'))
            ->assertOk()
            ->assertViewHas('summary', function (array $summary) use ($currentMonth) {
                return $summary['month'] === $currentMonth
                    && (float) $summary['net_revenue'] === 58500.0
                    && (float) $summary['gross_revenue'] === 65000.0
                    && (float) $summary['cash_revenue'] === 40000.0
                    && (float) $summary['online_revenue'] === 25000.0
                    && $summary['items_performed'] === 3
                    && $summary['completed_orders'] === 2
                    && $summary['total_orders'] === 3
                    && $summary['unique_patients'] === 2;
            })
            ->assertSee('58,500')
            ->assertSee('دانانی کانیۆلا');

        // Filtering to previous month shows only prevOrder
        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.reports.index', ['month' => $lastMonthKey]))
            ->assertOk()
            ->assertViewHas('summary', function (array $summary) use ($lastMonthKey) {
                return $summary['month'] === $lastMonthKey
                    && (float) $summary['net_revenue'] === 27000.0
                    && $summary['items_performed'] === 1
                    && $summary['completed_orders'] === 1
                    && $summary['unique_patients'] === 1;
            })
            ->assertSee('27,000')
            ->assertSee('پانسمانی برین');
    }

    public function test_lab_dashboard_and_reports_compute_monthly_accounting_accurately(): void
    {
        $labUser = User::create([
            'name' => 'تاقیگەی شەقام',
            'phone' => '07502223344',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);

        Lab::create([
            'user_id' => $labUser->id,
            'phone' => '07502223344',
            'location' => 'هەولێر - شەقامی پزیشکان',
            'about_us' => 'تاقیگەیەکی پێشکەوتووی پشکنینی پزیشکی',
            'is_approved' => true,
        ]);

        $patient = User::create([
            'name' => 'ئارام محەمەد',
            'phone' => '07508887766',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('patient123'),
        ]);

        $nowLocal = Carbon::now('Asia/Baghdad');
        $currentMonth = $nowLocal->format('Y-m');

        $labOrder = Order::create([
            'patient_id' => $patient->id,
            'assigned_lab_id' => $labUser->id,
            'service_type' => 'lab',
            'subtotal' => 75000,
            'extra_fee' => 0,
            'total_price' => 75000,
            'commission_amount' => 7500,
            'provider_net_amount' => 67500,
            'status' => 'completed',
            'payment_method' => 'cash',
        ]);
        $labOrder->created_at = $nowLocal->copy()->utc();
        $labOrder->save();

        OrderItem::create([
            'order_id' => $labOrder->id,
            'item_name' => 'CBC Complete Blood Count',
            'price' => 25000,
            'quantity' => 1,
        ]);

        OrderItem::create([
            'order_id' => $labOrder->id,
            'item_name' => 'Vitamin D3',
            'price' => 25000,
            'quantity' => 2,
        ]);

        $this->actingAs($labUser, 'web')
            ->get(route('lab.dashboard'))
            ->assertOk()
            ->assertSee('پوختەی حساباتی ئەم مانگە')
            ->assertSee('67,500')
            ->assertSee(route('lab.reports.index'), false);

        $this->actingAs($labUser, 'web')
            ->get(route('lab.reports.index'))
            ->assertOk()
            ->assertViewHas('summary', function (array $summary) use ($currentMonth) {
                return $summary['month'] === $currentMonth
                    && (float) $summary['net_revenue'] === 67500.0
                    && (float) $summary['gross_revenue'] === 75000.0
                    && $summary['items_performed'] === 3
                    && $summary['completed_orders'] === 1
                    && $summary['unique_patients'] === 1;
            })
            ->assertSee('67,500')
            ->assertSee('CBC Complete Blood Count')
            ->assertSee('Vitamin D3');
    }

    public function test_lab_tests_support_built_in_and_custom_categories(): void
    {
        $labUser = User::create([
            'name' => 'تاقیگەی زانیار',
            'phone' => '07503334455',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);

        $lab = Lab::create([
            'user_id' => $labUser->id,
            'phone' => '07503334455',
            'location' => 'هەولێر',
            'about_us' => 'تاقیگەی پزیشکی',
            'is_approved' => true,
        ]);

        // Create page renders built-in lab categories + custom option
        $this->actingAs($labUser, 'web')
            ->get(route('lab.tests.create'))
            ->assertOk()
            ->assertSee('پشکنینی خوێن')
            ->assertSee('هۆرمۆنات')
            ->assertSee('زیادکردنی کەتەگۆری نوێ');

        // Store with custom category via __custom__ + custom_type
        $this->actingAs($labUser, 'web')
            ->post(route('lab.tests.store'), [
                'name' => 'پشکنینی بۆماوەیی',
                'name_kmr' => 'پشکنینا بۆماوەیی',
                'name_ar' => 'فحص جيني',
                'name_en' => 'Genetic Panel',
                'type' => '__custom__',
                'custom_type' => 'بۆماوەیی و جینات',
                'price' => '50,000',
                'is_active' => '1',
            ])
            ->assertRedirect(route('lab.tests.index'));

        $test = LabTest::where('lab_id', $lab->id)->firstOrFail();
        $this->assertSame('بۆماوەیی و جینات', $test->type);

        // Index displays custom category filter bar & test badge
        $this->actingAs($labUser, 'web')
            ->get(route('lab.tests.index', ['type' => 'بۆماوەیی و جینات']))
            ->assertOk()
            ->assertSee('پشکنینی بۆماوەیی')
            ->assertSee('بۆماوەیی و جینات');
    }

    public function test_admin_commission_summary_lists_all_nurses_and_labs_individually(): void
    {
        $admin = User::create([
            'name' => 'Admin Commission',
            'phone' => '07509990011',
            'role' => 'admin',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);
        $nurse = User::create([
            'name' => 'پەرستار سارا',
            'phone' => '07509990012',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);
        $lab = User::create([
            'name' => 'تاقیگەی ڕۆژ',
            'phone' => '07509990013',
            'role' => 'lab',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);
        $patient = User::create([
            'name' => 'Patient C',
            'phone' => '07509990014',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('password123'),
        ]);

        $now = now();
        Order::create([
            'patient_id' => $patient->id,
            'assigned_nurse_id' => $nurse->id,
            'service_type' => 'nursing',
            'subtotal' => 50000,
            'extra_fee' => 0,
            'total_price' => 50000,
            'commission_rate' => 10,
            'commission_amount' => 5000,
            'provider_net_amount' => 45000,
            'status' => 'completed',
            'payment_method' => 'cash',
        ]);
        Order::create([
            'patient_id' => $patient->id,
            'assigned_lab_id' => $lab->id,
            'service_type' => 'lab',
            'subtotal' => 80000,
            'extra_fee' => 0,
            'total_price' => 80000,
            'commission_rate' => 15,
            'commission_amount' => 12000,
            'provider_net_amount' => 68000,
            'status' => 'completed',
            'payment_method' => 'cash',
        ]);

        $res = $this->actingAs($admin)
            ->getJson("/api/admin/commission/summary?year={$now->year}&month={$now->month}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $providers = collect($res->json('data.providers'));
        $this->assertCount(2, $providers);

        $labRow = $providers->firstWhere('id', $lab->id);
        $this->assertSame('lab', $labRow['service_type']);
        $this->assertEquals(80000, $labRow['total_amount']);
        $this->assertEquals(12000, $labRow['total_commission']);
        $this->assertEquals(68000, $labRow['provider_net']);

        $nurseRow = $providers->firstWhere('id', $nurse->id);
        $this->assertSame('nursing', $nurseRow['service_type']);
        $this->assertEquals(50000, $nurseRow['total_amount']);
        $this->assertEquals(5000, $nurseRow['total_commission']);
        $this->assertEquals(45000, $nurseRow['provider_net']);
    }
}

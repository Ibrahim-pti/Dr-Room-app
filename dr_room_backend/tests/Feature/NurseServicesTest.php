<?php

namespace Tests\Feature;

use App\Models\Nurse;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class NurseServicesTest extends TestCase
{
    use RefreshDatabase;

    public function test_nurse_services_page_updates_preserves_on_profile_save_and_exposes_in_api(): void
    {
        $nurseUser = User::create([
            'name' => 'پەرستاری تاقیکردنەوە',
            'phone' => '07504441122',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('nurse123456'),
        ]);

        $nurse = Nurse::create([
            'user_id' => $nurseUser->id,
            'phone' => '07504441122',
            'specialty' => 'General Care',
            'city' => 'Erbil',
            'is_approved' => true,
            'is_available' => true,
        ]);

        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.services.index'))
            ->assertOk()
            ->assertSee('خزمەتگوزارییەکان و نرخەکان');

        $this->actingAs($nurseUser, 'web')
            ->put(route('nurse.services.update'), [
                'custom_services' => [
                    [
                        'name' => 'دانانی کانیۆلا',
                        'name_kmr' => 'دانانا کانیۆلا',
                        'name_en' => 'IV Cannula',
                        'name_ar' => 'تركيب كانيولا',
                        'price' => 15000,
                    ],
                ],
            ])
            ->assertRedirect();

        $nurse->refresh();
        $this->assertCount(1, $nurse->custom_services);
        $this->assertSame('دانانی کانیۆلا', $nurse->custom_services[0]['name']);
        $this->assertSame(15000.0, (float) $nurse->custom_services[0]['price']);

        // Updating profile must NOT wipe custom_services managed on the standalone services page
        $this->actingAs($nurseUser, 'web')
            ->put(route('nurse.profile.update'), [
                'name' => 'پەرستاری نوێ',
                'name_kmr' => 'پەرستارێ نووی',
                'name_en' => 'New Nurse',
                'name_ar' => 'ممرض جديد',
                'phone' => '07504441122',
                'city' => 'Erbil',
                'address' => '60m Street',
                'address_kmr' => 'جادا 60 مەتری',
                'address_en' => '60m Street',
                'address_ar' => 'شارع 60',
                'bio' => 'تاقیکردنەوە',
                'bio_kmr' => 'تاقیکرن',
                'bio_en' => 'Bio test',
                'bio_ar' => 'تجربة',
                'specialties' => [
                    ['name' => 'پەرستاری گشتی', 'name_en' => 'General Nursing', 'name_ar' => 'تمريض عام'],
                ],
            ])
            ->assertRedirect();

        $nurse->refresh();
        $this->assertCount(1, $nurse->custom_services);

        // API continues to serve custom_services properly across languages
        $this->withHeaders(['Accept-Language' => 'kmr'])
            ->getJson("/api/nurses/{$nurse->id}?lang=kmr")
            ->assertOk()
            ->assertJsonPath('nurse.custom_services.0.name', 'دانانا کانیۆلا')
            ->assertJsonPath('nurse.custom_services.0.name_kmr', 'دانانا کانیۆلا')
            ->assertJsonPath('nurse.custom_services.0.name_en', 'IV Cannula')
            ->assertJsonPath('nurse.custom_services.0.name_ar', 'تركيب كانيولا')
            ->assertJsonPath('nurse.custom_services.0.price', 15000);
    }

    public function test_nurse_appointments_and_patients_pages_render_local_baghdad_time_and_aligned_tables(): void
    {
        $nurseUser = User::create([
            'name' => 'پەرستار',
            'phone' => '07504441133',
            'role' => 'nurse',
            'status' => 'approved',
            'password' => Hash::make('nurse123456'),
        ]);

        Nurse::create([
            'user_id' => $nurseUser->id,
            'phone' => '07504441133',
            'specialty' => 'General Care',
            'city' => 'Erbil',
            'is_approved' => true,
            'is_available' => true,
        ]);

        $patient = User::create([
            'name' => 'نەخۆش تاقیکردنەوە',
            'phone' => '07500000000',
            'role' => 'patient',
            'status' => 'approved',
            'password' => Hash::make('patient123'),
        ]);

        $order = Order::create([
            'patient_id' => $patient->id,
            'service_type' => 'nursing',
            'subtotal' => 35000,
            'extra_fee' => 0,
            'total_price' => 35000,
            'status' => 'pending',
            'payment_method' => 'cash',
            'patient_details' => ['location' => 'هەولێر'],
        ]);
        $order->created_at = \Carbon\Carbon::create(2026, 11, 15, 22, 14, 0, 'UTC');
        $order->save();

        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.appointments.index'))
            ->assertOk()
            ->assertSee('2026-11-16')
            ->assertSee('01:14 AM')
            ->assertDontSee('2026-11-15');

        $assignedOrder = Order::create([
            'patient_id' => $patient->id,
            'assigned_nurse_id' => $nurseUser->id,
            'service_type' => 'nursing',
            'subtotal' => 35000,
            'extra_fee' => 0,
            'total_price' => 35000,
            'status' => 'processing',
            'payment_method' => 'cash',
            'patient_details' => ['location' => 'هەولێر'],
        ]);
        $assignedOrder->created_at = \Carbon\Carbon::create(2026, 11, 15, 22, 14, 0, 'UTC');
        $assignedOrder->save();

        $this->actingAs($nurseUser, 'web')
            ->get(route('nurse.patients.index'))
            ->assertOk()
            ->assertSee('لیستی نەخۆشەکانم')
            ->assertSee('2026-11-16')
            ->assertDontSee('table-fixed');
    }
}

<?php

namespace Tests\Feature;

use App\Models\Nurse;
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
}

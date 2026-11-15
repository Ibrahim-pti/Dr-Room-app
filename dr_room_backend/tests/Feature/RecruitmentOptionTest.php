<?php

namespace Tests\Feature;

use App\Models\RecruitmentOption;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecruitmentOptionTest extends TestCase
{
    use RefreshDatabase;

    private function adminUser(): User
    {
        return User::create([
            'name' => 'Admin',
            'phone' => '07500009999',
            'email' => 'admin-opt@drroom.test',
            'password' => 'secret123',
            'role' => 'admin',
            'status' => 'approved',
        ]);
    }

    public function test_default_options_seed_and_render_on_delivery_landing(): void
    {
        $this->assertGreaterThanOrEqual(6, RecruitmentOption::where('type', 'education')->count());
        $this->assertGreaterThanOrEqual(7, RecruitmentOption::where('type', 'skill')->count());

        $this->get('/delivery/ckb')
            ->assertOk()
            ->assertSee('بەکالۆریۆس لە شیکاری نەخۆشییەکان / بایۆلۆجی')
            ->assertSee('کێشانی خوێن و دەرهێنانی نموونە بە پڕۆفیشناڵی');

        $this->get('/delivery/en')
            ->assertOk()
            ->assertSee('B.Sc. in Medical Lab / Biology')
            ->assertSee('Professional Venipuncture & Blood Draw');
    }

    public function test_admin_can_crud_recruitment_options_and_reflect_on_web_form(): void
    {
        $admin = $this->adminUser();
        $token = $admin->createToken('test')->plainTextToken;

        $createRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/admin/recruitment-options', [
                'type' => 'skill',
                'label_ckb' => 'فریاگوزاری سەرەتایی لە ماڵان',
                'label_kmr' => 'فرییاگوزاریا دەستپێکی ل مالان',
                'label_ar' => 'الإسعافات الأولية المنزلية',
                'label_en' => 'Home First Aid Care',
                'sort_order' => 99,
                'is_active' => true,
            ])
            ->assertCreated()
            ->assertJsonPath('label_ckb', 'فریاگوزاری سەرەتایی لە ماڵان')
            ->assertJsonPath('label_en', 'Home First Aid Care');

        $id = $createRes->json('id');
        $key = $createRes->json('option_key');

        $this->get('/delivery/ckb')->assertOk()->assertSee('فریاگوزاری سەرەتایی لە ماڵان');
        $this->get('/delivery/kmr')->assertOk()->assertSee('فرییاگوزاریا دەستپێکی ل مالان');
        $this->get('/delivery/ar')->assertOk()->assertSee('الإسعافات الأولية المنزلية');
        $this->get('/delivery/en')->assertOk()->assertSee('Home First Aid Care');

        // Register using the newly created dynamic skill
        $eduRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/admin/recruitment-options', [
                'type' => 'education',
                'label_ckb' => 'ماستەر لە پەرستاری',
                'label_kmr' => 'ماستەر د پەرستاریێ دا',
                'label_ar' => 'ماجستير تمريض',
                'label_en' => 'M.Sc. in Nursing',
            ])
            ->assertCreated();

        $eduKey = $eduRes->json('option_key');

        $this->post('/delivery/register', [
            'name' => 'Dynamic Staff',
            'phone' => '07507778899',
            'password' => 'pass123456',
            'password_confirmation' => 'pass123456',
            'city' => 'هەولێر',
            'applicant_role' => 'mobile_nurse',
            'education_level' => $eduKey,
            'clinical_skills' => [$key],
            'agree_terms' => '1',
        ])->assertRedirect();

        $driverUser = User::where('phone', '07507778899')->firstOrFail();
        $profile = $driverUser->driver->resolvedFieldProfile();
        $this->assertSame($eduKey, $profile['education_level']);
        $this->assertSame([$key], $profile['clinical_skills']);

        // Deactivate hides from public page
        $this->withHeader('Authorization', "Bearer {$token}")
            ->putJson("/api/admin/recruitment-options/{$id}", [
                'label_ckb' => 'فریاگوزاری دەستبەجێ',
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('is_active', false);

        $this->get('/delivery/ckb')->assertOk()->assertDontSee('فریاگوزاری دەستبەجێ');

        // Delete works
        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/admin/recruitment-options/{$id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('recruitment_options', ['id' => $id]);
    }
}

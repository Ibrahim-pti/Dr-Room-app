<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Driver;
use App\Models\User;
use App\Services\FcmService;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class DeliveryWebController extends Controller
{
    private function applyLocale(?string $locale = null, ?Request $request = null): string
    {
        $raw = $locale
            ?? ($request && $request->filled('lang') ? $request->query('lang') : null)
            ?? (session()->has('locale') ? session()->get('locale') : 'ckb');

        $normalized = strtolower(trim((string) $raw));
        if ($normalized === 'ku') {
            $normalized = 'ckb';
        }
        if (!in_array($normalized, ['ckb', 'ar', 'en', 'kmr'], true)) {
            $normalized = 'ckb';
        }

        session()->put('locale', $normalized);
        app()->setLocale($normalized);
        return $normalized;
    }

    public function landing(Request $request, ?string $locale = null)
    {
        $activeLocale = $this->applyLocale($locale, $request);

        return view('delivery.landing', [
            'locale' => $activeLocale,
        ]);
    }

    public function register(Request $request)
    {
        $this->applyLocale($request->input('locale'), $request);

        $localPhone = OtpService::toLocalPhone((string) $request->phone);

        if (trim((string) $request->name) === '') {
            return back()
                ->withErrors(['name' => __('delivery.err_name')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        if (!preg_match('/^07[0-9]{9}$/', $localPhone)) {
            return back()
                ->withErrors(['phone' => __('delivery.err_phone')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        if (OtpService::findUserByPhoneOrEmail($localPhone)) {
            return back()
                ->withErrors(['phone' => __('delivery.err_phone_exists')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        if (strlen((string) $request->password) < 6) {
            return back()
                ->withErrors(['password' => __('delivery.err_password')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        if ((string) $request->password !== (string) $request->password_confirmation) {
            return back()
                ->withErrors(['password_confirmation' => __('delivery.err_password_confirm')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        if (!$request->boolean('agree_terms')) {
            return back()
                ->withErrors(['agree_terms' => __('delivery.err_terms')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        $fileValidator = Validator::make($request->all(), [
            'id_document' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'certificate' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'license' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
            'cv' => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ]);

        if ($fileValidator->fails()) {
            return back()
                ->withErrors(['files' => __('delivery.err_file')])
                ->withInput($request->except('password', 'password_confirmation'));
        }

        $applicantRole = in_array($request->applicant_role, ['phlebotomist', 'mobile_nurse', 'both', 'courier'], true)
            ? $request->applicant_role
            : 'phlebotomist';

        $gender = in_array($request->gender, ['male', 'female'], true)
            ? $request->gender
            : null;

        $educationLevel = trim((string) $request->education_level);
        $educationLevel = $educationLevel !== '' ? $educationLevel : null;

        $experienceYears = is_numeric($request->experience_years)
            ? max(0, min(60, (int) $request->experience_years))
            : 0;

        $allowedSkills = [
            'venipuncture', 'pediatric_draw', 'cannula_iv', 'injections',
            'wound_care', 'vital_signs', 'cold_chain', 'pharma_handling',
        ];
        $clinicalSkills = collect((array) $request->input('clinical_skills', []))
            ->map(fn ($s) => (string) $s)
            ->filter(fn ($s) => in_array($s, $allowedSkills, true))
            ->values()
            ->all();

        $serviceAreas = trim((string) $request->service_areas);
        $serviceAreas = $serviceAreas !== '' ? $serviceAreas : null;

        $availabilityShift = in_array($request->availability_shift, ['morning', 'evening', 'full_flex'], true)
            ? $request->availability_shift
            : 'full_flex';

        $workDays = in_array($request->work_days, ['daily', 'weekdays', 'part_time'], true)
            ? $request->work_days
            : 'daily';

        $willingToTravel = $request->input('willing_to_travel', '1') === '1';
        $hasPrivateCar = $request->input('has_private_car', '0') === '1';

        if ($applicantRole === 'courier') {
            $vehicleType = in_array($request->vehicle_type, ['motorcycle', 'car', 'refrigerated_van'], true)
                ? $request->vehicle_type
                : 'motorcycle';
            $serviceScope = in_array($request->service_scope, ['pharmacy', 'lab_sample', 'both'], true)
                ? $request->service_scope
                : 'pharmacy';
        } else {
            $vehicleType = $hasPrivateCar ? 'car' : 'motorcycle';
            $serviceScope = $applicantRole === 'phlebotomist' ? 'lab_sample' : 'both';
        }

        $city = trim((string) ($request->city ?: 'هەولێر'));
        $plateNumber = trim((string) ($request->plate_number ?? ''));

        $user = DB::transaction(function () use (
            $request,
            $localPhone,
            $city,
            $vehicleType,
            $serviceScope,
            $plateNumber,
            $applicantRole,
            $gender,
            $educationLevel,
            $experienceYears,
            $clinicalSkills,
            $serviceAreas,
            $availabilityShift,
            $workDays,
            $willingToTravel,
            $hasPrivateCar
        ) {
            $created = User::create([
                'name' => trim((string) $request->name),
                'phone' => $localPhone,
                'password' => Hash::make((string) $request->password),
                'role' => 'driver',
                'status' => 'pending',
            ]);

            $docPaths = [];
            foreach (['id_document', 'certificate', 'license', 'cv'] as $fileField) {
                if ($request->hasFile($fileField) && $request->file($fileField)->isValid()) {
                    $docPaths[$fileField . '_path'] = $request->file($fileField)->store(
                        "driver_docs/{$created->id}",
                        'public'
                    );
                }
            }

            $fieldProfile = [
                'applicant_role' => $applicantRole,
                'gender' => $gender,
                'education_level' => $educationLevel,
                'experience_years' => $experienceYears,
                'clinical_skills' => $clinicalSkills,
                'service_areas' => $serviceAreas,
                'availability_shift' => $availabilityShift,
                'work_days' => $workDays,
                'willing_to_travel' => $willingToTravel,
                'has_private_car' => $hasPrivateCar,
                'id_document_path' => $docPaths['id_document_path'] ?? null,
                'certificate_path' => $docPaths['certificate_path'] ?? null,
                'license_path' => $docPaths['license_path'] ?? null,
                'cv_path' => $docPaths['cv_path'] ?? null,
            ];

            $driverData = [
                'user_id' => $created->id,
                'city' => $city,
                'vehicle_type' => $vehicleType,
                'plate_number' => $plateNumber !== '' ? $plateNumber : null,
                'service_scope' => $serviceScope,
                'duty_status' => 'offline',
                'notes' => json_encode($fieldProfile, JSON_UNESCAPED_UNICODE),
            ];

            $optionalColumns = [
                'applicant_role' => $applicantRole,
                'gender' => $gender,
                'education_level' => $educationLevel,
                'experience_years' => $experienceYears,
                'clinical_skills' => $clinicalSkills,
                'service_areas' => $serviceAreas,
                'availability_shift' => $availabilityShift,
                'work_days' => $workDays,
                'willing_to_travel' => $willingToTravel,
                'has_private_car' => $hasPrivateCar,
                'id_document_path' => $docPaths['id_document_path'] ?? null,
                'certificate_path' => $docPaths['certificate_path'] ?? null,
                'license_path' => $docPaths['license_path'] ?? null,
                'cv_path' => $docPaths['cv_path'] ?? null,
            ];

            foreach ($optionalColumns as $col => $val) {
                if (Schema::hasColumn('drivers', $col)) {
                    $driverData[$col] = $val;
                }
            }

            Driver::create($driverData);

            return $created;
        });

        // Notify admins about the new field/medical team application
        try {
            $adminIds = User::whereIn('role', ['admin', 'staff'])->pluck('id')->all();
            $roleTitleKu = match ($applicantRole) {
                'phlebotomist' => 'وەرگرتنی نموونەی خوێن و تاقیگە',
                'mobile_nurse' => 'پەرستاری ماڵان',
                'both' => 'پەرستاری + وەرگرتنی نموونەی خوێن',
                default => 'گەیاندنی دەرمان و پێداویستی تەندروستی',
            };
            $roleTitleAr = match ($applicantRole) {
                'phlebotomist' => 'أخصائي سحب عينات ومختبر',
                'mobile_nurse' => 'ممرض رعاية منزلية',
                'both' => 'تمريض + سحب عينات',
                default => 'توصيل أدوية ومستلزمات طبية',
            };
            $roleTitleEn = match ($applicantRole) {
                'phlebotomist' => 'Home Phlebotomist',
                'mobile_nurse' => 'Mobile Nurse',
                'both' => 'Nurse + Phlebotomist',
                default => 'Medicine Courier',
            };

            $title = 'داواکاری نوێی تیمی پزیشکی گەڕۆک 🩺';
            $msg = "{$user->name} ({$localPhone}) داواکاری پەیوەندیکردن ({$roleTitleKu}) لە شاری {$city} تۆمارکرد.";

            foreach ($adminIds as $adminId) {
                AppNotification::create([
                    'user_id' => $adminId,
                    'title' => $title,
                    'title_ar' => 'طلب انضمام جديد للفريق الميداني 🩺',
                    'title_en' => 'New Field Team Application 🩺',
                    'message' => $msg,
                    'message_ar' => "تقدم {$user->name} ({$localPhone}) بطلب ({$roleTitleAr}) في {$city}.",
                    'message_en' => "{$user->name} ({$localPhone}) applied as {$roleTitleEn} in {$city}.",
                    'type' => 'admin_notice',
                ]);
            }

            if (!empty($adminIds)) {
                app(FcmService::class)->sendToUsers(
                    $adminIds,
                    $title,
                    $msg,
                    ['type' => 'new_driver_application', 'driver_user_id' => (string) $user->id]
                );
            }
        } catch (\Throwable $e) {
            // Non-blocking notification
        }

        Auth::guard('web')->login($user, true);
        session()->put('delivery_applicant_id', $user->id);

        return redirect()->route('delivery.waiting');
    }

    public function waiting(Request $request)
    {
        $activeLocale = $this->applyLocale(null, $request);
        $user = Auth::user();
        if (!$user && session()->has('delivery_applicant_id')) {
            $user = User::where('id', session('delivery_applicant_id'))
                ->where('role', 'driver')
                ->first();
        }

        if (!$user || $user->role !== 'driver') {
            return redirect()->route('delivery.landing');
        }

        return view('delivery.waiting', [
            'user' => $user->load('driver'),
            'locale' => $activeLocale,
        ]);
    }

    public function status()
    {
        $user = Auth::user();
        if (!$user && session()->has('delivery_applicant_id')) {
            $user = User::where('id', session('delivery_applicant_id'))
                ->where('role', 'driver')
                ->first();
        }

        if (!$user || $user->role !== 'driver') {
            return response()->json(['status' => 'unauthenticated'], 401);
        }

        return response()->json(['status' => $user->status]);
    }

    public function logout(Request $request)
    {
        session()->forget('delivery_applicant_id');
        if (Auth::check() && Auth::user()->role === 'driver') {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        }

        return redirect()->route('delivery.landing');
    }
}


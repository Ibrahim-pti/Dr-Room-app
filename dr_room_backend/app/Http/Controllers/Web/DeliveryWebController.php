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

        $vehicleType = in_array($request->vehicle_type, ['motorcycle', 'car', 'refrigerated_van'], true)
            ? $request->vehicle_type
            : 'motorcycle';
        $serviceScope = in_array($request->service_scope, ['pharmacy', 'lab_sample', 'both'], true)
            ? $request->service_scope
            : 'both';
        $city = trim((string) ($request->city ?: 'هەولێر'));
        $plateNumber = trim((string) ($request->plate_number ?? ''));

        $user = DB::transaction(function () use ($request, $localPhone, $city, $vehicleType, $serviceScope, $plateNumber) {
            $created = User::create([
                'name' => trim((string) $request->name),
                'phone' => $localPhone,
                'password' => Hash::make((string) $request->password),
                'role' => 'driver',
                'status' => 'pending',
            ]);

            Driver::create([
                'user_id' => $created->id,
                'city' => $city,
                'vehicle_type' => $vehicleType,
                'plate_number' => $plateNumber !== '' ? $plateNumber : null,
                'service_scope' => $serviceScope,
                'duty_status' => 'offline',
            ]);

            return $created;
        });

        // Notify admins about the new delivery driver application
        try {
            $adminIds = User::whereIn('role', ['admin', 'staff'])->pluck('id')->all();
            $title = 'داواکاری نوێی کارمەندی گەیاندن 🛵';
            $msg = "{$user->name} ({$localPhone}) داواکاری بوون بە کارمەندی گەیاندنی تۆمارکرد.";

            foreach ($adminIds as $adminId) {
                AppNotification::create([
                    'user_id' => $adminId,
                    'title' => $title,
                    'title_ar' => 'طلب تسجيل مندوب توصيل جديد 🛵',
                    'title_en' => 'New Delivery Driver Application 🛵',
                    'message' => $msg,
                    'message_ar' => "تقدم {$user->name} ({$localPhone}) بطلب للعمل كمندوب توصيل.",
                    'message_en' => "{$user->name} ({$localPhone}) applied to join as a delivery driver.",
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

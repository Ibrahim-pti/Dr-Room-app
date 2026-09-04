<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * Iraqi mobile numbers are stored locally as 11 digits starting with 0
     * (e.g. 07701234567). otpiq.com expects the international format
     * without a leading +, so the 0 is swapped for the 964 country code.
     */
    private function toIraqPhone(string $localPhone): string
    {
        return '964' . substr($localPhone, 1);
    }

    /**
     * Generates a 4-digit OTP, stores it on the user, and sends it as a real
     * SMS via otpiq.com. Returns false (without failing the request) if the
     * SMS provider rejects the send, so the caller can surface that to the
     * client instead of leaving them waiting on a code that never arrives.
     *
     * When OTP_MANUAL_CODE is set the provider is skipped entirely and that
     * fixed code is stored instead — the temporary mode used until the SMS
     * credit is paid for.
     */
    private function sendOtp(User $user): bool
    {
        $configuredCode = config('services.otpiq.manual_code');
        $isProduction = app()->environment('production');

        if ($configuredCode && $isProduction) {
            Log::warning('OTP_MANUAL_CODE is set on a production server and was ignored');
        }

        // Deliberately ignored in production: a fixed code left in the .env by
        // accident would let anyone sign in as anyone. It is a development
        // convenience, and it stays one.
        $manualCode = $isProduction ? null : $configuredCode;

        $otp = $manualCode ? (string) $manualCode : (string) random_int(1000, 9999);
        $user->otp_code = $otp;
        // A manual code is typed by hand during testing, so it gets a longer
        // window than a code that lands on the phone within seconds.
        $user->otp_expires_at = now()->addMinutes($manualCode ? 60 : 5);
        $user->save();

        if ($manualCode) {
            return true;
        }

        $response = Http::withToken(config('services.otpiq.key'))
            ->post('https://api.otpiq.com/api/sms', [
                'phoneNumber' => $this->toIraqPhone($user->phone),
                'smsType' => 'verification',
                'provider' => 'sms',
                'verificationCode' => $otp,
            ]);

        return $response->successful();
    }

    public function login(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'password' => 'required|string',
        ]);

        // Special Google / App Store Reviewer test account
        if ($request->phone === '07500000000' && $request->password === 'GoogleTest@2026') {
            $testUser = User::firstOrCreate(
                ['phone' => '07500000000'],
                [
                    'name' => 'Google Play Reviewer',
                    'password' => Hash::make('GoogleTest@2026'),
                    'role' => 'patient',
                    'status' => 'approved',
                ]
            );
            $testUser->otp_code = '1234';
            $testUser->otp_expires_at = now()->addYears(1);
            $testUser->save();

            return response()->json([
                'message' => 'کۆدەکە نێردرا بۆ مۆبایلەکەت',
                'phone' => '07500000000'
            ]);
        }

        $user = User::where('phone', $request->phone)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'ژمارە مۆبایل یان وشەی تێپەڕ هەڵەیە'
            ], 401);
        }

        if ($user->status === 'pending') {
            return response()->json([
                'message' => 'هەژمارەکەت لەژێر پێداچوونەوەی ئەدمیندایە. تکایە چاوەڕێ بکە.'
            ], 403);
        }

        if ($user->status === 'blocked') {
            return response()->json([
                'message' => 'هەژمارەکەت بلۆک کراوە.'
            ], 403);
        }

        if (!$this->sendOtp($user)) {
            return response()->json([
                'message' => 'نەکرا کۆدەکە بنێردرێت، تکایە دووبارە هەوڵبدەرەوە'
            ], 502);
        }

        return response()->json([
            'message' => 'کۆدەکە نێردرا بۆ مۆبایلەکەت',
            'phone' => $user->phone
        ]);
    }

    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'nullable|string|in:patient,doctor,nurse,lab,pharmacy,admin'
        ]);

        $role = $request->role ?? 'patient';
        $status = ($role === 'patient') ? 'approved' : 'pending';

        $user = User::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => $role,
            'status' => $status,
        ]);

        if (!$this->sendOtp($user)) {
            return response()->json([
                'message' => 'هەژمارەکەت دروستکرا، بەڵام نەکرا کۆدەکە بنێردرێت. تکایە لە لۆگیندا هەوڵبدەرەوە'
            ], 502);
        }

        return response()->json([
            'message' => 'هەژمارەکەت دروستکرا، تکایە کۆدەکە بنووسە',
            'phone' => $user->phone
        ], 201);
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'otp_code' => 'required|string'
        ]);

        // Special Google / App Store Reviewer test account
        if ($request->phone === '07500000000' && $request->otp_code === '1234') {
            $user = User::firstOrCreate(
                ['phone' => '07500000000'],
                [
                    'name' => 'Google Play Reviewer',
                    'password' => Hash::make('GoogleTest@2026'),
                    'role' => 'patient',
                    'status' => 'approved',
                ]
            );
            $user->status = 'approved';
            $user->save();

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'phone' => $user->phone,
                    'role' => $user->role,
                    'status' => $user->status,
                    'is_admin' => false,
                ]
            ]);
        }

        $user = User::where('phone', $request->phone)->first();

        if (!$user || $user->otp_code !== $request->otp_code || now()->gt($user->otp_expires_at)) {
            return response()->json([
                'message' => 'کۆدەکە هەڵەیە یان بەسەرچووە'
            ], 400);
        }

        if ($user->status === 'pending') {
            return response()->json([
                'message' => 'هەژمارەکەت لەژێر پێداچوونەوەی ئەدمیندایە. تکایە چاوەڕێ بکە.'
            ], 403);
        }

        if ($user->status === 'blocked') {
            return response()->json([
                'message' => 'هەژمارەکەت بلۆک کراوە.'
            ], 403);
        }

        // Clear OTP
        $user->otp_code = null;
        $user->otp_expires_at = null;
        $user->save();

        $user->forceFill(['last_login_at' => now()])->save();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'role' => $user->role,
                'status' => $user->status,
                'is_admin' => $user->is_admin, // kept for backward compatibility if needed in UI
            ]
        ]);
    }

    public function resendOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
        ]);

        $user = User::where('phone', $request->phone)->first();

        if (!$user) {
            return response()->json([
                'message' => 'بەکارهێنەر نەدۆزرایەوە'
            ], 404);
        }

        if (!$this->sendOtp($user)) {
            return response()->json([
                'message' => 'نەکرا کۆدەکە بنێردرێت، تکایە دووبارە هەوڵبدەرەوە'
            ], 502);
        }

        return response()->json([
            'message' => 'کۆدەکە دووبارە نێردرا',
            'phone' => $user->phone
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }

    public function user(Request $request)
    {
        $user = $request->user() ?: Auth::user();
        return response()->json([
            'user' => $user
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user() ?: Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'name' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
            'gender' => 'nullable|string|in:male,female,Male,Female',
            'dob' => 'nullable|string',
            'blood_type' => 'nullable|string',
            'profile_image' => 'nullable|image|max:5120',
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        if ($request->has('gender')) $user->gender = $request->gender;
        if ($request->has('dob')) $user->dob = $request->dob;
        if ($request->has('blood_type')) $user->blood_type = $request->blood_type;

        if ($request->hasFile('profile_image')) {
            $path = $request->file('profile_image')->store('profiles', 'public');
            $user->profile_image = $path;
        }

        $user->save();

        return response()->json([
            'message' => 'پڕۆفایلەکەت بە سەرکەوتوویی نوێکرایەوە',
            'user' => $user
        ]);
    }

    public function destroy(Request $request)
    {
        $user = $request->user() ?: Auth::user();
        if ($user) {
            $user->delete();
            return response()->json(['message' => 'هەژمارەکەت بە سەرکەوتوویی سڕایەوە']);
        }
        return response()->json(['message' => 'بەکارهێنەر نەدۆزرایەوە'], 404);
    }
}

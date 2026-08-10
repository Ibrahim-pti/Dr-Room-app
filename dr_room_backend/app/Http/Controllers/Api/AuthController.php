<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;

class AuthController extends Controller
{
    /**
     * Iraqi mobile numbers are stored locally as 11 digits starting with 0
     * (e.g. 07701234567). Firebase Phone Auth deals in E.164, so the leading
     * 0 is swapped for the +964 country code both ways.
     */
    private function toE164(string $localPhone): string
    {
        return '+964' . substr($localPhone, 1);
    }

    public function login(Request $request)
    {
        \Log::info('login hit', $request->all());
        $request->validate([
            'phone' => 'required|string',
            'password' => 'required|string',
        ]);

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

        // Password is correct — the app now sends the real SMS OTP itself via
        // Firebase Phone Auth. This response just confirms it's clear to do so.
        return response()->json([
            'message' => 'وشەی تێپەڕ ڕاستە',
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

        return response()->json([
            'message' => 'هەژمارەکەت دروستکرا',
            'phone' => $user->phone
        ], 201);
    }

    /**
     * Finalizes login/register: the client verifies the SMS code with
     * Firebase itself, then hands us the resulting ID token. We verify it
     * server-side and only trust the phone number Firebase attests to.
     */
    public function verifyFirebaseOtp(Request $request, FirebaseAuth $firebaseAuth)
    {
        $request->validate([
            'phone' => 'required|string',
            'firebase_id_token' => 'required|string',
        ]);

        try {
            $verifiedToken = $firebaseAuth->verifyIdToken($request->firebase_id_token);
        } catch (FailedToVerifyToken $e) {
            return response()->json([
                'message' => 'کۆدەکە هەڵەیە یان بەسەرچووە'
            ], 400);
        }

        $tokenPhone = $verifiedToken->claims()->get('phone_number');

        if ($tokenPhone !== $this->toE164($request->phone)) {
            return response()->json([
                'message' => 'ژمارە مۆبایلەکە لەگەڵ کۆدەکە ناگونجێت'
            ], 400);
        }

        $user = User::where('phone', $request->phone)->first();

        if (!$user) {
            return response()->json([
                'message' => 'بەکارهێنەر نەدۆزرایەوە'
            ], 404);
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

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }

    public function user(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ]);
    }

    public function destroy(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $user->delete();
            return response()->json(['message' => 'هەژمارەکەت بە سەرکەوتوویی سڕایەوە']);
        }
        return response()->json(['message' => 'بەکارهێنەر نەدۆزرایەوە'], 404);
    }
}

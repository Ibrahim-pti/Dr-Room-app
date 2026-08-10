<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
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

        $otp = 1234; // کۆدەکە جێگیر کراوە بۆ تێستکردن
        $user->otp_code = $otp;
        $user->otp_expires_at = now()->addMinutes(5);
        $user->save();

        return response()->json([
            'message' => 'کۆدەکە نێردرا بۆ مۆبایلەکەت',
            'otp' => $otp, // For dev purposes
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

        $otp = 1234; // کۆدەکە جێگیر کراوە بۆ تێستکردن
        
        $role = $request->role ?? 'patient';
        $status = ($role === 'patient') ? 'approved' : 'pending';

        $user = User::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => $role,
            'status' => $status,
            'otp_code' => $otp,
            'otp_expires_at' => now()->addMinutes(5)
        ]);

        return response()->json([
            'message' => 'هەژمارەکەت دروستکرا، تکایە کۆدەکە بنووسە',
            'otp' => $otp, // For dev purposes
            'phone' => $user->phone
        ], 201);
    }

    public function verifyOtp(Request $request)
    {
        \Log::info('verifyOtp hit', $request->all());
        $request->validate([
            'phone' => 'required|string',
            'otp_code' => 'required|string'
        ]);

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

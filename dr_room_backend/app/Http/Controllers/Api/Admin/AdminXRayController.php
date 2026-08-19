<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\XRay;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminXRayController extends Controller
{
    public function index()
    {
        $xrays = User::where('role', 'xray')->with('xray')->orderBy('created_at', 'desc')->get();
        return response()->json($xrays);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'location' => 'nullable|string|max:255',
            'email' => 'nullable|email',
        ]);

        $email = $request->email ?: 'xray_' . Str::random(6) . '@drroom.app';

        $user = User::create([
            'name' => $request->name,
            'name_ar' => $request->name_ar ?? $request->name,
            'name_en' => $request->name_en ?? $request->name,
            'email' => $email,
            'phone' => $request->phone,
            'password' => Hash::make('password123'),
            'role' => 'xray',
            'status' => $request->status ?? 'approved',
        ]);

        $xray = XRay::create([
            'user_id' => $user->id,
            'phone' => $request->phone,
            'location' => $request->location ?? 'Erbil',
            'rating' => 4.8,
            'total_reviews' => 8,
            'is_approved' => ($user->status === 'approved'),
        ]);

        return response()->json([
            'message' => 'XRay center created successfully',
            'user' => $user->load('xray')
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'location' => 'nullable|string|max:255',
        ]);

        $userData = $request->only(['name', 'name_ar', 'name_en', 'phone', 'status']);
        $user->update($userData);

        if ($user->xray) {
            $user->xray->update([
                'phone' => $request->phone ?? $user->xray->phone,
                'location' => $request->location ?? $user->xray->location,
            ]);
        }

        return response()->json([
            'message' => 'XRay center updated successfully',
            'user' => $user->load('xray')
        ]);
    }

    public function approve($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->xray) {
            $user->xray()->create([
                'location' => 'Erbil',
                'rating' => 4.8,
                'is_approved' => true,
            ]);
        } else {
            $user->xray->update(['is_approved' => true]);
        }

        \App\Models\AppNotification::create([
            'user_id' => $user->id,
            'title' => 'هەژمارەکەت پەسەندکرا',
            'title_en' => 'Account Approved',
            'title_ar' => 'تمت الموافقة على حسابك',
            'message' => 'پیرۆزە! هەژماری سەنتەری تیشکەکەت لەلایەن ئەدمینەوە پەسەندکرا.',
            'message_en' => 'Congratulations! Your X-Ray center account has been approved by admin.',
            'message_ar' => 'مبروك! تمت الموافقة على حساب مركز الأشعة الخاص بك.',
            'type' => 'system',
            'is_read' => false
        ]);

        return response()->json(['message' => 'XRay approved successfully', 'user' => $user->load('xray')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        if ($user->xray) {
            $user->xray->update(['is_approved' => false]);
        }

        return response()->json(['message' => 'XRay rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        if ($user->xray) {
            $user->xray->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}

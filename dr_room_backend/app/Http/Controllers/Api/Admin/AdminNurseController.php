<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Nurse;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminNurseController extends Controller
{
    public function index()
    {
        $nurses = User::where('role', 'nurse')
            ->with(['nurse'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json($nurses);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email',
            'specialty' => 'nullable|string|max:150',
        ]);

        $email = $request->email ?: 'nurse_' . Str::random(6) . '@drroom.app';

        $user = User::create([
            'name' => $request->name,
            'name_ar' => $request->name_ar ?? $request->name,
            'name_en' => $request->name_en ?? $request->name,
            'email' => $email,
            'phone' => $request->phone,
            'password' => Hash::make('password123'),
            'role' => 'nurse',
            'status' => $request->status ?? 'approved',
        ]);

        $nurse = Nurse::create([
            'user_id' => $user->id,
            'specialty' => $request->specialty ?? 'General Care',
            'phone' => $request->phone,
            'is_approved' => ($user->status === 'approved'),
        ]);

        return response()->json([
            'message' => 'Nurse created successfully',
            'user' => $user->load('nurse')
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'specialty' => 'nullable|string|max:150',
        ]);

        $userData = $request->only(['name', 'name_ar', 'name_en', 'phone', 'status']);
        $user->update($userData);

        if ($user->nurse) {
            $user->nurse->update([
                'phone' => $request->phone ?? $user->nurse->phone,
                'specialty' => $request->specialty ?? $user->nurse->specialty,
            ]);
        }

        return response()->json([
            'message' => 'Nurse updated successfully',
            'user' => $user->load('nurse')
        ]);
    }

    public function approve($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        $user->update(['status' => 'approved']);

        if (!$user->nurse) {
            $user->nurse()->create([
                'specialty' => 'General Care',
                'is_approved' => true,
            ]);
        } else {
            $user->nurse->update(['is_approved' => true]);
        }

        \App\Models\AppNotification::create([
            'user_id' => $user->id,
            'title' => 'هەژمارەکەت پەسەندکرا',
            'title_en' => 'Account Approved',
            'title_ar' => 'تمت الموافقة على حسابك',
            'message' => 'پیرۆزە! هەژمارەکەت لەلایەن ئەدمینەوە پەسەندکرا. ئێستا دەتوانیت بچیتە ناو سیستەمەکە.',
            'message_en' => 'Congratulations! Your account has been approved by the admin.',
            'message_ar' => 'مبروك! تمت الموافقة على حسابك من قبل المسؤول.',
            'type' => 'system',
            'is_read' => false
        ]);

        return response()->json(['message' => 'Nurse approved successfully', 'user' => $user->load('nurse')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        $user->update(['status' => 'rejected']);

        if ($user->nurse) {
            $user->nurse->update(['is_approved' => false]);
        }

        return response()->json(['message' => 'Nurse rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        if ($user->nurse) {
            $user->nurse->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}

<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Lab;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminLabController extends Controller
{
    public function index()
    {
        $labs = User::where('role', 'lab')
            ->with(['lab.tests'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json($labs);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'city' => 'nullable|string|max:100',
            'lab_type' => 'nullable|string|max:100',
            'email' => 'nullable|email',
            'location' => 'nullable|string|max:255',
        ]);

        $email = $request->email ?: 'lab_' . Str::random(6) . '@drroom.app';

        $user = User::create([
            'name' => $request->name,
            'name_ar' => $request->name_ar ?? $request->name,
            'name_en' => $request->name_en ?? $request->name,
            'email' => $email,
            'phone' => $request->phone,
            'password' => Hash::make('password123'),
            'role' => 'lab',
            'status' => $request->status ?? 'approved',
        ]);

        $lab = Lab::create([
            'user_id' => $user->id,
            'city' => $request->city ?? 'Erbil',
            'phone' => $request->phone,
            'location' => $request->location ?? $request->city,
            'rating' => 4.8,
            'total_reviews' => 10,
            'is_approved' => ($user->status === 'approved'),
        ]);

        return response()->json([
            'message' => 'Lab created successfully',
            'user' => $user->load('lab')
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'city' => 'nullable|string|max:100',
            'location' => 'nullable|string|max:255',
        ]);

        $userData = $request->only(['name', 'name_ar', 'name_en', 'phone', 'status']);
        $user->update($userData);

        if ($user->lab) {
            $user->lab->update([
                'city' => $request->city ?? $user->lab->city,
                'phone' => $request->phone ?? $user->lab->phone,
                'location' => $request->location ?? $user->lab->location,
            ]);
        }

        return response()->json([
            'message' => 'Lab updated successfully',
            'user' => $user->load('lab')
        ]);
    }

    public function approve($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->lab) {
            $user->lab()->create([
                'city' => 'Erbil',
                'rating' => 4.8,
                'is_approved' => true,
            ]);
        } else {
            $user->lab->update(['is_approved' => true]);
        }

        \App\Models\AppNotification::create([
            'user_id' => $user->id,
            'title' => 'هەژمارەکەت پەسەندکرا',
            'title_en' => 'Account Approved',
            'title_ar' => 'تمت الموافقة على حسابك',
            'message' => 'پیرۆزە! هەژماری تاقیگەکەت لەلایەن ئەدمینەوە پەسەندکرا.',
            'message_en' => 'Congratulations! Your laboratory account has been approved by admin.',
            'message_ar' => 'مبروك! تمت الموافقة على حساب المختبر الخاص بك.',
            'type' => 'system',
            'is_read' => false
        ]);

        return response()->json(['message' => 'Lab approved successfully', 'user' => $user->load('lab')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        if ($user->lab) {
            $user->lab->update(['is_approved' => false]);
        }

        return response()->json(['message' => 'Lab rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        if ($user->lab) {
            $user->lab->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}

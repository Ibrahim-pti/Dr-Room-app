<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminPharmacyController extends Controller
{
    public function index()
    {
        $pharmacies = User::where('role', 'pharmacy')
            ->with(['pharmacy'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json($pharmacies);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:255',
            'location' => 'nullable|string|max:255',
            'email' => 'nullable|email',
        ]);

        $email = $request->email ?: 'pharmacy_' . Str::random(6) . '@drroom.app';

        $user = User::create([
            'name' => $request->name,
            'name_ar' => $request->name_ar ?? $request->name,
            'name_en' => $request->name_en ?? $request->name,
            'email' => $email,
            'phone' => $request->phone,
            'password' => Hash::make('password123'),
            'role' => 'pharmacy',
            'status' => $request->status ?? 'approved',
        ]);

        $pharmacy = Pharmacy::create([
            'user_id' => $user->id,
            'phone' => $request->phone,
            'location' => $request->location ?? $request->address ?? 'Erbil',
            'rating' => 4.8,
            'total_reviews' => 15,
            'is_approved' => ($user->status === 'approved'),
        ]);

        return response()->json([
            'message' => 'Pharmacy created successfully',
            'user' => $user->load('pharmacy')
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'nullable|string|max:50',
            'location' => 'nullable|string|max:255',
            'address' => 'nullable|string|max:255',
        ]);

        $userData = $request->only(['name', 'name_ar', 'name_en', 'phone', 'status']);
        $user->update($userData);

        if ($user->pharmacy) {
            $user->pharmacy->update([
                'phone' => $request->phone ?? $user->pharmacy->phone,
                'location' => $request->location ?? $request->address ?? $user->pharmacy->location,
            ]);
        }

        return response()->json([
            'message' => 'Pharmacy updated successfully',
            'user' => $user->load('pharmacy')
        ]);
    }

    public function approve($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->pharmacy) {
            $user->pharmacy()->create([
                'rating' => 4.8,
                'is_approved' => true,
            ]);
        } else {
            $user->pharmacy->update(['is_approved' => true]);
        }

        \App\Models\AppNotification::create([
            'user_id' => $user->id,
            'title' => 'هەژمارەکەت پەسەندکرا',
            'title_en' => 'Account Approved',
            'title_ar' => 'تمت الموافقة على حسابك',
            'message' => 'پیرۆزە! هەژماری دەرمانخانەکەت لەلایەن ئەدمینەوە پەسەندکرا.',
            'message_en' => 'Congratulations! Your pharmacy account has been approved by admin.',
            'message_ar' => 'مبروك! تمت الموافقة على حساب الصيدلية الخاص بك.',
            'type' => 'system',
            'is_read' => false
        ]);

        return response()->json(['message' => 'Pharmacy approved successfully', 'user' => $user->load('pharmacy')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        if ($user->pharmacy) {
            $user->pharmacy->update(['is_approved' => false]);
        }

        return response()->json(['message' => 'Pharmacy rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        if ($user->pharmacy) {
            $user->pharmacy->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}

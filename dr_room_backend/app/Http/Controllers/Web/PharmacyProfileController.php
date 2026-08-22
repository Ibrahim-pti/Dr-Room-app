<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Pharmacy;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class PharmacyProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user()->load('pharmacy');
        return view('pharmacy.profile.index', compact('user'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:30',
            'location' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'delivery_fee' => 'nullable|numeric|min:0',
            'delivery_time' => 'nullable|string|max:100',
            'facebook_url' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'profile_image' => 'nullable|image|max:2048',
        ]);

        $user = Auth::user();
        $user->name = $request->name;
        $user->phone = $request->phone;

        if ($request->hasFile('profile_image')) {
            if ($user->profile_image && !str_starts_with($user->profile_image, 'http')) {
                Storage::disk('public')->delete($user->profile_image);
            }
            $user->profile_image = $request->file('profile_image')->store('pharmacies', 'public');
        }
        $user->save();

        $pharmacy = Pharmacy::firstOrCreate(['user_id' => $user->id]);
        $pharmacy->update([
            'location' => $request->location ?? $pharmacy->location,
            'city' => $request->city ?? 'هەولێر',
            'delivery_fee' => $request->delivery_fee ?? 3000,
            'delivery_time' => $request->delivery_time ?? '۲۰-۳۰ خولەک',
            'facebook_url' => $request->facebook_url,
            'bio' => $request->bio,
            'is_open' => $request->has('is_open'),
        ]);

        return back()->with('success', 'پرۆفایل بە سەرکەوتوویی تازەکرایەوە.');
    }
}

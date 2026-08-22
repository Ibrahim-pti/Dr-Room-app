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
            'name_ar' => 'nullable|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'phone' => 'required|string|max:30',
            'location' => 'nullable|string|max:255',
            'location_ar' => 'nullable|string|max:255',
            'location_en' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'delivery_fee' => 'nullable|numeric|min:0',
            'delivery_time' => 'nullable|string|max:100',
            'facebook_url' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'bio_ar' => 'nullable|string',
            'bio_en' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'profile_image' => 'nullable|image|max:4096',
            'gallery_images' => 'nullable|array',
            'gallery_images.*' => 'nullable|image|max:4096',
        ]);

        $user = Auth::user();
        $user->name = $request->name;
        $user->name_ar = $request->name_ar;
        $user->name_en = $request->name_en;
        $user->phone = $request->phone;

        if ($request->hasFile('profile_image')) {
            if ($user->profile_image && !str_starts_with($user->profile_image, 'http')) {
                Storage::disk('public')->delete($user->profile_image);
            }
            $user->profile_image = $request->file('profile_image')->store('pharmacies', 'public');
        }
        $user->save();

        $pharmacy = Pharmacy::firstOrCreate(['user_id' => $user->id]);
        
        $gallery = $pharmacy->gallery_images ?? [];
        if (!is_array($gallery)) {
            $gallery = json_decode($gallery, true) ?? [];
        }

        if ($request->hasFile('gallery_images')) {
            foreach ($request->file('gallery_images') as $imageFile) {
                $path = $imageFile->store('pharmacies/gallery', 'public');
                $gallery[] = $path;
            }
        }

        $pharmacy->update([
            'location' => $request->location ?? $pharmacy->location,
            'location_ar' => $request->location_ar ?? $pharmacy->location_ar,
            'location_en' => $request->location_en ?? $pharmacy->location_en,
            'city' => $request->city ?? 'هەولێر',
            'delivery_fee' => $request->delivery_fee ?? 3000,
            'delivery_time' => $request->delivery_time ?? '۲۰-۳۰ خولەک',
            'facebook_url' => $request->facebook_url,
            'bio' => $request->bio,
            'bio_ar' => $request->bio_ar,
            'bio_en' => $request->bio_en,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'gallery_images' => $gallery,
            'is_open' => $request->has('is_open'),
        ]);

        return back()->with('success', 'پرۆفایل بە سەرکەوتوویی تازەکرایەوە.');
    }

    public function deleteGalleryImage(Request $request)
    {
        $request->validate([
            'image' => 'required|string',
        ]);

        $pharmacy = Auth::user()->pharmacy;
        if (!$pharmacy) {
            return back()->with('error', 'دەرمانخانە نەدۆزرایەوە.');
        }

        $gallery = $pharmacy->gallery_images ?? [];
        if (!is_array($gallery)) {
            $gallery = json_decode($gallery, true) ?? [];
        }

        $imageToDelete = $request->image;
        $newGallery = array_values(array_filter($gallery, fn($img) => $img !== $imageToDelete));

        if (!str_starts_with($imageToDelete, 'http')) {
            Storage::disk('public')->delete($imageToDelete);
        }

        $pharmacy->gallery_images = $newGallery;
        $pharmacy->save();

        return back()->with('success', 'وێنەی کارسۆل بە سەرکەوتوویی سڕایەوە.');
    }
}

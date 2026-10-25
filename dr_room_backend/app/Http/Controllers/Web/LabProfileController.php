<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $lab = $user->lab;
        return view('lab.profile.index', compact('user', 'lab'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();
        $lab = $user->lab;

        $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'phone' => 'required|string|max:20',
            'city' => 'nullable|string|max:100',
            'location' => 'nullable|string|max:255',
            'location_en' => 'nullable|string|max:255',
            'location_ar' => 'nullable|string|max:255',
            'opening_hours' => 'nullable|string|max:100',
            'youtube_url' => 'nullable|url|max:255',
            'discount' => 'nullable|integer|min:0|max:100',
            'about_us' => 'required|string|max:1000',
            'about_us_en' => 'nullable|string|max:1000',
            'about_us_ar' => 'nullable|string|max:1000',
            'latitude' => 'nullable|string|max:50',
            'longitude' => 'nullable|string|max:50',
            'home_sample_collection' => 'nullable|boolean',
            'image' => 'nullable|image|max:5120',
        ]);

        $user->update([
            'name' => $request->name,
            'name_en' => $request->name_en,
            'name_ar' => $request->name_ar,
            'name_kmr' => $request->name_kmr,
            'phone' => $request->phone,
        ]);

        $updateData = [
            'phone' => $request->phone,
            'city' => $request->city ?? 'Erbil',
            'location' => $request->location,
            'location_en' => $request->location_en,
            'location_ar' => $request->location_ar,
            'location_kmr' => $request->location_kmr,
            'opening_hours' => $request->opening_hours ?? '08:00 AM - 10:00 PM',
            'youtube_url' => $request->youtube_url,
            'discount' => $request->discount,
            'about_us' => $request->about_us,
            'about_us_en' => $request->about_us_en,
            'about_us_ar' => $request->about_us_ar,
            'about_us_kmr' => $request->about_us_kmr,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'home_sample_collection' => $request->has('home_sample_collection') ? true : false,
        ];

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('lab_images', 'public');
            $updateData['image_path'] = '/storage/' . $path;
        }

        try {
            if ($request->about_us && !$request->about_us_en) {
                $updateData['about_us_en'] = \App\Services\TranslationService::translate($request->about_us, 'en');
            }
            if ($request->about_us && !$request->about_us_ar) {
                $updateData['about_us_ar'] = \App\Services\TranslationService::translate($request->about_us, 'ar');
            }
            if ($request->about_us && !$request->about_us_kmr) {
                $updateData['about_us_kmr'] = \App\Services\TranslationService::translate($request->about_us, 'ku');
            }
            if ($request->location && !$request->location_en) {
                $updateData['location_en'] = \App\Services\TranslationService::translate($request->location, 'en');
            }
            if ($request->location && !$request->location_ar) {
                $updateData['location_ar'] = \App\Services\TranslationService::translate($request->location, 'ar');
            }
            if ($request->location && !$request->location_kmr) {
                $updateData['location_kmr'] = \App\Services\TranslationService::translate($request->location, 'ku');
            }
            if ($request->name && !$request->name_en) {
                $user->update(['name_en' => \App\Services\TranslationService::translate($request->name, 'en')]);
            }
            if ($request->name && !$request->name_ar) {
                $user->update(['name_ar' => \App\Services\TranslationService::translate($request->name, 'ar')]);
            }
            if ($request->name && !$request->name_kmr) {
                $user->update(['name_kmr' => \App\Services\TranslationService::translate($request->name, 'ku')]);
            }
        } catch (\Exception $e) {
            // Translation failed, ignore
        }

        if ($lab) {
            $lab->update($updateData);
        } else {
            $user->lab()->create($updateData);
        }

        return redirect()->back()->with('success', 'زانیارییەکانی پرۆفایل بە سەرکەوتوویی نوێکرانەوە.');
    }
}


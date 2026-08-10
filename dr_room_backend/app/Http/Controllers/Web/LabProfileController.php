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
            'phone' => $request->phone,
        ]);

        $updateData = [
            'phone' => $request->phone,
            'about_us' => $request->about_us,
            'about_us_en' => $request->about_us_en,
            'about_us_ar' => $request->about_us_ar,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'home_sample_collection' => $request->has('home_sample_collection') ? true : false,
        ];

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('lab_images', 'public');
            $updateData['image_path'] = '/storage/' . $path;
        }

        try {
            if (class_exists('\Stichoza\GoogleTranslate\GoogleTranslate')) {
                $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
                
                if ($request->about_us && !$request->about_us_en) {
                    $updateData['about_us_en'] = $tr->setTarget('en')->translate($request->about_us);
                }
                if ($request->about_us && !$request->about_us_ar) {
                    $updateData['about_us_ar'] = $tr->setTarget('ar')->translate($request->about_us);
                }
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

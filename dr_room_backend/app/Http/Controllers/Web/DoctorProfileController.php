<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $doctor = $user->doctor;
        return view('doctor.profile.index', compact('user', 'doctor'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();
        $doctor = $user->doctor;

        $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'phone' => 'required|string|max:20',
            'specialty' => 'nullable|string|max:255',
            'specialty_en' => 'nullable|string|max:255',
            'specialty_ar' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'bio_en' => 'nullable|string',
            'bio_ar' => 'nullable|string',
            'experience_years' => 'nullable|integer|min:0|max:70',
            'consultation_fee' => 'nullable|numeric|min:0',
            'clinic_name' => 'nullable|string|max:255',
            'clinic_name_en' => 'nullable|string|max:255',
            'clinic_name_ar' => 'nullable|string|max:255',
            'address' => 'nullable|string|max:500',
            'address_en' => 'nullable|string|max:500',
            'address_ar' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'image' => 'nullable|image|max:5120',
            'video_type' => 'nullable|in:youtube,uploaded',
            'youtube_url' => 'nullable|url',
            'video_file' => 'nullable|mimes:mp4,mov,ogg,qt|max:50000', // max 50MB
        ]);

        $user->update([
            'name' => $request->name,
            'name_en' => $request->name_en,
            'name_ar' => $request->name_ar,
            'phone' => $request->phone,
        ]);

        if ($doctor) {
            $updateData = [
                'specialty' => $request->specialty,
                'bio' => $request->bio,
                'experience_years' => $request->filled('experience_years') ? $request->experience_years : null,
                'consultation_fee' => $request->filled('consultation_fee') ? $request->consultation_fee : null,
                'clinic_name' => $request->clinic_name,
                'clinic_name_en' => $request->clinic_name_en,
                'clinic_name_ar' => $request->clinic_name_ar,
                'address' => $request->address,
                'address_en' => $request->address_en,
                'address_ar' => $request->address_ar,
                'latitude' => $request->filled('latitude') ? $request->latitude : null,
                'longitude' => $request->filled('longitude') ? $request->longitude : null,
                // The API exposes the doctor record, not the user, so the
                // contact number has to live on both.
                'phone' => $request->phone,
            ];

            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('doctor_images', 'public');
                $updateData['image_path'] = '/storage/' . $path;
            }

            if ($request->has('video_type')) {
                $updateData['video_type'] = $request->video_type;
                if ($request->video_type === 'youtube') {
                    $updateData['video_url'] = $request->youtube_url;
                } elseif ($request->video_type === 'uploaded' && $request->hasFile('video_file')) {
                    $path = $request->file('video_file')->store('doctor_videos', 'public');
                    $updateData['video_url'] = '/storage/' . $path;
                }
            }

            $updateData['specialty_en'] = $request->specialty_en;
            $updateData['specialty_ar'] = $request->specialty_ar;
            $updateData['bio_en'] = $request->bio_en;
            $updateData['bio_ar'] = $request->bio_ar;
            
            try {
                $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
                if ($request->specialty && !$request->specialty_en) {
                    $updateData['specialty_en'] = $tr->setTarget('en')->translate($request->specialty);
                }
                if ($request->specialty && !$request->specialty_ar) {
                    $updateData['specialty_ar'] = $tr->setTarget('ar')->translate($request->specialty);
                }
                if ($request->bio && !$request->bio_en) {
                    $updateData['bio_en'] = $tr->setTarget('en')->translate($request->bio);
                }
                if ($request->bio && !$request->bio_ar) {
                    $updateData['bio_ar'] = $tr->setTarget('ar')->translate($request->bio);
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Translation failed: ' . $e->getMessage());
            }

            $doctor->update($updateData);
        }

        return back()->with('success', 'زانیارییەکانی پڕۆفایل نوێکرانەوە.');
    }
}

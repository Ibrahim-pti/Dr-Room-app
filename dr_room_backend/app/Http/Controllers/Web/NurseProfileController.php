<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;
        return view('nurse.profile.index', compact('user', 'nurse'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'phone' => 'required|string|max:20',
            'specialty' => 'nullable|string|max:500',
            'specialty_en' => 'nullable|string|max:500',
            'specialty_ar' => 'nullable|string|max:500',
            'specialties' => 'nullable|array',
            'specialties.*.name' => 'nullable|string|max:255',
            'specialties.*.name_en' => 'nullable|string|max:255',
            'specialties.*.name_ar' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'bio_en' => 'nullable|string',
            'bio_ar' => 'nullable|string',
            'city' => 'nullable|string|max:100',
            'service_type' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:500',
            'address_en' => 'nullable|string|max:500',
            'address_ar' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'is_available' => 'nullable|boolean',
            'fee' => 'nullable|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:3072',
        ]);

        // Process multiple specialties
        $specialtiesList = [];
        if ($request->has('specialties') && is_array($request->specialties)) {
            foreach ($request->specialties as $s) {
                if (!empty($s['name'])) {
                    $specialtiesList[] = [
                        'name' => trim($s['name']),
                        'name_en' => trim($s['name_en'] ?? ''),
                        'name_ar' => trim($s['name_ar'] ?? ''),
                    ];
                }
            }
        }

        $specialtyKurdish = $request->specialty;
        $specialtyEn = $request->specialty_en;
        $specialtyAr = $request->specialty_ar;

        if (!empty($specialtiesList)) {
            $specialtyKurdish = implode('، ', array_column($specialtiesList, 'name'));
            $specialtyEn = implode(', ', array_filter(array_column($specialtiesList, 'name_en')));
            $specialtyAr = implode('، ', array_filter(array_column($specialtiesList, 'name_ar')));
        }

        // Automatic Translation helper
        $userNameEn = $request->name_en;
        $userNameAr = $request->name_ar;
        $bioEn = $request->bio_en;
        $bioAr = $request->bio_ar;
        $addressEn = $request->address_en;
        $addressAr = $request->address_ar;

        try {
            $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
            
            // Name translations
            if ($request->name && !$userNameEn) {
                $userNameEn = $tr->setTarget('en')->translate($request->name);
            }
            if ($request->name && !$userNameAr) {
                $userNameAr = $tr->setTarget('ar')->translate($request->name);
            }

            // Specialty translations
            if ($specialtyKurdish && !$specialtyEn) {
                $specialtyEn = $tr->setTarget('en')->translate($specialtyKurdish);
            }
            if ($specialtyKurdish && !$specialtyAr) {
                $specialtyAr = $tr->setTarget('ar')->translate($specialtyKurdish);
            }

            // Bio translations
            if ($request->bio && !$bioEn) {
                $bioEn = $tr->setTarget('en')->translate($request->bio);
            }
            if ($request->bio && !$bioAr) {
                $bioAr = $tr->setTarget('ar')->translate($request->bio);
            }

            // Address translations
            if ($request->address && !$addressEn) {
                $addressEn = $tr->setTarget('en')->translate($request->address);
            }
            if ($request->address && !$addressAr) {
                $addressAr = $tr->setTarget('ar')->translate($request->address);
            }

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Nurse profile translation failed: ' . $e->getMessage());
        }

        $user->update([
            'name' => $request->name,
            'name_en' => $userNameEn,
            'name_ar' => $userNameAr,
            'phone' => $request->phone,
        ]);

        if ($nurse) {
            $updateData = [
                'specialty' => $specialtyKurdish,
                'specialty_en' => $specialtyEn,
                'specialty_ar' => $specialtyAr,
                'bio' => $request->bio,
                'bio_en' => $bioEn,
                'bio_ar' => $bioAr,
                'address' => $request->address,
                'address_en' => $addressEn,
                'address_ar' => $addressAr,
                'latitude' => $request->filled('latitude') ? $request->latitude : null,
                'longitude' => $request->filled('longitude') ? $request->longitude : null,
                'is_available' => $request->has('is_available') ? (bool) $request->is_available : $nurse->is_available,
                'fee' => $request->fee ?? $nurse->fee,
                'city' => $request->city ?? $nurse->city,
                'service_type' => $request->service_type ?? $nurse->service_type,
                'phone' => $request->phone,
            ];

            // Handle image upload
            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('nurses', 'public');
                $updateData['image_path'] = $path;
            }

            $nurse->update($updateData);
        }

        return back()->with('success', 'زانیارییەکانی پڕۆفایل بە سەرکەوتوویی نوێکرانەوە و وەرگێڕدران.');
    }

    /**
     * AJAX Translate All fields to English and Arabic in real time
     */
    public function translateAll(Request $request)
    {
        $request->validate([
            'name' => 'nullable|string',
            'specialty' => 'nullable|string',
            'specialties' => 'nullable|array',
            'city' => 'nullable|string',
            'address' => 'nullable|string',
            'bio' => 'nullable|string',
        ]);

        $translations = [
            'name_en' => '',
            'name_ar' => '',
            'specialty_en' => '',
            'specialty_ar' => '',
            'specialties_translated' => [],
            'city_en' => '',
            'city_ar' => '',
            'address_en' => '',
            'address_ar' => '',
            'bio_en' => '',
            'bio_ar' => '',
        ];

        try {
            $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();

            if ($request->filled('name')) {
                $translations['name_en'] = $tr->setTarget('en')->translate($request->name);
                $translations['name_ar'] = $tr->setTarget('ar')->translate($request->name);
            }

            if ($request->has('specialties') && is_array($request->specialties)) {
                $specList = [];
                foreach ($request->specialties as $idx => $s) {
                    $kurdish = trim($s['name'] ?? '');
                    $en = trim($s['name_en'] ?? '');
                    $ar = trim($s['name_ar'] ?? '');
                    if ($kurdish) {
                        if (!$en) $en = $tr->setTarget('en')->translate($kurdish);
                        if (!$ar) $ar = $tr->setTarget('ar')->translate($kurdish);
                    }
                    $specList[$idx] = [
                        'name' => $kurdish,
                        'name_en' => $en,
                        'name_ar' => $ar,
                    ];
                }
                $translations['specialties_translated'] = $specList;
            }

            if ($request->filled('specialty')) {
                $translations['specialty_en'] = $tr->setTarget('en')->translate($request->specialty);
                $translations['specialty_ar'] = $tr->setTarget('ar')->translate($request->specialty);
            }
            if ($request->filled('city')) {
                $translations['city_en'] = $tr->setTarget('en')->translate($request->city);
                $translations['city_ar'] = $tr->setTarget('ar')->translate($request->city);
            }
            if ($request->filled('address')) {
                $translations['address_en'] = $tr->setTarget('en')->translate($request->address);
                $translations['address_ar'] = $tr->setTarget('ar')->translate($request->address);
            }
            if ($request->filled('bio')) {
                $translations['bio_en'] = $tr->setTarget('en')->translate($request->bio);
                $translations['bio_ar'] = $tr->setTarget('ar')->translate($request->bio);
            }

            return response()->json([
                'success' => true,
                'data' => $translations,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'وەرگێڕان سەرکەوتوو نەبوو: ' . $e->getMessage(),
            ], 500);
        }
    }
}


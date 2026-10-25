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
            'name_kmr' => 'nullable|string|max:255',
            'phone' => 'required|string|max:20',
            'specialty' => 'nullable|string|max:500',
            'specialty_en' => 'nullable|string|max:500',
            'specialty_ar' => 'nullable|string|max:500',
            'specialty_kmr' => 'nullable|string|max:500',
            'specialties' => 'nullable|array',
            'specialties.*.name' => 'nullable|string|max:255',
            'specialties.*.name_en' => 'nullable|string|max:255',
            'specialties.*.name_ar' => 'nullable|string|max:255',
            'specialties.*.name_kmr' => 'nullable|string|max:255',
            'custom_services' => 'nullable|array',
            'custom_services.*.name' => 'nullable|string|max:255',
            'custom_services.*.name_en' => 'nullable|string|max:255',
            'custom_services.*.name_ar' => 'nullable|string|max:255',
            'custom_services.*.name_kmr' => 'nullable|string|max:255',
            'custom_services.*.price' => 'nullable|numeric|min:0',
            'bio' => 'nullable|string',
            'bio_en' => 'nullable|string',
            'bio_ar' => 'nullable|string',
            'bio_kmr' => 'nullable|string',
            'city' => 'nullable|string|max:100',
            'service_type' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:500',
            'address_en' => 'nullable|string|max:500',
            'address_ar' => 'nullable|string|max:500',
            'address_kmr' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'is_available' => 'nullable|boolean',
            'fee' => 'nullable|numeric|min:0',
            'experience_years' => 'nullable|integer|min:0|max:70',
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
                        'name_kmr' => trim($s['name_kmr'] ?? ''),
                    ];
                }
            }
        }

        $specialtyKurdish = $request->specialty;
        $specialtyEn = $request->specialty_en;
        $specialtyAr = $request->specialty_ar;
        $specialtyKmr = $request->specialty_kmr;

        if (!empty($specialtiesList)) {
            $specialtyKurdish = implode('، ', array_column($specialtiesList, 'name'));
            $specialtyEn = implode(', ', array_filter(array_column($specialtiesList, 'name_en')));
            $specialtyAr = implode('، ', array_filter(array_column($specialtiesList, 'name_ar')));
            $specialtyKmr = implode('، ', array_filter(array_column($specialtiesList, 'name_kmr')));
        }

        // Process custom services & fees
        $customServicesList = [];
        if ($request->has('custom_services') && is_array($request->custom_services)) {
            foreach ($request->custom_services as $cs) {
                if (!empty($cs['name'])) {
                    $customServicesList[] = [
                        'name' => trim($cs['name']),
                        'name_en' => trim($cs['name_en'] ?? ''),
                        'name_ar' => trim($cs['name_ar'] ?? ''),
                        'name_kmr' => trim($cs['name_kmr'] ?? ''),
                        'price' => !empty($cs['price']) ? (float)$cs['price'] : 0,
                    ];
                }
            }
        }

        // Automatic Translation helper
        $userNameEn = $request->name_en;
        $userNameAr = $request->name_ar;
        $userNameKmr = $request->name_kmr;
        $bioEn = $request->bio_en;
        $bioAr = $request->bio_ar;
        $bioKmr = $request->bio_kmr;
        $addressEn = $request->address_en;
        $addressAr = $request->address_ar;
        $addressKmr = $request->address_kmr;

        try {
            // Name translations
            if ($request->name && !$userNameEn) {
                $userNameEn = \App\Services\TranslationService::translate($request->name, 'en');
            }
            if ($request->name && !$userNameAr) {
                $userNameAr = \App\Services\TranslationService::translate($request->name, 'ar');
            }
            if ($request->name && !$userNameKmr) {
                $userNameKmr = \App\Services\TranslationService::translate($request->name, 'ku');
            }

            // Specialty translations
            if ($specialtyKurdish && !$specialtyEn) {
                $specialtyEn = \App\Services\TranslationService::translate($specialtyKurdish, 'en');
            }
            if ($specialtyKurdish && !$specialtyAr) {
                $specialtyAr = \App\Services\TranslationService::translate($specialtyKurdish, 'ar');
            }
            if ($specialtyKurdish && !$specialtyKmr) {
                $specialtyKmr = \App\Services\TranslationService::translate($specialtyKurdish, 'ku');
            }

            // Custom services translations
            foreach ($customServicesList as &$cService) {
                if (!empty($cService['name'])) {
                    if (empty($cService['name_en'])) {
                        $cService['name_en'] = \App\Services\TranslationService::translate($cService['name'], 'en');
                    }
                    if (empty($cService['name_ar'])) {
                        $cService['name_ar'] = \App\Services\TranslationService::translate($cService['name'], 'ar');
                    }
                    if (empty($cService['name_kmr'])) {
                        $cService['name_kmr'] = \App\Services\TranslationService::translate($cService['name'], 'ku');
                    }
                }
            }
            unset($cService);

            // Bio translations
            if ($request->bio && !$bioEn) {
                $bioEn = \App\Services\TranslationService::translate($request->bio, 'en');
            }
            if ($request->bio && !$bioAr) {
                $bioAr = \App\Services\TranslationService::translate($request->bio, 'ar');
            }
            if ($request->bio && !$bioKmr) {
                $bioKmr = \App\Services\TranslationService::translate($request->bio, 'ku');
            }

            // Address translations
            if ($request->address && !$addressEn) {
                $addressEn = \App\Services\TranslationService::translate($request->address, 'en');
            }
            if ($request->address && !$addressAr) {
                $addressAr = \App\Services\TranslationService::translate($request->address, 'ar');
            }
            if ($request->address && !$addressKmr) {
                $addressKmr = \App\Services\TranslationService::translate($request->address, 'ku');
            }

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Nurse profile translation failed: ' . $e->getMessage());
        }

        $user->update([
            'name' => $request->name,
            'name_en' => $userNameEn,
            'name_ar' => $userNameAr,
            'name_kmr' => $userNameKmr,
            'phone' => $request->phone,
        ]);

        if ($nurse) {
            $updateData = [
                'specialty' => $specialtyKurdish,
                'specialty_en' => $specialtyEn,
                'specialty_ar' => $specialtyAr,
                'specialty_kmr' => $specialtyKmr,
                'custom_services' => $customServicesList,
                'bio' => $request->bio,
                'bio_en' => $bioEn,
                'bio_ar' => $bioAr,
                'bio_kmr' => $bioKmr,
                'address' => $request->address,
                'address_en' => $addressEn,
                'address_ar' => $addressAr,
                'address_kmr' => $addressKmr,
                'latitude' => $request->filled('latitude') ? $request->latitude : null,
                'longitude' => $request->filled('longitude') ? $request->longitude : null,
                'is_available' => $request->has('is_available') ? (bool) $request->is_available : $nurse->is_available,
                'fee' => $request->fee ?? $nurse->fee,
                'experience_years' => $request->filled('experience_years') ? (int) $request->experience_years : $nurse->experience_years,
                'city' => $request->city ?? $nurse->city,
                'service_type' => $request->service_type ?? $nurse->service_type,
                'phone' => $request->phone,
            ];

            // Handle image upload (Cropped base64 or File)
            if ($request->filled('cropped_image')) {
                try {
                    $imageData = $request->input('cropped_image');
                    // Extract base64 part
                    if (preg_match('/^data:image\/(\w+);base64,/', $imageData, $type)) {
                        $imageData = substr($imageData, strpos($imageData, ',') + 1);
                        $type = strtolower($type[1]); // jpg, png, jpeg
                        if (!in_array($type, ['jpg', 'jpeg', 'gif', 'png', 'webp'])) {
                            $type = 'jpg';
                        }
                        $decodedImage = base64_decode($imageData);
                        if ($decodedImage !== false) {
                            $filename = 'nurses/' . uniqid('nurse_', true) . '.' . $type;
                            \Illuminate\Support\Facades\Storage::disk('public')->put($filename, $decodedImage);
                            $updateData['image_path'] = $filename;
                        }
                    }
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error('Error saving cropped nurse image: ' . $e->getMessage());
                }
            } elseif ($request->hasFile('image')) {
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
            'custom_services' => 'nullable|array',
            'city' => 'nullable|string',
            'address' => 'nullable|string',
            'bio' => 'nullable|string',
        ]);

        $translations = [
            'name_en' => '',
            'name_ar' => '',
            'name_kmr' => '',
            'specialty_en' => '',
            'specialty_ar' => '',
            'specialty_kmr' => '',
            'specialties_translated' => [],
            'custom_services_translated' => [],
            'city_en' => '',
            'city_ar' => '',
            'city_kmr' => '',
            'address_en' => '',
            'address_ar' => '',
            'address_kmr' => '',
            'bio_en' => '',
            'bio_ar' => '',
            'bio_kmr' => '',
        ];

        try {
            if ($request->filled('name')) {
                $translations['name_en'] = \App\Services\TranslationService::translate($request->name, 'en');
                $translations['name_ar'] = \App\Services\TranslationService::translate($request->name, 'ar');
                $translations['name_kmr'] = \App\Services\TranslationService::translate($request->name, 'ku');
            }

            if ($request->has('specialties') && is_array($request->specialties)) {
                $specList = [];
                foreach ($request->specialties as $idx => $s) {
                    $kurdish = trim($s['name'] ?? '');
                    $en = trim($s['name_en'] ?? '');
                    $ar = trim($s['name_ar'] ?? '');
                    $kmr = trim($s['name_kmr'] ?? '');
                    if ($kurdish) {
                        if (!$en) $en = \App\Services\TranslationService::translate($kurdish, 'en');
                        if (!$ar) $ar = \App\Services\TranslationService::translate($kurdish, 'ar');
                        if (!$kmr) $kmr = \App\Services\TranslationService::translate($kurdish, 'ku');
                    }
                    $specList[$idx] = [
                        'name' => $kurdish,
                        'name_en' => $en,
                        'name_ar' => $ar,
                        'name_kmr' => $kmr,
                    ];
                }
                $translations['specialties_translated'] = $specList;
            }

            if ($request->has('custom_services') && is_array($request->custom_services)) {
                $csList = [];
                foreach ($request->custom_services as $idx => $cs) {
                    $kurdish = trim($cs['name'] ?? '');
                    $en = trim($cs['name_en'] ?? '');
                    $ar = trim($cs['name_ar'] ?? '');
                    $kmr = trim($cs['name_kmr'] ?? '');
                    if ($kurdish) {
                        if (!$en) $en = \App\Services\TranslationService::translate($kurdish, 'en');
                        if (!$ar) $ar = \App\Services\TranslationService::translate($kurdish, 'ar');
                        if (!$kmr) $kmr = \App\Services\TranslationService::translate($kurdish, 'ku');
                    }
                    $csList[$idx] = [
                        'name' => $kurdish,
                        'name_en' => $en,
                        'name_ar' => $ar,
                        'name_kmr' => $kmr,
                    ];
                }
                $translations['custom_services_translated'] = $csList;
            }

            if ($request->filled('specialty')) {
                $translations['specialty_en'] = \App\Services\TranslationService::translate($request->specialty, 'en');
                $translations['specialty_ar'] = \App\Services\TranslationService::translate($request->specialty, 'ar');
                $translations['specialty_kmr'] = \App\Services\TranslationService::translate($request->specialty, 'ku');
            }
            if ($request->filled('city')) {
                $translations['city_en'] = \App\Services\TranslationService::translate($request->city, 'en');
                $translations['city_ar'] = \App\Services\TranslationService::translate($request->city, 'ar');
                $translations['city_kmr'] = \App\Services\TranslationService::translate($request->city, 'ku');
            }
            if ($request->filled('address')) {
                $translations['address_en'] = \App\Services\TranslationService::translate($request->address, 'en');
                $translations['address_ar'] = \App\Services\TranslationService::translate($request->address, 'ar');
                $translations['address_kmr'] = \App\Services\TranslationService::translate($request->address, 'ku');
            }
            if ($request->filled('bio')) {
                $translations['bio_en'] = \App\Services\TranslationService::translate($request->bio, 'en');
                $translations['bio_ar'] = \App\Services\TranslationService::translate($request->bio, 'ar');
                $translations['bio_kmr'] = \App\Services\TranslationService::translate($request->bio, 'ku');
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


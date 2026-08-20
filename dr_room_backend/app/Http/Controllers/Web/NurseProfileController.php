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
            'specialty' => 'nullable|string|max:255',
            'specialty_en' => 'nullable|string|max:255',
            'specialty_ar' => 'nullable|string|max:255',
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
            'offered_services' => 'nullable|array',
            'offered_services.*' => 'string',
            'custom_services' => 'nullable|array',
            'custom_services.*.name' => 'nullable|string|max:255',
            'custom_services.*.price' => 'nullable|numeric|min:0',
            'is_available' => 'nullable|boolean',
            'fee' => 'nullable|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:3072',
        ]);

        // Clean and prepare custom services
        $customServices = [];
        if ($request->has('custom_services') && is_array($request->custom_services)) {
            foreach ($request->custom_services as $cs) {
                if (!empty($cs['name'])) {
                    $customServices[] = [
                        'name' => trim($cs['name']),
                        'name_en' => trim($cs['name_en'] ?? ''),
                        'name_ar' => trim($cs['name_ar'] ?? ''),
                        'price' => isset($cs['price']) && is_numeric($cs['price']) ? (float)$cs['price'] : null,
                        'description' => trim($cs['description'] ?? ''),
                    ];
                }
            }
        }

        // Automatic Translation helper
        $userNameEn = $request->name_en;
        $userNameAr = $request->name_ar;
        $specialtyEn = $request->specialty_en;
        $specialtyAr = $request->specialty_ar;
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
            if ($request->specialty && !$specialtyEn) {
                $specialtyEn = $tr->setTarget('en')->translate($request->specialty);
            }
            if ($request->specialty && !$specialtyAr) {
                $specialtyAr = $tr->setTarget('ar')->translate($request->specialty);
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

            // Custom services translations
            foreach ($customServices as &$csItem) {
                if (!empty($csItem['name'])) {
                    if (empty($csItem['name_en'])) {
                        $csItem['name_en'] = $tr->setTarget('en')->translate($csItem['name']);
                    }
                    if (empty($csItem['name_ar'])) {
                        $csItem['name_ar'] = $tr->setTarget('ar')->translate($csItem['name']);
                    }
                }
            }
            unset($csItem);

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
                'specialty' => $request->specialty,
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
                'offered_services' => $request->offered_services ?? [],
                'custom_services' => $customServices,
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
}

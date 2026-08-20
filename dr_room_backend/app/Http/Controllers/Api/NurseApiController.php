<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Nurse;
use App\Models\NurseAppointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseApiController extends Controller
{
    /**
     * List all approved nurses (like the doctor listing).
     */
    public function index(Request $request)
    {
        $query = Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,email,profile_image']);

        if ($request->has('specialty') && $request->specialty) {
            $query->where('specialty', 'like', '%' . $request->specialty . '%');
        }

        // Filter by city
        if ($request->has('city') && $request->city) {
            $query->where('city', $request->city);
        }

        // Filter by service_type (home_nursing, clinic, hospital)
        if ($request->has('service_type') && $request->service_type) {
            $query->where('service_type', $request->service_type);
        }

        $nurses = $query->get()->map(function ($nurse) {
            return [
                'id' => $nurse->id,
                'name' => $nurse->user->name ?? '',
                'name_en' => $nurse->user->name_en ?? '',
                'name_ar' => $nurse->user->name_ar ?? '',
                'specialty' => $nurse->specialty ?? '',
                'specialty_en' => $nurse->specialty_en ?? '',
                'specialty_ar' => $nurse->specialty_ar ?? '',
                'bio' => $nurse->bio ?? '',
                'bio_en' => $nurse->bio_en ?? '',
                'bio_ar' => $nurse->bio_ar ?? '',
                'phone' => $nurse->phone ?? '',
                'city' => $nurse->city ?? '',
                'address' => $nurse->address ?? '',
                'address_en' => $nurse->address_en ?? '',
                'address_ar' => $nurse->address_ar ?? '',
                'latitude' => $nurse->latitude,
                'longitude' => $nurse->longitude,
                'service_type' => $nurse->service_type ?? 'home_nursing',
                'image' => $nurse->image_path
                    ? asset('storage/' . $nurse->image_path)
                    : ($nurse->user->profile_image
                        ? asset('storage/' . $nurse->user->profile_image)
                        : null),
                'is_available' => $nurse->is_available ?? true,
                'fee' => $nurse->fee,
                'offered_services' => $nurse->offered_services ?? [],
                'custom_services' => $nurse->custom_services ?? [],
                'completed_appointments' => $nurse->nurseAppointments()
                    ->where('status', 'completed')->count(),
            ];
        });

        // Dynamic city categories from database
        $cities = Nurse::where('is_approved', true)
            ->whereNotNull('city')
            ->where('city', '!=', '')
            ->distinct()
            ->pluck('city')
            ->toArray();

        // Build city categories with Kurdish/Arabic/English names
        $cityMap = [
            'Erbil'         => ['name' => 'هەولێر',     'name_en' => 'Erbil',         'name_ar' => 'أربيل'],
            'Sulaymaniyah'  => ['name' => 'سلێمانی',    'name_en' => 'Sulaymaniyah',  'name_ar' => 'السليمانية'],
            'Duhok'         => ['name' => 'دهۆک',       'name_en' => 'Duhok',         'name_ar' => 'دهوك'],
            'Kirkuk'        => ['name' => 'کەرکووک',    'name_en' => 'Kirkuk',        'name_ar' => 'كركوك'],
            'Halabja'       => ['name' => 'هەڵەبجە',    'name_en' => 'Halabja',       'name_ar' => 'حلبجة'],
        ];

        $categories = [];

        // Always include "Home Nursing" category
        $categories[] = [
            'id' => 'home_nursing',
            'name' => 'پەرستاری ماڵ',
            'name_en' => 'Home Nursing',
            'name_ar' => 'تمريض منزلي',
            'type' => 'service_type',
            'icon' => 'home',
        ];

        // Add dynamic city categories from DB
        foreach ($cities as $city) {
            $mapped = $cityMap[$city] ?? ['name' => $city, 'name_en' => $city, 'name_ar' => $city];
            $categories[] = [
                'id' => $city,
                'name' => $mapped['name'],
                'name_en' => $mapped['name_en'],
                'name_ar' => $mapped['name_ar'],
                'type' => 'city',
                'icon' => 'location',
            ];
        }

        return response()->json([
            'success' => true,
            'nurses' => $nurses,
            'categories' => $categories,
        ]);
    }

    /**
     * Show a single nurse's details.
     */
    public function show($id)
    {
        $nurse = Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,email,profile_image'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'nurse' => [
                'id' => $nurse->id,
                'name' => $nurse->user->name ?? '',
                'name_en' => $nurse->user->name_en ?? '',
                'name_ar' => $nurse->user->name_ar ?? '',
                'specialty' => $nurse->specialty ?? '',
                'specialty_en' => $nurse->specialty_en ?? '',
                'specialty_ar' => $nurse->specialty_ar ?? '',
                'bio' => $nurse->bio ?? '',
                'bio_en' => $nurse->bio_en ?? '',
                'bio_ar' => $nurse->bio_ar ?? '',
                'phone' => $nurse->phone ?? '',
                'city' => $nurse->city ?? '',
                'address' => $nurse->address ?? '',
                'address_en' => $nurse->address_en ?? '',
                'address_ar' => $nurse->address_ar ?? '',
                'latitude' => $nurse->latitude,
                'longitude' => $nurse->longitude,
                'service_type' => $nurse->service_type ?? 'home_nursing',
                'fee' => $nurse->fee,
                'is_available' => $nurse->is_available ?? true,
                'offered_services' => $nurse->offered_services ?? [],
                'custom_services' => $nurse->custom_services ?? [],
                'image' => $nurse->image_path
                    ? asset('storage/' . $nurse->image_path)
                    : ($nurse->user->profile_image
                        ? asset('storage/' . $nurse->user->profile_image)
                        : null),
                'completed_appointments' => $nurse->nurseAppointments()
                    ->where('status', 'completed')->count(),
            ],
        ]);
    }

    /**
     * Get the list of available nursing services.
     */
    public function getServices()
    {
        $services = [
            [
                'id' => 'injection',
                'name' => 'دەرزی',
                'description' => 'دەرزی ماسولکە، دەمار، یان ژێر پێست لە ماڵەوە',
                'icon' => 'Icons.medical_services',
                'price' => 15000,
            ],
            [
                'id' => 'cannula',
                'name' => 'دانانی کانیۆلا',
                'description' => 'دانان و چاودێریکردنی کانیۆلای دەمار بە شێوەیەکی پڕۆفیشناڵ',
                'icon' => 'Icons.vaccines',
                'price' => 20000,
            ],
            [
                'id' => 'dressing',
                'name' => 'پێچانەوەی برین (پانسیمان)',
                'description' => 'پاککردنەوە و پێچانەوەی برین و دوای نەشتەرگەری',
                'icon' => 'Icons.healing',
                'price' => 25000,
            ],
            [
                'id' => 'checkup',
                'name' => 'چاودێری خێرا',
                'description' => 'پشکنینی سەرەتایی، پەستانی خوێن، و چاودێری نیشانە ژیانییەکان',
                'icon' => 'Icons.monitor_heart',
                'price' => 10000,
            ],
        ];

        return response()->json([
            'success' => true,
            'services' => $services,
        ]);
    }

    /**
     * Book a nursing service.
     */
    public function book(Request $request)
    {
        $request->validate([
            'nurse_id' => 'nullable|exists:nurses,id',
            'services' => 'required|array',
            'address' => 'required|string',
            'phone' => 'required|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'appointment_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $nurseId = $request->nurse_id;
        $fee = 0;

        if ($nurseId) {
            $nurse = Nurse::find($nurseId);
            // In a real app, fee calculation might be more complex. For now, use the nurse's base fee.
            $fee = $nurse->fee ?? $this->calculateTotalFee($request->services);
        } else {
            $fee = $this->calculateTotalFee($request->services);
        }

        $appointment = NurseAppointment::create([
            'patient_id' => Auth::id(),
            'nurse_id' => $nurseId,
            'services' => $request->services, // ['injection', 'cannula']
            'address' => $request->address,
            'phone' => $request->phone,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'appointment_date' => $request->appointment_date,
            'notes' => $request->notes,
            'status' => 'pending',
            'type' => 'home_visit', // Usually home visit from the app
            'fee' => $fee,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'داواکارییەکەت بە سەرکەوتوویی نێردرا',
            'appointment' => $appointment,
        ]);
    }

    private function calculateTotalFee(array $serviceIds)
    {
        $prices = [
            'injection' => 15000,
            'cannula' => 20000,
            'dressing' => 25000,
            'checkup' => 10000,
        ];

        $total = 0;
        foreach ($serviceIds as $id) {
            if (isset($prices[$id])) {
                $total += $prices[$id];
            }
        }
        return $total;
    }
}

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
                'image' => $nurse->image_path
                    ? asset('storage/' . $nurse->image_path)
                    : ($nurse->user->profile_image
                        ? asset('storage/' . $nurse->user->profile_image)
                        : null),
                'completed_appointments' => $nurse->nurseAppointments()
                    ->where('status', 'completed')->count(),
            ];
        });

        return response()->json([
            'success' => true,
            'nurses' => $nurses,
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
            'services' => 'required|array',
            'address' => 'required|string',
            'phone' => 'required|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'appointment_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $appointment = NurseAppointment::create([
            'patient_id' => Auth::id(),
            'nurse_id' => null, // Will be assigned by admin or claimed by a nurse
            'services' => $request->services, // ['injection', 'cannula']
            'address' => $request->address,
            'phone' => $request->phone,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'appointment_date' => $request->appointment_date,
            'notes' => $request->notes,
            'status' => 'pending',
            'type' => 'home_visit', // Usually home visit from the app
            'fee' => $this->calculateTotalFee($request->services),
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

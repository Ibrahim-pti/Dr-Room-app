<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Doctor;
use App\Models\Pharmacy;
use App\Models\Medication;
use App\Models\Lab;
use App\Models\Nurse;

class GlobalSearchController extends Controller
{
    public function search(Request $request)
    {
        $query = $request->input('q');

        // Functions to map database models to API JSON format expected by Flutter
        $mapDoctor = function($doc) {
            return [
                'id' => $doc->id,
                'name' => $doc->user ? $doc->user->name : 'Doctor',
                'specialization' => $doc->specialty,
                'image' => $doc->image_path,
                'experience_years' => $doc->experience_years,
                'rating' => $doc->rating,
                'fee' => $doc->consultation_fee
            ];
        };

        $mapPharmacy = function($ph) {
            return [
                'id' => $ph->id,
                'name' => $ph->user ? $ph->user->name : 'Pharmacy',
                'address' => $ph->location,
                'image' => $ph->image_path,
                'rating' => $ph->rating,
                'delivery_time' => 30, // Default dummy values since not in schema
                'delivery_fee' => 2000,
                'is_open' => $ph->is_approved ? 1 : 0
            ];
        };

        $mapLab = function($lab) {
            return [
                'id' => $lab->id,
                'name' => $lab->user ? $lab->user->name : 'Lab',
                'address' => $lab->location,
                'image' => $lab->image_path,
                'rating' => $lab->rating,
                'is_open' => $lab->is_approved ? 1 : 0
            ];
        };

        $mapNurse = function($nurse) {
            $user = $nurse->user;
            $rawName = $user ? $user->name : ($nurse->name ?? 'Nurse');
            $nameKu = (strtolower(trim($rawName)) === 'aesha fatih') ? 'عائشە فاتیح' : ($user->name_kmr ?? $rawName);
            $rawSpec = $nurse->specialty ?? '';
            $specKu = (str_contains(strtolower($rawSpec), 'general care')) ? 'چاودێری گشتی' : $rawSpec;

            return [
                'id' => $nurse->id,
                'name' => $nameKu,
                'name_ku' => $nameKu,
                'name_en' => $user ? ($user->name_en ?? $rawName) : $rawName,
                'name_ar' => $user ? ($user->name_ar ?? $rawName) : $rawName,
                'specialty' => $specKu,
                'specialty_ku' => $specKu,
                'specialty_en' => $nurse->specialty_en ?? $rawSpec,
                'specialty_ar' => $nurse->specialty_ar ?? $rawSpec,
                'city' => $nurse->city ?? '',
                'address' => $nurse->address ?? '',
                'image' => $nurse->image_path
                    ? (str_starts_with($nurse->image_path, 'http') ? $nurse->image_path : asset('storage/' . $nurse->image_path))
                    : ($user && $user->profile_image ? asset('storage/' . $user->profile_image) : null),
                'rating' => (float) ($nurse->rating ?? 4.8),
                'total_reviews' => (int) ($nurse->total_reviews ?? 0),
                'experience_years' => (int) ($nurse->experience_years ?? 1),
                'is_available' => (bool) ($nurse->is_available ?? true),
                'fee' => $nurse->fee ?? 15000,
                'service_type' => $nurse->service_type ?? 'home_nursing',
            ];
        };

        $mapMedication = function($med) {
            return [
                'id' => $med->id,
                'pharmacy_id' => $med->user_id, // Linked via user
                'name' => $med->name,
                'price' => $med->price,
                'image' => $med->image_path,
                'pharmacy' => ['name' => $med->user ? $med->user->name : 'Pharmacy']
            ];
        };

        if (!$query) {
            $doctors = Doctor::with('user:id,name')->limit(10)->get()->map($mapDoctor);
            $pharmacies = Pharmacy::with('user:id,name')->limit(10)->get()->map($mapPharmacy);
            $labs = Lab::with('user:id,name')->limit(10)->get()->map($mapLab);
            $nurses = Nurse::where('is_approved', true)->with('user:id,name,name_en,name_ar,profile_image')->limit(15)->get()->map($mapNurse);
            $medications = Medication::with('user:id,name')->limit(10)->get()->map($mapMedication);
        } else {
            $doctors = Doctor::with('user:id,name')
                ->whereHas('user', function($q) use ($query) {
                    $q->where('name', 'LIKE', "%{$query}%");
                })
                ->orWhere('specialty', 'LIKE', "%{$query}%")
                ->limit(10)
                ->get()
                ->map($mapDoctor);

            $pharmacies = Pharmacy::with('user:id,name')
                ->whereHas('user', function($q) use ($query) {
                    $q->where('name', 'LIKE', "%{$query}%");
                })
                ->orWhere('location', 'LIKE', "%{$query}%")
                ->limit(10)
                ->get()
                ->map($mapPharmacy);

            $labs = Lab::with('user:id,name')
                ->whereHas('user', function($q) use ($query) {
                    $q->where('name', 'LIKE', "%{$query}%");
                })
                ->orWhere('location', 'LIKE', "%{$query}%")
                ->limit(10)
                ->get()
                ->map($mapLab);

            $nurses = Nurse::where('is_approved', true)
                ->where(function($q) use ($query) {
                    $q->whereHas('user', function($u) use ($query) {
                        $u->where('name', 'LIKE', "%{$query}%")
                          ->orWhere('name_en', 'LIKE', "%{$query}%")
                          ->orWhere('name_ar', 'LIKE', "%{$query}%");
                    })
                    ->orWhere('specialty', 'LIKE', "%{$query}%")
                    ->orWhere('city', 'LIKE', "%{$query}%");
                })
                ->with('user:id,name,name_en,name_ar,profile_image')
                ->limit(15)
                ->get()
                ->map($mapNurse);

            $medications = Medication::with('user:id,name')
                ->where('name', 'LIKE', "%{$query}%")
                ->orWhere('description', 'LIKE', "%{$query}%")
                ->limit(10)
                ->get()
                ->map($mapMedication);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'doctors' => $doctors,
                'pharmacies' => $pharmacies,
                'medications' => $medications,
                'labs' => $labs,
                'nurses' => $nurses
            ]
        ]);
    }
}

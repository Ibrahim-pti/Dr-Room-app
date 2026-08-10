<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Doctor;
use App\Models\Pharmacy;
use App\Models\Medication;
use App\Models\Lab;

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
                'labs' => $labs
            ]
        ]);
    }
}

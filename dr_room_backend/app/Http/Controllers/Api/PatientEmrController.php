<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PatientEmrRecord;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PatientEmrController extends Controller
{
    /**
     * Get authenticated patient's own EMR
     */
    public function show()
    {
        $patient = Auth::user();
        $emr = PatientEmrRecord::firstOrCreate(
            ['patient_id' => $patient->id],
            [
                'blood_type' => null,
                'chronic_diseases' => [],
                'allergies' => [],
                'current_medications' => [],
                'past_surgeries' => [],
                'emergency_notes' => null,
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $emr,
        ]);
    }

    /**
     * Update patient's own EMR
     */
    public function update(Request $request)
    {
        $patient = Auth::user();
        $emr = PatientEmrRecord::firstOrCreate(['patient_id' => $patient->id]);

        $validated = $request->validate([
            'blood_type' => 'nullable|string|max:10',
            'chronic_diseases' => 'nullable|array',
            'allergies' => 'nullable|array',
            'current_medications' => 'nullable|array',
            'past_surgeries' => 'nullable|array',
            'emergency_notes' => 'nullable|string',
            'height_cm' => 'nullable|numeric|min:20|max:300',
            'weight_kg' => 'nullable|numeric|min:1|max:500',
        ]);

        $validated['last_updated_by'] = $patient->id;
        $emr->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'دۆسیەی پزیشکی بە سەرکەوتوویی نوێکرایەوە',
            'data' => $emr,
        ]);
    }

    /**
     * Provider (Nurse or Doctor) viewing a patient's EMR before visit
     */
    public function patientEmr($id)
    {
        $viewer = Auth::user();
        $isSelf = (int) $viewer->id === (int) $id;
        $isPrivileged = in_array($viewer->role, ['admin', 'staff', 'moderator', 'doctor', 'nurse', 'lab'], true);
        if (!$isSelf && !$isPrivileged) {
            return response()->json(['success' => false, 'message' => 'دەسەڵاتت نییە بۆ بینینی دۆسیەی ئەم نەخۆشە'], 403);
        }

        $patient = User::findOrFail($id);
        $emr = PatientEmrRecord::where('patient_id', $patient->id)->first();

        return response()->json([
            'success' => true,
            'data' => [
                'patient' => [
                    'id' => $patient->id,
                    'name' => $patient->name,
                    'phone' => $patient->phone,
                    'profile_image' => $patient->profile_image,
                ],
                'emr' => $emr,
            ]
        ]);
    }
}


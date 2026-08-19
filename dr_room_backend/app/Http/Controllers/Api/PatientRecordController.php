<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\NursePatientCare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PatientRecordController extends Controller
{
    /**
     * Get all lab results for the authenticated patient
     */
    public function labResults(Request $request = null)
    {
        $patient = Auth::user();
        $patientId = $patient ? $patient->id : null;
        
        $results = LabResult::with(['lab', 'test'])
            ->where('patient_id', $patientId)
            ->latest()
            ->get()
            ->map(function ($result) {
                return [
                    'id' => $result->id,
                    'lab_name' => $result->lab->name ?? 'General Lab',
                    'test_name' => $result->test->name ?? 'Lab Test',
                    'test_type' => $result->test->type ?? null,
                    'result_value' => $result->result_value,
                    'status' => $result->status,
                    'file_url' => $result->file_path ? url('storage/' . $result->file_path) : null,
                    'notes' => $result->notes,
                    'created_at' => $result->created_at ? $result->created_at->toDateTimeString() : now()->toDateTimeString(),
                    'created_at_human' => $result->created_at ? $result->created_at->diffForHumans() : 'Recently',
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $results
        ]);
    }

    /**
     * Get all nurse care records for the authenticated patient
     */
    public function nurseCares(Request $request = null)
    {
        $patient = Auth::user();
        $patientId = $patient ? $patient->id : null;

        $cares = NursePatientCare::with(['nurse.user'])
            ->where('patient_id', $patientId)
            ->latest()
            ->get()
            ->map(function ($care) {
                return [
                    'id' => $care->id,
                    'nurse_name' => $care->nurse->user->name ?? 'Staff Nurse',
                    'date' => $care->date ? (is_string($care->date) ? $care->date : $care->date->format('Y-m-d')) : null,
                    'symptoms' => $care->symptoms,
                    'vitals' => $care->vitals,
                    'medication_given' => $care->medication_given,
                    'notes' => $care->notes,
                    'created_at' => $care->created_at ? $care->created_at->toDateTimeString() : now()->toDateTimeString(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $cares
        ]);
    }
}

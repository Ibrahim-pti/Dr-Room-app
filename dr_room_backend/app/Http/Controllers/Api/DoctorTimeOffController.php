<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DoctorTimeOff;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorTimeOffController extends Controller
{
    /**
     * Get all time offs for the authenticated doctor.
     */
    public function index()
    {
        $doctor = Auth::user()->doctor;
        if (!$doctor) {
            return response()->json(['message' => 'Unauthorized. Not a doctor.'], 403);
        }

        $timeOffs = $doctor->timeOffs()->orderBy('start_datetime', 'desc')->get();

        return response()->json([
            'data' => $timeOffs
        ]);
    }

    /**
     * Store a new time off.
     */
    public function store(Request $request)
    {
        $doctor = Auth::user()->doctor;
        if (!$doctor) {
            return response()->json(['message' => 'Unauthorized. Not a doctor.'], 403);
        }

        $request->validate([
            'start_datetime' => 'required|date',
            'end_datetime' => 'required|date|after:start_datetime',
            'reason' => 'nullable|string|max:255',
        ]);

        $timeOff = $doctor->timeOffs()->create([
            'start_datetime' => $request->start_datetime,
            'end_datetime' => $request->end_datetime,
            'reason' => $request->reason,
        ]);

        // Bust the availability cache since slots changed
        \Illuminate\Support\Facades\Cache::forget("doctor:{$doctor->id}:availability");

        return response()->json([
            'message' => 'Time off added successfully.',
            'data' => $timeOff
        ], 201);
    }

    /**
     * Remove a time off.
     */
    public function destroy($id)
    {
        $doctor = Auth::user()->doctor;
        if (!$doctor) {
            return response()->json(['message' => 'Unauthorized. Not a doctor.'], 403);
        }

        $timeOff = $doctor->timeOffs()->findOrFail($id);
        $timeOff->delete();

        // Bust the availability cache since slots changed
        \Illuminate\Support\Facades\Cache::forget("doctor:{$doctor->id}:availability");

        return response()->json([
            'message' => 'Time off deleted successfully.'
        ]);
    }
}


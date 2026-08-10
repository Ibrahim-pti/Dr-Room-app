<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * API Controller for doctor-specific actions (used by the mobile app).
 * All routes here require auth:sanctum + is_doctor middleware.
 */
class DoctorController extends Controller
{
    /**
     * GET /api/doctor/appointments
     * Returns all appointments for the currently authenticated doctor.
     */
    public function appointments(Request $request)
    {
        $doctor = Auth::user()->doctor;

        if (!$doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $query = $doctor->appointments()->with('patient:id,name,email,profile_image');

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filter by date
        if ($request->has('date')) {
            $query->whereDate('appointment_date', $request->date);
        }

        // Filter: today only
        if ($request->boolean('today')) {
            $query->today();
        }

        $appointments = $query->orderBy('appointment_date', 'asc')->get();

        return response()->json([
            'data' => $appointments,
            'total' => $appointments->count(),
        ]);
    }

    /**
     * PATCH /api/doctor/appointments/{id}/status
     * Update the status of an appointment (confirm, cancel, complete).
     */
    public function updateAppointmentStatus(Request $request, $id)
    {
        $doctor = Auth::user()->doctor;

        $request->validate([
            'status' => 'required|in:pending,confirmed,cancelled,completed',
        ]);

        $appointment = Appointment::where('doctor_id', $doctor->id)->findOrFail($id);
        $appointment->update(['status' => $request->status]);

        return response()->json([
            'message' => 'Status updated successfully.',
            'appointment' => $appointment->load('patient:id,name,email'),
        ]);
    }

    /**
     * GET /api/doctor/patients
     * Returns unique patients who have booked with this doctor.
     */
    public function patients()
    {
        $doctor = Auth::user()->doctor;

        if (!$doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $patients = $doctor->appointments()
            ->with('patient:id,name,email,profile_image,phone_number')
            ->select('patient_id')
            ->distinct()
            ->get()
            ->pluck('patient')
            ->filter();

        return response()->json([
            'data' => $patients,
            'total' => $patients->count(),
        ]);
    }

    /**
     * GET /api/doctor/stats
     * Returns summary statistics for the doctor's dashboard.
     */
    public function stats()
    {
        $doctor = Auth::user()->doctor;

        if (!$doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        return response()->json([
            'today_appointments'   => $doctor->today_appointments_count,
            'total_appointments'   => $doctor->appointments()->count(),
            'total_patients'       => $doctor->total_patients,
            'pending_appointments' => $doctor->appointments()->where('status', 'pending')->count(),
            'rating'               => $doctor->rating ?? 0,
            'total_reviews'        => $doctor->total_reviews ?? 0,
        ]);
    }

    /**
     * GET /api/doctor/profile
     * Returns the doctor's profile information.
     */
    public function profile()
    {
        $user   = Auth::user();
        $doctor = $user->doctor;

        if (!$doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        return response()->json([
            'id'               => $doctor->id,
            'name'             => $user->name,
            'email'            => $user->email,
            'specialty'        => $doctor->specialty,
            'bio'              => $doctor->bio,
            'rating'           => $doctor->rating,
            'total_reviews'    => $doctor->total_reviews,
            'consultation_fee' => $doctor->consultation_fee,
            'experience_years' => $doctor->experience_years,
            'phone'            => $doctor->phone,
            'available_days'   => $doctor->available_days,
            'image_url'        => $doctor->image_path
                ? asset('storage/' . $doctor->image_path)
                : null,
        ]);
    }

    /**
     * PUT /api/doctor/profile
     * Update the doctor's profile.
     */
    public function updateProfile(Request $request)
    {
        $user   = Auth::user();
        $doctor = $user->doctor;

        $request->validate([
            'specialty'        => 'sometimes|string|max:100',
            'bio'              => 'sometimes|string',
            'consultation_fee' => 'sometimes|numeric|min:0',
            'experience_years' => 'sometimes|integer|min:0',
            'phone'            => 'sometimes|string|max:20',
            'available_days'   => 'sometimes|array',
        ]);

        $doctor->update($request->only([
            'specialty', 'bio', 'consultation_fee', 'experience_years', 'phone', 'available_days',
        ]));

        return response()->json([
            'message' => 'Profile updated successfully.',
            'doctor'  => $doctor->fresh(),
        ]);
    }
}

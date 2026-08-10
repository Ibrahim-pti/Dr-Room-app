<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Services\AppointmentSlotService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Appointment booking API for patients (mobile app users).
 */
class AppointmentBookingController extends Controller
{
    /**
     * POST /api/appointments
     * Book an appointment with a doctor.
     */
    public function store(Request $request, AppointmentSlotService $slots)
    {
        $request->validate([
            'doctor_id'        => 'required|exists:doctors,id',
            'service_id'       => 'nullable|exists:doctor_services,id',
            'appointment_date' => 'required|date|after:now',
            'type'             => 'sometimes|in:in_person,online',
            'notes'            => 'nullable|string|max:500',
        ]);

        $doctor = Doctor::findOrFail($request->doctor_id);
        $when = Carbon::parse($request->appointment_date)->seconds(0);

        // The client generates nothing on its own — the requested time has to
        // be a slot this doctor actually offers, and still be free.
        if (! $slots->isBookable($doctor, $when)) {
            return response()->json([
                'message' => 'This time is no longer available.',
                'code'    => 'slot_unavailable',
            ], 409);
        }

        $fee = $doctor->consultation_fee;
        if ($request->filled('service_id')) {
            $service = \App\Models\DoctorService::where('id', $request->service_id)->where('doctor_id', $doctor->id)->first();
            if ($service) {
                $fee = $service->price;
            }
        }

        $appointment = Appointment::create([
            'doctor_id'        => $request->doctor_id,
            'service_id'       => $request->service_id,
            'patient_id'       => Auth::id(),
            'appointment_date' => $when,
            'type'             => $request->type ?? 'in_person',
            'notes'            => $request->notes,
            'fee'              => $fee,
            'status'           => 'pending',
        ]);

        // Bust the availability cache so the just-taken slot disappears
        // immediately for the next viewer.
        \Illuminate\Support\Facades\Cache::forget("doctor:{$request->doctor_id}:availability");

        return response()->json([
            'message'     => 'Appointment booked successfully.',
            'appointment' => $appointment->load('doctor.user:id,name', 'patient:id,name'),
        ], 201);
    }

    /**
     * GET /api/doctors/{id}/availability
     *
     * The bookable days and times, already stripped of past and taken slots.
     * The app renders this verbatim rather than deriving its own grid.
     */
    public function availability($id, AppointmentSlotService $slots)
    {
        $doctor = Doctor::with('schedules')->findOrFail($id);

        // Cache the expensive slot computation for 60 seconds per doctor.
        // Short enough that a new booking shows up within a minute, long
        // enough that bursts of requests (e.g. pull-to-refresh) are free.
        $data = \Illuminate\Support\Facades\Cache::remember(
            "doctor:{$id}:availability",
            60,
            fn () => [
                'horizon_days' => AppointmentSlotService::HORIZON_DAYS,
                'days' => $slots->availability($doctor),
            ],
        );

        return response()->json($data);
    }

    /**
     * GET /api/appointments
     * Get the authenticated patient's appointments.
     */
    public function index(Request $request)
    {
        $query = Appointment::where('patient_id', Auth::id())
            ->with('doctor.user:id,name', 'doctor:id,user_id,specialty,image_path,rating');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $appointments = $query->orderBy('appointment_date', 'desc')->get();

        return response()->json([
            'data'  => $appointments,
            'total' => $appointments->count(),
        ]);
    }

    /**
     * DELETE /api/appointments/{id}
     * Cancel an appointment (patient cancels their own).
     */
    public function destroy($id)
    {
        $appointment = Appointment::where('patient_id', Auth::id())->findOrFail($id);

        if ($appointment->status === 'completed') {
            return response()->json(['message' => 'Cannot cancel a completed appointment.'], 422);
        }

        $appointment->update(['status' => 'cancelled']);

        // Freed slot should appear immediately in the availability grid.
        \Illuminate\Support\Facades\Cache::forget("doctor:{$appointment->doctor_id}:availability");

        return response()->json(['message' => 'Appointment cancelled successfully.']);
    }
}

<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Appointment;

class DoctorAppointmentController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;
        $appointments = $doctor->appointments()->with('patient')->orderBy('appointment_date', 'desc')->paginate(15);
        return view('doctor.appointments.index', compact('appointments'));
    }

    public function updateStatus(Request $request, Appointment $appointment)
    {
        // Ensure the appointment belongs to the logged in doctor
        if ($appointment->doctor_id !== Auth::user()->doctor->id) {
            abort(403);
        }

        $request->validate([
            'status' => 'required|in:pending,confirmed,completed,cancelled'
        ]);

        $appointment->status = $request->status;
        $appointment->save();

        return back()->with('success', 'دۆخی چاوپێکەوتنەکە نوێکرایەوە.');
    }
}

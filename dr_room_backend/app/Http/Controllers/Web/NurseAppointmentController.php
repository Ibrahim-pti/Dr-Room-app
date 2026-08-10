<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\NurseAppointment;

class NurseAppointmentController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;
        $appointments = $nurse->nurseAppointments()->with('patient')->orderBy('appointment_date', 'desc')->paginate(15);
        return view('nurse.appointments.index', compact('appointments'));
    }

    public function updateStatus(Request $request, NurseAppointment $appointment)
    {
        // Ensure the appointment belongs to the logged in nurse
        if ($appointment->nurse_id !== Auth::user()->nurse->id) {
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

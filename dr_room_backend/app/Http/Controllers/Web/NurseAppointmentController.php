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
        
        // Appointments assigned to this nurse
        $appointments = $nurse->nurseAppointments()
            ->with('patient')
            ->orderBy('appointment_date', 'desc')
            ->paginate(15);
            
        // Pending requests without a nurse
        $unassignedRequests = NurseAppointment::whereNull('nurse_id')
            ->where('status', 'pending')
            ->with('patient')
            ->orderBy('created_at', 'desc')
            ->get();

        return view('nurse.appointments.index', compact('appointments', 'unassignedRequests'));
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

    public function acceptRequest(NurseAppointment $appointment)
    {
        // Only allow accepting if it's currently unassigned
        if ($appointment->nurse_id !== null) {
            return back()->with('error', 'ئەم داواکارییە پێشتر لەلایەن پەرستارێکی ترەوە وەرگیراوە.');
        }

        $appointment->nurse_id = Auth::user()->nurse->id;
        $appointment->status = 'confirmed'; // Auto confirm when accepted
        $appointment->save();

        return back()->with('success', 'داواکارییەکە بە سەرکەوتوویی وەرگیرا.');
    }
}

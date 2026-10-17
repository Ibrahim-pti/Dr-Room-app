<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class NursePatientController extends Controller
{
    public function index()
    {
        $userId = Auth::id();
        $nurse = Auth::user()->nurse;

        // Get patients who have orders or appointments with this nurse
        $patientIds = \App\Models\Order::where('assigned_nurse_id', $userId)
            ->whereIn('service_type', ['Nursing Services', 'nursing'])
            ->pluck('patient_id')
            ->filter();

        if ($nurse) {
            $appointmentPatientIds = \App\Models\NurseAppointment::where('nurse_id', $nurse->id)
                ->pluck('patient_id')
                ->filter();
            $patientIds = $patientIds->concat($appointmentPatientIds)->unique();
        }

        $patients = User::whereIn('id', $patientIds)
            ->withCount(['orders as total_visits' => function($q) use ($userId) {
                $q->where('assigned_nurse_id', $userId)
                  ->whereIn('service_type', ['Nursing Services', 'nursing']);
            }])
            ->with(['orders' => function($q) use ($userId) {
                $q->where('assigned_nurse_id', $userId)
                  ->whereIn('service_type', ['Nursing Services', 'nursing'])
                  ->orderBy('created_at', 'desc')
                  ->take(1);
            }])
            ->paginate(15);

        return view('nurse.patients.index', compact('patients'));
    }
}

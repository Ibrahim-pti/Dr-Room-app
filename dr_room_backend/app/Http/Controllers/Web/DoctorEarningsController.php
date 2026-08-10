<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorEarningsController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;
        
        // Sum of all completed appointments fees
        $totalEarnings = $doctor->appointments()->where('status', 'completed')->sum('fee');
        
        // Sum for this month
        $monthlyEarnings = $doctor->appointments()
            ->where('status', 'completed')
            ->whereMonth('appointment_date', now()->month)
            ->whereYear('appointment_date', now()->year)
            ->sum('fee');

        $completedAppointments = $doctor->appointments()
            ->where('status', 'completed')
            ->with('patient')
            ->orderBy('appointment_date', 'desc')
            ->paginate(15);

        return view('doctor.earnings.index', compact('totalEarnings', 'monthlyEarnings', 'completedAppointments'));
    }
}

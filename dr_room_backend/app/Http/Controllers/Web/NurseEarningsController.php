<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseEarningsController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;
        
        // Sum of all completed appointments fees
        $totalEarnings = $nurse->nurseAppointments()->where('status', 'completed')->sum('fee');
        
        // Sum for this month
        $monthlyEarnings = $nurse->nurseAppointments()
            ->where('status', 'completed')
            ->whereMonth('appointment_date', now()->month)
            ->whereYear('appointment_date', now()->year)
            ->sum('fee');

        $completedAppointments = $nurse->nurseAppointments()
            ->where('status', 'completed')
            ->with('patient')
            ->orderBy('appointment_date', 'desc')
            ->paginate(15);

        return view('nurse.earnings.index', compact('totalEarnings', 'monthlyEarnings', 'completedAppointments'));
    }
}

<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseDashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        if (!$nurse) {
            return redirect()->route('nurse.login')->withErrors(['error' => 'No nurse profile found.']);
        }

        // Fetch appointments specific to this nurse
        $todayAppointments = $nurse->nurseAppointments()->today()->count();
        
        // Total unique patients
        $totalPatients = $nurse->nurseAppointments()->distinct('patient_id')->count('patient_id');
        
        // Upcoming appointments
        $upcomingAppointments = $nurse->nurseAppointments()
            ->upcoming()
            ->with('patient')
            ->orderBy('appointment_date', 'asc')
            ->take(5)
            ->get();

        // Appointments per day for the last 7 days, oldest first, for the chart.
        $weeklyChart = collect(range(6, 0))->map(function (int $daysAgo) use ($nurse) {
            $day = today()->subDays($daysAgo);

            return [
                'label' => $day->translatedFormat('D'),
                'count' => $nurse->nurseAppointments()
                    ->whereDate('appointment_date', $day)
                    ->count(),
            ];
        });

        return view('nurse.dashboard.index', compact(
            'user',
            'nurse',
            'todayAppointments',
            'totalPatients',
            'upcomingAppointments',
            'weeklyChart'
        ));
    }
}

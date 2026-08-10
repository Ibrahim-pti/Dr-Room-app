<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorDashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $doctor = $user->doctor;

        if (!$doctor) {
            // If they somehow got here without a doctor record, redirect or handle it
            return redirect()->route('doctor.login')->withErrors(['error' => 'No doctor profile found.']);
        }

        // Fetch appointments specific to this doctor
        $todayAppointments = $doctor->appointments()->today()->count();
        $totalPatients = $doctor->total_patients;
        
        // Upcoming appointments
        $upcomingAppointments = $doctor->appointments()
            ->upcoming()
            ->with('patient')
            ->orderBy('appointment_date', 'asc')
            ->take(5)
            ->get();

        // Appointments per day for the last 7 days, oldest first, for the chart.
        $weeklyChart = collect(range(6, 0))->map(function (int $daysAgo) use ($doctor) {
            $day = today()->subDays($daysAgo);

            return [
                'label' => $day->translatedFormat('D'),
                'count' => $doctor->appointments()
                    ->whereDate('appointment_date', $day)
                    ->count(),
            ];
        });

        // Most recently seen patients, newest first, one row per patient.
        $recentPatients = $doctor->appointments()
            ->with('patient')
            ->whereNotNull('patient_id')
            ->latest('appointment_date')
            ->take(20)
            ->get()
            ->unique('patient_id')
            ->take(3)
            ->values();

        return view('doctor.dashboard.index', compact(
            'user',
            'doctor',
            'todayAppointments',
            'totalPatients',
            'upcomingAppointments',
            'recentPatients',
            'weeklyChart'
        ));
    }
}

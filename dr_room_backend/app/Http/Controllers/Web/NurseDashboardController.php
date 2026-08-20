<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Order;

class NurseDashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        if (!$nurse) {
            return redirect()->route('nurse.login')->withErrors(['error' => 'No nurse profile found.']);
        }

        $userId = Auth::id();

        // Fetch appointments specific to this nurse
        $todayAppointments = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->whereDate('created_at', today())
            ->count();
        
        // Total unique patients
        $totalPatients = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->distinct('patient_id')
            ->count('patient_id');
        
        // Upcoming appointments
        $upcomingAppointments = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->where('status', 'processing')
            ->with('patient')
            ->orderBy('created_at', 'asc')
            ->take(5)
            ->get();

        // Unassigned requests that any nurse can claim
        $unassignedRequests = Order::whereNull('assigned_nurse_id')
            ->where('service_type', 'Nursing Services')
            ->where('status', 'pending')
            ->with(['patient', 'items'])
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        // Appointments per day for the last 7 days, oldest first, for the chart.
        $weeklyChart = collect(range(6, 0))->map(function (int $daysAgo) use ($userId) {
            $day = today()->subDays($daysAgo);

            return [
                'label' => $day->translatedFormat('D'),
                'count' => Order::where('assigned_nurse_id', $userId)
                    ->where('service_type', 'Nursing Services')
                    ->whereDate('created_at', $day)
                    ->count(),
            ];
        });

        // Completed vs Pending for dashboard cards
        $completedAppointments = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->where('status', 'completed')
            ->count();

        $pendingAppointments = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->where('status', 'processing')
            ->count();

        return view('nurse.dashboard.index', compact(
            'user',
            'nurse',
            'todayAppointments',
            'totalPatients',
            'upcomingAppointments',
            'unassignedRequests',
            'weeklyChart',
            'completedAppointments',
            'pendingAppointments'
        ));
    }
}

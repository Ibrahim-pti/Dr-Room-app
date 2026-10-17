<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Order;

class NurseEarningsController extends Controller
{
    public function index()
    {
        $userId = Auth::id();
        $nurse = Auth::user()->nurse;

        // Sum of all completed appointments and orders
        $appointmentEarnings = $nurse ? $nurse->nurseAppointments()->where('status', 'completed')->sum('fee') : 0;
        $orderEarnings = Order::where('assigned_nurse_id', $userId)
            ->whereIn('service_type', ['Nursing Services', 'nursing'])
            ->where('status', 'completed')
            ->sum('total_price');
        $totalEarnings = $appointmentEarnings + $orderEarnings;

        // Sum for this month
        $monthlyAppEarnings = $nurse ? $nurse->nurseAppointments()
            ->where('status', 'completed')
            ->whereMonth('appointment_date', now()->month)
            ->whereYear('appointment_date', now()->year)
            ->sum('fee') : 0;
        $monthlyOrderEarnings = Order::where('assigned_nurse_id', $userId)
            ->whereIn('service_type', ['Nursing Services', 'nursing'])
            ->where('status', 'completed')
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('total_price');
        $monthlyEarnings = $monthlyAppEarnings + $monthlyOrderEarnings;

        // Completed list from orders
        $completedAppointments = Order::where('assigned_nurse_id', $userId)
            ->whereIn('service_type', ['Nursing Services', 'nursing'])
            ->where('status', 'completed')
            ->with('patient')
            ->select('id', 'patient_id', 'total_price as fee', 'created_at as appointment_date')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return view('nurse.earnings.index', compact('totalEarnings', 'monthlyEarnings', 'completedAppointments'));
    }
}

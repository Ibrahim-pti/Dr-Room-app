<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Doctor;
use App\Models\Appointment;
use App\Models\Order;

class DashboardController extends Controller
{
    public function index()
    {
        $totalUsers = User::whereNotIn('role', ['admin', 'doctor', 'nurse', 'lab', 'pharmacy'])->count(); // patients
        $totalDoctors = Doctor::count();
        $pendingDoctors = User::where('role', 'doctor')->where('status', 'pending')->count();
        
        $totalNurses = User::where('role', 'nurse')->where('status', 'approved')->count();
        $pendingNurses = User::where('role', 'nurse')->where('status', 'pending')->count();
        
        $totalLabs = User::where('role', 'lab')->where('status', 'approved')->count();
        $pendingLabs = User::where('role', 'lab')->where('status', 'pending')->count();
        
        $totalPharmacies = User::where('role', 'pharmacy')->where('status', 'approved')->count();
        $pendingPharmacies = User::where('role', 'pharmacy')->where('status', 'pending')->count();
        
        $totalOrders = Order::count();
        $pendingOrders = Order::where('status', 'pending')->count();
        $totalAppointments = Appointment::count();
        
        $recentAppointments = Appointment::with(['patient', 'doctor.user'])
            ->orderBy('id', 'desc')
            ->take(5)
            ->get();

        $recentOrders = Order::with(['items', 'patient', 'assignedNurse'])
            ->orderBy('id', 'desc')
            ->take(5)
            ->get();

        return response()->json([
            'total_users' => $totalUsers,
            'total_doctors' => $totalDoctors,
            'pending_doctors' => $pendingDoctors,
            'total_nurses' => $totalNurses,
            'pending_nurses' => $pendingNurses,
            'total_labs' => $totalLabs,
            'pending_labs' => $pendingLabs,
            'total_pharmacies' => $totalPharmacies,
            'pending_pharmacies' => $pendingPharmacies,
            'total_orders' => $totalOrders,
            'pending_orders' => $pendingOrders,
            'total_appointments' => $totalAppointments,
            'recent_appointments' => $recentAppointments,
            'recent_orders' => $recentOrders,
        ]);
    }
}

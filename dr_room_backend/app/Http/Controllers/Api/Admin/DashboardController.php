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
        $totalUsers = User::where(function ($q) {
            $q->whereNull('role')->orWhereNotIn('role', ['admin', 'staff', 'moderator', 'doctor', 'nurse', 'lab', 'pharmacy', 'xray', 'driver']);
        })->count(); // patients
        $totalDoctors = Doctor::count();
        $pendingDoctors = User::where('role', 'doctor')->where('status', 'pending')->count();
        
        $totalNurses = User::where('role', 'nurse')->where('status', 'approved')->count();
        $pendingNurses = User::where('role', 'nurse')->where('status', 'pending')->count();
        
        $totalLabs = User::where('role', 'lab')->where('status', 'approved')->count();
        $pendingLabs = User::where('role', 'lab')->where('status', 'pending')->count();
        
        $totalPharmacies = User::where('role', 'pharmacy')->where('status', 'approved')->count();
        $pendingPharmacies = User::where('role', 'pharmacy')->where('status', 'pending')->count();

        $totalDrivers = User::where('role', 'driver')->where('status', 'approved')->count();
        $pendingDrivers = User::where('role', 'driver')->where('status', 'pending')->count();
        $onlineDrivers = 0;
        $busyDrivers = 0;
        try {
            $onlineDrivers = \App\Models\Driver::whereHas('user', fn ($q) => $q->where('role', 'driver')->where('status', 'approved'))
                ->whereIn('duty_status', ['available', 'busy'])
                ->count();
            $busyDrivers = \App\Models\Driver::whereHas('user', fn ($q) => $q->where('role', 'driver')->where('status', 'approved'))
                ->where('duty_status', 'busy')
                ->count();
        } catch (\Throwable $e) {}
        
        $totalOrders = Order::count();
        $pendingOrders = Order::where('status', 'pending')->count();
        $totalAppointments = Appointment::count();

        $openTickets = 0;
        $unreadTicketMessages = 0;
        try {
            $openTickets = \App\Models\SupportTicket::where('status', 'open')->count();
            $unreadTicketMessages = \App\Models\TicketMessage::where('is_admin_reply', false)->where('is_read', false)->count();
        } catch (\Throwable $e) {}
        
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
            'total_drivers' => $totalDrivers,
            'pending_drivers' => $pendingDrivers,
            'online_drivers' => $onlineDrivers,
            'busy_drivers' => $busyDrivers,
            'total_orders' => $totalOrders,
            'pending_orders' => $pendingOrders,
            'open_tickets' => $openTickets,
            'unread_ticket_messages' => $unreadTicketMessages,
            'total_appointments' => $totalAppointments,
            'recent_appointments' => $recentAppointments,
            'recent_orders' => $recentOrders,
        ]);
    }
}

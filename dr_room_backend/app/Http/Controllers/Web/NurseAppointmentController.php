<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Order;

class NurseAppointmentController extends Controller
{
    public function index()
    {
        $userId = Auth::id(); // Order table uses user_id for assignment
        
        // Appointments assigned to this nurse
        $appointments = Order::where('assigned_nurse_id', $userId)
            ->where('service_type', 'Nursing Services')
            ->with('patient')
            ->orderBy('created_at', 'desc')
            ->paginate(15);
            
        // Pending requests without a nurse
        $unassignedRequests = Order::whereNull('assigned_nurse_id')
            ->where('service_type', 'Nursing Services')
            ->where('status', 'pending')
            ->with('patient')
            ->orderBy('created_at', 'desc')
            ->get();

        return view('nurse.appointments.index', compact('appointments', 'unassignedRequests'));
    }

    public function updateStatus(Request $request, Order $appointment)
    {
        // Ensure the appointment belongs to the logged in nurse
        if ($appointment->assigned_nurse_id !== Auth::id()) {
            abort(403);
        }

        $request->validate([
            'status' => 'required|in:pending,processing,completed,cancelled'
        ]);

        $appointment->status = $request->status;
        $appointment->save();

        return back()->with('success', 'دۆخی چاوپێکەوتنەکە نوێکرایەوە.');
    }

    public function acceptRequest(Order $appointment)
    {
        // Only allow accepting if it's currently unassigned
        if ($appointment->assigned_nurse_id !== null) {
            return back()->with('error', 'ئەم داواکارییە پێشتر لەلایەن پەرستارێکی ترەوە وەرگیراوە.');
        }

        $appointment->assigned_nurse_id = Auth::id();
        $appointment->status = 'processing'; // Auto processing when accepted
        $appointment->save();

        return back()->with('success', 'داواکارییەکە بە سەرکەوتوویی وەرگیرا.');
    }
    
    public function confirm()
    {
        return view('shared.placeholder', ['layout' => 'nurse.layouts.app', 'title' => 'دڵنیابوونەوە لە کات']);
    }
}

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
            ->forNursing()
            ->with('patient')
            ->orderBy('created_at', 'desc')
            ->paginate(15);
            
        // Pending requests without a nurse
        $unassignedRequests = Order::whereNull('assigned_nurse_id')
            ->forNursing()
            ->where('status', 'pending')
            ->with('patient')
            ->orderBy('created_at', 'desc')
            ->get();

        return view('nurse.appointments.index', compact('appointments', 'unassignedRequests'));
    }

    public function updateStatus(Request $request, Order $appointment)
    {
        // Ensure the appointment belongs to the logged in nurse
        if ((int) $appointment->assigned_nurse_id !== (int) Auth::id()) {
            abort(403);
        }

        $request->validate([
            'status' => 'required|in:pending,confirmed,approved,processing,in_progress,completed,cancelled'
        ]);

        if ($request->status === 'completed') {
            $appointment->markCompletedWithFinancials();
        } else {
            $appointment->status = $request->status;
            $appointment->save();
        }

        \App\Services\OrderNotificationService::notifyStatusChanged($appointment, $request->status);

        return back()->with('success', 'دۆخی چاوپێکەوتنەکە نوێکرایەوە.');
    }

    public function acceptRequest(Order $appointment)
    {
        if (!$appointment->isNursingService()) {
            abort(403);
        }

        $updated = Order::where('id', $appointment->id)
            ->whereNull('assigned_nurse_id')
            ->update([
                'assigned_nurse_id' => Auth::id(),
                'status' => 'processing',
            ]);

        if ($updated === 0) {
            return back()->with('error', 'ئەم داواکارییە پێشتر لەلایەن پەرستارێکی ترەوە وەرگیراوە.');
        }

        $appointment->refresh();
        \App\Services\OrderNotificationService::notifyStatusChanged($appointment, 'processing');

        return back()->with('success', 'داواکارییەکە بە سەرکەوتوویی وەرگیرا.');
    }
    
    public function confirm()
    {
        return view('shared.placeholder', ['layout' => 'nurse.layouts.app', 'title' => 'دڵنیابوونەوە لە کات']);
    }
}

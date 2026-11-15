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
            ->with(['patient', 'items'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);
            
        // Pending requests without a nurse
        $unassignedRequests = Order::whereNull('assigned_nurse_id')
            ->forNursing()
            ->where('status', 'pending')
            ->with(['patient', 'items'])
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
            'status' => 'required|in:pending,confirmed,approved,processing,in_progress,completed,cancelled',
            'estimated_duration_minutes' => 'nullable|integer|min:1|max:43200',
        ]);

        $previousStatus = $appointment->status;
        $previousEstimated = $appointment->estimated_duration_minutes;
        $isTerminal = in_array($request->status, ['completed', 'cancelled'], true);

        if ($request->has('estimated_duration_minutes')) {
            if ($request->filled('estimated_duration_minutes')) {
                $mins = (int) $request->input('estimated_duration_minutes');
                $appointment->estimated_duration_minutes = $mins;
                $appointment->estimated_ready_at = $isTerminal ? null : now()->addMinutes($mins);
            } else {
                $appointment->estimated_duration_minutes = null;
                $appointment->estimated_ready_at = null;
            }
        } elseif ($isTerminal) {
            $appointment->estimated_ready_at = null;
        }

        if ($request->status === 'completed') {
            $appointment->markCompletedWithFinancials();
        } else {
            $appointment->status = $request->status;
            $appointment->save();
        }

        $statusChanged = $previousStatus !== $request->status;
        $estimatedChanged = $previousEstimated !== $appointment->estimated_duration_minutes
            && $appointment->estimated_duration_minutes !== null;

        if ($statusChanged || $estimatedChanged) {
            \App\Services\OrderNotificationService::notifyStatusChanged($appointment, $request->status);
        }

        return back()->with('success', 'بارودۆخ و کاتی داواکارییەکە بە سەرکەوتوویی نوێکرایەوە.');
    }

    public function acceptRequest(Request $request, Order $appointment)
    {
        if (!$appointment->isNursingService()) {
            abort(403);
        }

        $request->validate([
            'estimated_duration_minutes' => 'nullable|integer|min:1|max:43200',
        ]);

        $updateData = [
            'assigned_nurse_id' => Auth::id(),
            'status' => 'processing',
        ];
        if ($request->filled('estimated_duration_minutes')) {
            $mins = (int) $request->input('estimated_duration_minutes');
            $updateData['estimated_duration_minutes'] = $mins;
            $updateData['estimated_ready_at'] = now()->addMinutes($mins);
        }

        $updated = Order::where('id', $appointment->id)
            ->whereNull('assigned_nurse_id')
            ->update($updateData);

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

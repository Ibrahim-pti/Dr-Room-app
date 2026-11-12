<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Order;

class LabPatientController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $status = $request->get('status');

        $baseQuery = Order::with(['items', 'patient'])
            ->where(function ($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)
                  ->orWhere(function ($unassigned) {
                      $unassigned->whereNull('assigned_lab_id')->forLab();
                  });
            });

        $counts = [
            'all' => (clone $baseQuery)->count(),
            'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
            'approved' => (clone $baseQuery)->whereIn('status', ['approved', 'confirmed', 'processing', 'in_progress'])->count(),
            'completed' => (clone $baseQuery)->where('status', 'completed')->count(),
        ];

        $query = clone $baseQuery;
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $orders = $query->latest()->paginate(10)->withQueryString();

        return view('lab.patients.index', compact('orders', 'status', 'counts'));
    }

    public function updateStatus(Request $request, Order $order)
    {
        $userId = (int) Auth::id();
        if (($order->assigned_lab_id !== null && (int) $order->assigned_lab_id !== $userId)
            || ($order->assigned_lab_id === null && !$order->isLabService())) {
            abort(403);
        }

        $request->validate([
            'status' => 'required|in:pending,confirmed,approved,processing,in_progress,completed,cancelled',
        ]);

        if ($order->assigned_lab_id === null) {
            $order->assigned_lab_id = $userId;
        }

        if ($request->status === 'completed') {
            $order->markCompletedWithFinancials();
        } else {
            $order->status = $request->status;
            $order->save();
        }

        if ($order->assigned_driver_id && in_array($request->status, ['completed', 'cancelled'], true)) {
            \App\Models\Driver::syncDutyStatusForUser((int) $order->assigned_driver_id);
        }

        \App\Services\OrderNotificationService::notifyStatusChanged($order, $request->status);

        return back()->with('success', 'بارودۆخی داواکارییەکە بە سەرکەوتوویی نوێکرایەوە.');
    }
}

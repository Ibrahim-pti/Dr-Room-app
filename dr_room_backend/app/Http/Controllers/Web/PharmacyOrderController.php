<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;

class PharmacyOrderController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status');
        
        $baseQuery = Order::with('items')->forPharmacy()
            ->where(function($query) {
                $query->where('assigned_pharmacy_id', Auth::id())
                      ->orWhere(function ($unassigned) {
                          $unassigned->whereNull('assigned_pharmacy_id')
                                     ->where('status', 'pending');
                      });
            });

        $counts = [
            'all' => (clone $baseQuery)->count(),
            'pending' => (clone $baseQuery)->where('status', 'pending')->count(),
            'accepted' => (clone $baseQuery)->where('status', 'accepted')->count(),
            'completed' => (clone $baseQuery)->where('status', 'completed')->count(),
            'cancelled' => (clone $baseQuery)->where('status', 'cancelled')->count(),
        ];

        if ($status && $status !== 'all') {
            $baseQuery->where('status', $status);
        }

        $orders = $baseQuery->latest()->paginate(15);
            
        return view('pharmacy.orders.index', compact('orders', 'status', 'counts'));
    }

    public function show($id)
    {
        $order = Order::with('items')->findOrFail($id);
        
        // Ensure this order is either unassigned pending or belongs to this pharmacy
        if (!$order->isPharmacyService() || 
           ((int) $order->assigned_pharmacy_id !== (int) Auth::id() && !($order->status === 'pending' && $order->assigned_pharmacy_id === null))) {
            abort(403);
        }

        return view('pharmacy.orders.show', compact('order'));
    }

    public function updateStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        
        if (!$order->isPharmacyService()) abort(403);
        
        $request->validate([
            'status' => 'required|in:accepted,completed,cancelled'
        ]);

        if ($request->status === 'accepted') {
            $updated = Order::where('id', $order->id)
                ->where('status', 'pending')
                ->where(function ($q) {
                    $q->whereNull('assigned_pharmacy_id')
                      ->orWhere('assigned_pharmacy_id', Auth::id());
                })
                ->update([
                    'status' => 'accepted',
                    'assigned_pharmacy_id' => Auth::id(),
                ]);

            if ($updated === 0) {
                return back()->withErrors(['error' => 'ئەم داواکارییە پێشتر وەرگیراوە.']);
            }
            $order->refresh();

            if (!$order->assigned_driver_id && $order->needsDeliveryDriver()) {
                try {
                    app(\App\Services\DriverDispatchService::class)->dispatchNearest($order);
                } catch (\Throwable $e) {}
            }

            \App\Services\OrderNotificationService::notifyStatusChanged($order, 'accepted');

            return back()->with('success', 'داواکارییەکە بە سەرکەوتوویی وەرگیرا.');
        }

        // For other status updates, ensure the pharmacy owns the order
        if ((int) $order->assigned_pharmacy_id !== (int) Auth::id()) {
            abort(403);
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

        return back()->with('success', 'باری داواکارییەکە گۆڕدرا بۆ ' . $request->status);
    }
}

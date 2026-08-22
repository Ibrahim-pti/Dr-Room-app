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
        
        $baseQuery = Order::with('items')->where('service_type', 'pharmacy')
            ->where(function($query) {
                $query->where('status', 'pending')
                      ->orWhere('assigned_pharmacy_id', Auth::id());
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
        
        // Ensure this order is either pending or belongs to this pharmacy
        if ($order->service_type !== 'pharmacy' || 
           ($order->status !== 'pending' && $order->assigned_pharmacy_id !== Auth::id())) {
            abort(403);
        }

        return view('pharmacy.orders.show', compact('order'));
    }

    public function updateStatus(Request $request, $id)
    {
        $order = Order::findOrFail($id);
        
        if ($order->service_type !== 'pharmacy') abort(403);
        
        $request->validate([
            'status' => 'required|in:accepted,completed,cancelled'
        ]);

        if ($request->status === 'accepted') {
            if ($order->status !== 'pending') {
                return back()->withErrors(['error' => 'ئەم داواکارییە پێشتر وەرگیراوە.']);
            }
            $order->status = 'accepted';
            $order->assigned_pharmacy_id = Auth::id();
            $order->save();
            return back()->with('success', 'داواکارییەکە بە سەرکەوتوویی وەرگیرا.');
        }

        // For other status updates, ensure the pharmacy owns the order
        if ($order->assigned_pharmacy_id !== Auth::id()) {
            abort(403);
        }

        $order->status = $request->status;
        $order->save();

        return back()->with('success', 'باری داواکارییەکە گۆڕدرا بۆ ' . $request->status);
    }
}

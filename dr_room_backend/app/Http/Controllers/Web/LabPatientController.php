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

        $query = Order::with(['items', 'patient'])
            ->where(function($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)
                  ->orWhere('service_type', 'lab')
                  ->orWhere('service_type', 'Lab');
            });

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $orders = $query->latest()->paginate(10)->withQueryString();

        $counts = [
            'all' => Order::where(function($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)->orWhere('service_type', 'lab');
            })->count(),
            'pending' => Order::where(function($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)->orWhere('service_type', 'lab');
            })->where('status', 'pending')->count(),
            'approved' => Order::where(function($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)->orWhere('service_type', 'lab');
            })->whereIn('status', ['approved', 'confirmed', 'in_progress'])->count(),
            'completed' => Order::where(function($q) use ($user) {
                $q->where('assigned_lab_id', $user->id)->orWhere('service_type', 'lab');
            })->where('status', 'completed')->count(),
        ];

        return view('lab.patients.index', compact('orders', 'status', 'counts'));
    }

    public function updateStatus(Request $request, Order $order)
    {
        $request->validate([
            'status' => 'required|in:pending,confirmed,approved,in_progress,completed,cancelled',
        ]);

        $order->update([
            'status' => $request->status,
        ]);

        return back()->with('success', 'بارودۆخی داواکارییەکە بە سەرکەوتوویی نوێکرایەوە.');
    }
}

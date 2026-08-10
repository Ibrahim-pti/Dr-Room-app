<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;

class PharmacyCustomerController extends Controller
{
    public function index()
    {
        // Get all unique customers who had completed orders with this pharmacy
        $orders = Order::where('assigned_pharmacy_id', Auth::id())
            ->where('status', 'completed')
            ->get();
            
        // Extract unique customers based on patient_id
        $customers = $orders->unique('patient_id')->map(function($order) {
            $details = json_decode($order->patient_details, true);
            return [
                'id' => $order->patient_id,
                'name' => $details['name'] ?? 'نەزانراو',
                'phone' => $details['phone'] ?? 'نەزانراو',
                'total_orders' => Order::where('patient_id', $order->patient_id)
                                    ->where('assigned_pharmacy_id', Auth::id())
                                    ->where('status', 'completed')
                                    ->count(),
                'total_spent' => Order::where('patient_id', $order->patient_id)
                                    ->where('assigned_pharmacy_id', Auth::id())
                                    ->where('status', 'completed')
                                    ->sum('total_price'),
                'last_order' => Order::where('patient_id', $order->patient_id)
                                    ->where('assigned_pharmacy_id', Auth::id())
                                    ->latest()->first()->created_at
            ];
        })->sortByDesc('last_order');
        
        return view('pharmacy.customers.index', compact('customers'));
    }
}

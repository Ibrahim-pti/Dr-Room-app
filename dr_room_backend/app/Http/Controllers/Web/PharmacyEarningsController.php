<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class PharmacyEarningsController extends Controller
{
    public function index()
    {
        $today = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();
        
        $todayEarnings = Order::where('assigned_pharmacy_id', Auth::id())
            ->where('status', 'completed')
            ->whereDate('created_at', $today)
            ->sum('total_price');
            
        $monthEarnings = Order::where('assigned_pharmacy_id', Auth::id())
            ->where('status', 'completed')
            ->where('created_at', '>=', $thisMonth)
            ->sum('total_price');
            
        $totalEarnings = Order::where('assigned_pharmacy_id', Auth::id())
            ->where('status', 'completed')
            ->sum('total_price');

        $recentOrders = Order::where('assigned_pharmacy_id', Auth::id())
            ->where('status', 'completed')
            ->latest()
            ->take(10)
            ->get();

        return view('pharmacy.earnings.index', compact('todayEarnings', 'monthEarnings', 'totalEarnings', 'recentOrders'));
    }
}

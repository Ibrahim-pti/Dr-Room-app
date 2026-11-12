<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Medication;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;

class PharmacyDashboardController extends Controller
{
    /** Stock at or below this is surfaced as needing a reorder. */
    private const LOW_STOCK_THRESHOLD = 10;

    public function index()
    {
        $user = Auth::user();

        // Same scope PharmacyOrderController uses: unclaimed pharmacy orders
        // plus everything already assigned to this pharmacy.
        $visibleOrders = fn() => Order::forPharmacy()
            ->where(function ($query) {
                $query->where('assigned_pharmacy_id', Auth::id())
                    ->orWhere(function ($unassigned) {
                        $unassigned->whereNull('assigned_pharmacy_id')
                            ->where('status', 'pending');
                    });
            });

        $todayOrders = $visibleOrders()->whereDate('created_at', today())->count();

        $pendingOrders = $visibleOrders()->where('status', 'pending')->count();
        $totalMedications = Medication::where('user_id', $user->id)->count();

        $lowStockItems = Medication::where('user_id', $user->id)
            ->where('is_active', true)
            ->where('stock', '<=', self::LOW_STOCK_THRESHOLD)
            ->count();

        return view('pharmacy.dashboard.index', compact(
            'user',
            'todayOrders',
            'pendingOrders',
            'totalMedications',
            'lowStockItems'
        ));
    }
}

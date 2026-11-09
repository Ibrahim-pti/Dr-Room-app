<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\LabTest;
use App\Models\Nurse;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminAnalyticsController extends Controller
{
    public function overview()
    {
        $now = now();
        $startOfMonth = $now->copy()->startOfMonth();

        // 1. Monthly Metrics
        $thisMonthOrders = Order::where('created_at', '>=', $startOfMonth)->count();
        $thisMonthCompleted = Order::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->count();
        $thisMonthRevenue = Order::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->sum('total_price');
        $newUsersThisMonth = User::where('created_at', '>=', $startOfMonth)->count();

        // 2. User Growth (last 6 months)
        $userGrowth = User::selectRaw('YEAR(created_at) as year, MONTH(created_at) as month, COUNT(*) as count')
            ->where('created_at', '>=', now()->subMonths(6))
            ->groupBy('year', 'month')
            ->orderBy('year', 'asc')
            ->orderBy('month', 'asc')
            ->get();

        // 3. Top Requested Lab Tests
        $topTests = OrderItem::select('title', DB::raw('COUNT(*) as total_requests'), DB::raw('SUM(price * quantity) as total_volume'))
            ->whereNotNull('title')
            ->groupBy('title')
            ->orderBy('total_requests', 'desc')
            ->take(8)
            ->get();

        if ($topTests->isEmpty()) {
            // Fallback from lab_results if orders items are empty
            $topTests = LabTest::select('name as title', DB::raw('count(*) as total_requests'))
                ->join('lab_results', 'lab_tests.id', '=', 'lab_results.test_id')
                ->groupBy('lab_tests.id', 'lab_tests.name')
                ->orderBy('total_requests', 'desc')
                ->take(8)
                ->get();
        }

        // 4. Top Performing Nurses
        $topNurses = Nurse::with('user:id,name,phone,profile_image')
            ->orderBy('rating', 'desc')
            ->take(5)
            ->get();

        // 5. Test Categories Distribution
        $categoriesBreakdown = LabTest::select('category_id', DB::raw('COUNT(*) as count'))
            ->whereNotNull('category_id')
            ->groupBy('category_id')
            ->with('category:id,name,name_en,name_ar,name_kmr')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'monthly' => [
                    'orders_count' => $thisMonthOrders,
                    'completed_count' => $thisMonthCompleted,
                    'revenue' => (float) $thisMonthRevenue,
                    'new_users' => $newUsersThisMonth,
                ],
                'user_growth' => $userGrowth,
                'top_tests' => $topTests,
                'top_nurses' => $topNurses,
                'categories_distribution' => $categoriesBreakdown,
            ]
        ]);
    }
}

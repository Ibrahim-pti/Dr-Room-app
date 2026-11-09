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
        $thisMonthOrders = 0;
        $thisMonthCompleted = 0;
        $thisMonthRevenue = 0.0;
        $newUsersThisMonth = 0;
        try {
            $thisMonthOrders = Order::where('created_at', '>=', $startOfMonth)->count();
            $thisMonthCompleted = Order::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->count();
            $thisMonthRevenue = (float) Order::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->sum('total_price');
            $newUsersThisMonth = User::where('created_at', '>=', $startOfMonth)->count();
        } catch (\Throwable $e) {}

        // 2. User Growth (last 6 months)
        $userGrowth = [];
        try {
            $userGrowth = User::selectRaw('YEAR(created_at) as year, MONTH(created_at) as month, COUNT(*) as count')
                ->where('created_at', '>=', now()->subMonths(6))
                ->groupBy(DB::raw('YEAR(created_at)'), DB::raw('MONTH(created_at)'))
                ->orderBy(DB::raw('YEAR(created_at)'), 'asc')
                ->orderBy(DB::raw('MONTH(created_at)'), 'asc')
                ->get();
        } catch (\Throwable $e) {
            $userGrowth = [];
        }

        // 3. Top Requested Lab Tests
        $topTests = collect();
        try {
            $topTests = OrderItem::select('item_name as title', DB::raw('COUNT(*) as total_requests'), DB::raw('SUM(price * quantity) as total_volume'))
                ->whereNotNull('item_name')
                ->groupBy('item_name')
                ->orderBy('total_requests', 'desc')
                ->take(8)
                ->get();

            if ($topTests->isEmpty()) {
                // Fallback from lab_results if order items are empty
                $topTests = LabTest::select('lab_tests.name as title', DB::raw('count(lab_results.id) as total_requests'), DB::raw('0 as total_volume'))
                    ->join('lab_results', 'lab_tests.id', '=', 'lab_results.test_id')
                    ->groupBy('lab_tests.name')
                    ->orderBy('total_requests', 'desc')
                    ->take(8)
                    ->get();
            }

            if ($topTests->isEmpty()) {
                // Final fallback: list existing active lab tests so screen isn't empty
                $topTests = LabTest::select('name as title', DB::raw('0 as total_requests'), DB::raw('0 as total_volume'))
                    ->where('is_active', true)
                    ->take(6)
                    ->get();
            }
        } catch (\Throwable $e) {
            $topTests = collect();
        }

        // 4. Top Performing Nurses
        $topNurses = [];
        try {
            $topNurses = Nurse::with('user:id,name,phone,profile_image')
                ->orderBy('rating', 'desc')
                ->take(5)
                ->get();
        } catch (\Throwable $e) {
            $topNurses = [];
        }

        // 5. Test Categories Distribution
        $categoriesBreakdown = [];
        try {
            $categoriesBreakdown = LabTest::select('type as category', DB::raw('COUNT(*) as count'))
                ->whereNotNull('type')
                ->groupBy('type')
                ->get();
        } catch (\Throwable $e) {
            $categoriesBreakdown = [];
        }

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


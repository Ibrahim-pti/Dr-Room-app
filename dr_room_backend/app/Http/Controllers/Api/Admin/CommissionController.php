<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\CommissionService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class CommissionController extends Controller
{
    /** @return array{0:int,1:int} */
    private function period(Request $request): array
    {
        $year = (int) $request->input('year', now()->year);
        $month = (int) $request->input('month', now()->month);
        if ($year < 2000 || $year > 2100) {
            $year = (int) now()->year;
        }
        if ($month < 1 || $month > 12) {
            $month = (int) now()->month;
        }
        return [$year, $month];
    }

    public function settings(Request $request)
    {
        [$year, $month] = $this->period($request);

        return response()->json([
            'success' => true,
            'data' => array_merge(
                ['year' => $year, 'month' => $month],
                CommissionService::ratesFor($year, $month),
            ),
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'nursing_rate' => 'required|numeric|min:0|max:100',
            'lab_rate' => 'required|numeric|min:0|max:100',
            'year' => 'nullable|integer|min:2000|max:2100',
            'month' => 'nullable|integer|min:1|max:12',
        ]);

        [$year, $month] = $this->period($request);

        $updated = CommissionService::saveRates(
            $year,
            $month,
            (float) $validated['nursing_rate'],
            (float) $validated['lab_rate'],
        );

        return response()->json([
            'success' => true,
            'message' => 'ڕێژەکانی کۆمیشن بۆ ئەم مانگە نوێکرانەوە',
            'data' => array_merge(
                ['year' => $year, 'month' => $month, 'recalculated_orders' => $updated],
                CommissionService::ratesFor($year, $month),
            ),
        ]);
    }

    public function summary(Request $request)
    {
        [$year, $month] = $this->period($request);
        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end = (clone $start)->endOfMonth();

        $orders = Order::where('status', 'completed')
            ->whereBetween('created_at', [$start, $end])
            ->get(['id', 'service_type', 'total_price', 'commission_rate', 'commission_amount', 'created_at']);

        $rates = CommissionService::ratesFor($year, $month);
        $labels = ['nursing' => 'پەرستاری ماڵەوە', 'lab' => 'تاقیگەکان'];
        $buckets = [];
        foreach (CommissionService::TYPES as $type) {
            $buckets[$type] = [
                'service_type' => $type,
                'label' => $labels[$type],
                'rate' => (float) $rates["{$type}_rate"],
                'total_orders' => 0,
                'total_amount' => 0.0,
                'total_commission' => 0.0,
                'provider_net' => 0.0,
            ];
        }

        foreach ($orders as $order) {
            $cat = CommissionService::categoryFor($order->service_type);
            if (!$cat) {
                continue; // pharmacy / clinic orders are not part of the commission system
            }
            $total = max(0.0, (float) $order->total_price);
            $comm = CommissionService::commissionOf($order);
            $buckets[$cat]['total_orders']++;
            $buckets[$cat]['total_amount'] += $total;
            $buckets[$cat]['total_commission'] += $comm;
            $buckets[$cat]['provider_net'] += $total - $comm;
        }

        foreach ($buckets as &$b) {
            $b['total_amount'] = round($b['total_amount'], 2);
            $b['total_commission'] = round($b['total_commission'], 2);
            $b['provider_net'] = round($b['provider_net'], 2);
        }
        unset($b);

        $totalRevenue = array_sum(array_column($buckets, 'total_amount'));
        $totalCommission = array_sum(array_column($buckets, 'total_commission'));

        return response()->json([
            'success' => true,
            'data' => [
                'year' => $year,
                'month' => $month,
                'total_orders' => array_sum(array_column($buckets, 'total_orders')),
                'total_revenue' => round($totalRevenue, 2),
                'total_commission' => round($totalCommission, 2),
                'total_provider_payout' => round($totalRevenue - $totalCommission, 2),
                'breakdown' => array_values($buckets),
            ],
        ]);
    }
}

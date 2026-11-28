<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Lab;
use App\Models\Order;
use App\Models\User;
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

        $orders = Order::with(['assignedNurse:id,name,phone', 'assignedLab:id,name,phone', 'items'])
            ->where('status', 'completed')
            ->whereBetween('created_at', [$start, $end])
            ->get([
                'id',
                'service_type',
                'total_price',
                'commission_rate',
                'commission_amount',
                'assigned_nurse_id',
                'assigned_lab_id',
                'created_at',
            ]);

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

        // Seed every nurse & lab so the admin sees all providers (including 0-order ones).
        $providers = [];
        $allProviders = User::whereIn('role', ['nurse', 'lab'])
            ->orderBy('name')
            ->get(['id', 'name', 'phone', 'role', 'status']);
        foreach ($allProviders as $u) {
            $type = $u->role === 'lab' ? 'lab' : 'nursing';
            $key = "{$type}_{$u->id}";
            $providers[$key] = [
                'id' => $u->id,
                'name' => $u->name ?: ($type === 'lab' ? 'تاقیگە' : 'پەرستار'),
                'phone' => $u->phone ?? '',
                'service_type' => $type,
                'status' => $u->status ?? 'approved',
                'rate' => (float) $rates["{$type}_rate"],
                'total_orders' => 0,
                'total_amount' => 0.0,
                'total_commission' => 0.0,
                'provider_net' => 0.0,
            ];
        }

        $labModelCache = [];

        foreach ($orders as $order) {
            $cat = CommissionService::categoryFor($order->service_type);
            if (!$cat) {
                continue; // pharmacy / clinic orders are not part of the commission system
            }
            $total = max(0.0, (float) $order->total_price);
            $comm = CommissionService::commissionOf($order);
            $net = $total - $comm;

            $buckets[$cat]['total_orders']++;
            $buckets[$cat]['total_amount'] += $total;
            $buckets[$cat]['total_commission'] += $comm;
            $buckets[$cat]['provider_net'] += $net;

            $providerId = $cat === 'nursing' ? $order->assigned_nurse_id : $order->assigned_lab_id;
            $providerUser = $cat === 'nursing' ? $order->assignedNurse : $order->assignedLab;

            if ($cat === 'lab' && !$providerId && $order->items->isNotEmpty()) {
                $firstExtra = $order->items->first()->extra_data ?? [];
                if (is_string($firstExtra)) {
                    $firstExtra = json_decode($firstExtra, true) ?: [];
                }
                if (is_array($firstExtra) && !empty($firstExtra['lab_id'])) {
                    $rawLabId = (int) $firstExtra['lab_id'];
                    if (!array_key_exists($rawLabId, $labModelCache)) {
                        $labModelCache[$rawLabId] = Lab::with('user:id,name,phone,status')->find($rawLabId);
                    }
                    $labModel = $labModelCache[$rawLabId];
                    if ($labModel && $labModel->user) {
                        $providerId = $labModel->user->id;
                        $providerUser = $labModel->user;
                    }
                }
            }

            if ($providerId) {
                $key = "{$cat}_{$providerId}";
                if (!isset($providers[$key])) {
                    $providers[$key] = [
                        'id' => (int) $providerId,
                        'name' => $providerUser?->name ?: ($cat === 'lab' ? 'تاقیگە' : 'پەرستار'),
                        'phone' => $providerUser?->phone ?? '',
                        'service_type' => $cat,
                        'status' => $providerUser?->status ?? 'approved',
                        'rate' => (float) $rates["{$cat}_rate"],
                        'total_orders' => 0,
                        'total_amount' => 0.0,
                        'total_commission' => 0.0,
                        'provider_net' => 0.0,
                    ];
                }
            } else {
                $key = "unassigned_{$cat}";
                if (!isset($providers[$key])) {
                    $providers[$key] = [
                        'id' => null,
                        'name' => $cat === 'lab' ? 'تاقیگەی دیارینەکراو' : 'پەرستاری دیارینەکراو',
                        'phone' => '',
                        'service_type' => $cat,
                        'status' => 'unassigned',
                        'rate' => (float) $rates["{$cat}_rate"],
                        'total_orders' => 0,
                        'total_amount' => 0.0,
                        'total_commission' => 0.0,
                        'provider_net' => 0.0,
                    ];
                }
            }

            $providers[$key]['total_orders']++;
            $providers[$key]['total_amount'] += $total;
            $providers[$key]['total_commission'] += $comm;
            $providers[$key]['provider_net'] += $net;
        }

        foreach ($buckets as &$b) {
            $b['total_amount'] = round($b['total_amount'], 2);
            $b['total_commission'] = round($b['total_commission'], 2);
            $b['provider_net'] = round($b['provider_net'], 2);
        }
        unset($b);

        foreach ($providers as &$p) {
            $p['total_amount'] = round($p['total_amount'], 2);
            $p['total_commission'] = round($p['total_commission'], 2);
            $p['provider_net'] = round($p['provider_net'], 2);
        }
        unset($p);

        $providersList = array_values($providers);
        usort($providersList, function ($a, $b) {
            if ($b['total_amount'] !== $a['total_amount']) {
                return $b['total_amount'] <=> $a['total_amount'];
            }
            if ($b['total_orders'] !== $a['total_orders']) {
                return $b['total_orders'] <=> $a['total_orders'];
            }
            return strcmp((string) $a['name'], (string) $b['name']);
        });

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
                'providers' => $providersList,
                'branding' => \App\Services\ReportBrandingService::get(),
                'generated_at' => now()->format('Y-m-d H:i'),
            ],
        ]);
    }
}

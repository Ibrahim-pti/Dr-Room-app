<?php

namespace App\Services;

use App\Models\LabResult;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class ProviderReportService
{
    public const TIMEZONE = 'Asia/Baghdad';

    /**
     * Build a complete accounting & monthly report dataset for a Nurse or Lab.
     */
    public function buildForNurse(int $nurseUserId, ?string $selectedMonth = null): array
    {
        $orders = Order::where('assigned_nurse_id', $nurseUserId)
            ->forNursing()
            ->with(['items', 'patient:id,name,phone'])
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->compileReport($orders, $selectedMonth, [
            'role' => 'nurse',
            'page_title' => 'حسابات و ڕاپۆرتی مانگانە',
            'page_subtitle' => 'پوختەی داهات، خزمەتگوزارییە ئەنجامدراوەکان، نەخۆشەکان و ڕاپۆرتی مانگانەی پەرستاری.',
            'work_label' => 'داواکاری تەواوکراو',
            'items_label' => 'خزمەتگوزاری ئەنجامدراو',
            'top_items_title' => 'زۆرترین خزمەتگوزارییە ئەنجامدراوەکان',
            'item_col_label' => 'خزمەتگوزاری',
            'accent' => 'teal',
            'extra_results_count' => null,
        ]);
    }

    public function buildForLab(int $labUserId, ?int $labProfileId = null, ?string $selectedMonth = null): array
    {
        $orders = Order::where('assigned_lab_id', $labUserId)
            ->forLab()
            ->with(['items', 'patient:id,name,phone'])
            ->orderBy('created_at', 'desc')
            ->get();

        $manualResultsCount = null;
        if ($labProfileId) {
            $manualResultsCount = LabResult::where('lab_id', $labProfileId)->count();
        }

        return $this->compileReport($orders, $selectedMonth, [
            'role' => 'lab',
            'page_title' => 'حسابات و ڕاپۆرتی تاقیگە',
            'page_subtitle' => 'پوختەی پشکنینە ئەنجامدراوەکان، داهات، کارەکان، نەخۆشەکان و ڕاپۆرتی مانگانە.',
            'work_label' => 'داواکاری تەواوکراو',
            'items_label' => 'فەحس و پشکنینی ئەنجامدراو',
            'top_items_title' => 'زۆرترین پشکنینە ئەنجامدراوەکان',
            'item_col_label' => 'ناوی پشکنین',
            'accent' => 'violet',
            'extra_results_count' => $manualResultsCount,
        ]);
    }

    public function summarizeCurrentMonth(Collection $orders): array
    {
        $currentMonth = now(self::TIMEZONE)->format('Y-m');
        $monthOrders = $orders->filter(
            fn (Order $o) => $this->localMonth($o) === $currentMonth
        );

        return $this->summarizeSlice($monthOrders, $currentMonth);
    }

    private function compileReport(Collection $orders, ?string $selectedMonth, array $meta): array
    {
        $currentMonth = now(self::TIMEZONE)->format('Y-m');

        $months = $orders
            ->map(fn (Order $o) => $this->localMonth($o))
            ->filter()
            ->push($currentMonth)
            ->unique()
            ->sortDesc()
            ->values();

        if ($selectedMonth !== 'all' && (!$selectedMonth || !preg_match('/^\d{4}-\d{2}$/', $selectedMonth))) {
            $selectedMonth = $currentMonth;
        }

        $periodOrders = $selectedMonth === 'all'
            ? $orders
            : $orders->filter(fn (Order $o) => $this->localMonth($o) === $selectedMonth)->values();

        $summary = $this->summarizeSlice($periodOrders, $selectedMonth);
        $overall = $this->summarizeSlice($orders, 'all');

        // Monthly breakdown across all available months (newest first)
        $monthlyRows = $months->map(function (string $month) use ($orders) {
            $slice = $orders->filter(fn (Order $o) => $this->localMonth($o) === $month);
            return $this->summarizeSlice($slice, $month);
        })->values();

        // Chart data: last 6 months in chronological order
        $chartMonths = collect(range(5, 0))->map(
            fn (int $ago) => now(self::TIMEZONE)->startOfMonth()->subMonths($ago)->format('Y-m')
        );
        $chartSeries = $chartMonths->map(function (string $month) use ($monthlyRows) {
            $row = $monthlyRows->firstWhere('month', $month);
            return [
                'month' => $month,
                'gross_revenue' => $row['gross_revenue'] ?? 0.0,
                'net_revenue' => $row['net_revenue'] ?? 0.0,
                'completed_orders' => $row['completed_orders'] ?? 0,
                'items_performed' => $row['items_performed'] ?? 0,
            ];
        })->values();

        // Top services / lab tests in the selected period (completed orders)
        $topItems = $periodOrders
            ->where('status', 'completed')
            ->flatMap(function (Order $order) {
                if ($order->items->isEmpty()) {
                    return [[
                        'name' => $order->isLabService() ? 'پشکنینی تاقیگە' : 'خزمەتگوزاری پەرستاری',
                        'quantity' => 1,
                        'revenue' => (float) $order->total_price,
                    ]];
                }

                return $order->items->map(function ($item) {
                    $qty = max(1, (int) ($item->quantity ?? 1));
                    return [
                        'name' => (string) ($item->item_name ?: 'بێ ناو'),
                        'quantity' => $qty,
                        'revenue' => (float) ($item->price ?? 0) * $qty,
                    ];
                });
            })
            ->groupBy('name')
            ->map(function (Collection $group, string $name) {
                return [
                    'name' => $name,
                    'count' => (int) $group->sum('quantity'),
                    'revenue' => (float) $group->sum('revenue'),
                ];
            })
            ->sortByDesc('count')
            ->values()
            ->take(10);

        return [
            'meta' => $meta,
            'selectedMonth' => $selectedMonth,
            'currentMonth' => $currentMonth,
            'months' => $months,
            'summary' => $summary,
            'overall' => $overall,
            'monthlyRows' => $monthlyRows,
            'chartSeries' => $chartSeries,
            'topItems' => $topItems,
            'ledgerOrders' => $periodOrders->take(50)->values(),
        ];
    }

    private function summarizeSlice(Collection $orders, string $month): array
    {
        $completed = $orders->where('status', 'completed');
        $active = $orders->whereIn('status', ['pending', 'processing', 'in_progress', 'on_the_way', 'approved', 'confirmed']);
        $cancelled = $orders->whereIn('status', ['cancelled', 'rejected']);

        $grossRevenue = (float) $completed->sum('total_price');
        $commissionTotal = (float) $completed->sum(fn (Order $o) => (float) ($o->commission_amount ?? 0));
        $netRevenue = (float) $completed->sum(function (Order $o) {
            if ($o->provider_net_amount !== null) {
                return (float) $o->provider_net_amount;
            }
            return max(0.0, (float) $o->total_price - (float) ($o->commission_amount ?? 0));
        });

        $cashRevenue = (float) $completed
            ->filter(fn (Order $o) => strtolower((string) ($o->payment_method ?? 'cash')) === 'cash')
            ->sum('total_price');
        $onlineRevenue = max(0.0, $grossRevenue - $cashRevenue);

        $itemsPerformed = (int) $completed->sum(function (Order $o) {
            if ($o->items->isEmpty()) {
                return 1;
            }
            return (int) $o->items->sum(fn ($item) => max(1, (int) ($item->quantity ?? 1)));
        });

        $uniquePatients = $orders->pluck('patient_id')->filter()->unique()->count();
        $completedPatients = $completed->pluck('patient_id')->filter()->unique()->count();

        return [
            'month' => $month,
            'total_orders' => $orders->count(),
            'completed_orders' => $completed->count(),
            'active_orders' => $active->count(),
            'cancelled_orders' => $cancelled->count(),
            'items_performed' => $itemsPerformed,
            'unique_patients' => $uniquePatients,
            'completed_patients' => $completedPatients,
            'gross_revenue' => $grossRevenue,
            'commission_total' => $commissionTotal,
            'net_revenue' => $netRevenue,
            'cash_revenue' => $cashRevenue,
            'online_revenue' => $onlineRevenue,
        ];
    }

    private function localMonth(Order $order): ?string
    {
        if (!$order->created_at) {
            return null;
        }
        return Carbon::parse($order->created_at)->timezone(self::TIMEZONE)->format('Y-m');
    }
}

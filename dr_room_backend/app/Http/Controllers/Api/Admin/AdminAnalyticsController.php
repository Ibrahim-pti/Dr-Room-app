<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Appointment;
use App\Models\Driver;
use App\Models\Expense;
use App\Models\LabResult;
use App\Models\Nurse;
use App\Models\Order;
use App\Models\SupportTicket;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class AdminAnalyticsController extends Controller
{
    public const TIMEZONE = 'Asia/Baghdad';

    public function overview(Request $request)
    {
        $selectedMonth = trim((string) $request->input('month', ''));
        $serviceFilter = trim((string) $request->input('service_type', 'all'));
        if (!in_array($serviceFilter, ['all', 'lab', 'nursing'], true)) {
            $serviceFilter = 'all';
        }

        $currentMonth = now(self::TIMEZONE)->format('Y-m');
        if ($selectedMonth !== 'all' && !preg_match('/^\d{4}-\d{2}$/', $selectedMonth)) {
            $selectedMonth = $currentMonth;
        }

        $orders = Order::with([
            'items',
            'patient:id,name,phone',
            'assignedNurse:id,name',
            'assignedLab:id,name',
            'assignedPharmacy:id,name',
            'assignedDriver:id,name',
        ])
            ->orderBy('created_at', 'desc')
            ->get();

        $expenses = Expense::orderBy('expense_date', 'desc')->get();

        $nonPatientRoles = ['admin', 'staff', 'moderator', 'doctor', 'nurse', 'lab', 'pharmacy', 'xray', 'driver'];
        $patients = User::where(function ($q) use ($nonPatientRoles) {
            $q->whereNull('role')->orWhereNotIn('role', $nonPatientRoles);
        })
            ->select('id', 'created_at')
            ->get();

        // Build all available YYYY-MM months across orders, expenses, and patients
        $months = collect([$currentMonth])
            ->merge($orders->map(fn (Order $o) => $this->localMonth($o->created_at)))
            ->merge($expenses->map(fn (Expense $e) => $this->expenseMonth($e)))
            ->merge($patients->map(fn (User $u) => $this->localMonth($u->created_at)))
            ->filter()
            ->unique()
            ->sortDesc()
            ->values();

        // Apply service_type filter to orders for main report
        $filteredOrders = $serviceFilter === 'all'
            ? $orders
            : $orders->filter(fn (Order $o) => $this->classifyOrderService($o) === $serviceFilter)->values();

        $periodOrders = $selectedMonth === 'all'
            ? $filteredOrders
            : $filteredOrders->filter(fn (Order $o) => $this->localMonth($o->created_at) === $selectedMonth)->values();

        $periodExpenses = $selectedMonth === 'all'
            ? $expenses
            : $expenses->filter(fn (Expense $e) => $this->expenseMonth($e) === $selectedMonth)->values();

        $periodNewUsers = $selectedMonth === 'all'
            ? $patients->count()
            : $patients->filter(fn (User $u) => $this->localMonth($u->created_at) === $selectedMonth)->count();

        $summary = $this->summarizeSlice($periodOrders, $periodExpenses, $periodNewUsers, $selectedMonth);
        $overall = $this->summarizeSlice($filteredOrders, $expenses, $patients->count(), 'all');

        // Monthly rows across all months
        $monthlyRows = $months->map(function (string $month) use ($filteredOrders, $expenses, $patients) {
            $mOrders = $filteredOrders->filter(fn (Order $o) => $this->localMonth($o->created_at) === $month);
            $mExpenses = $expenses->filter(fn (Expense $e) => $this->expenseMonth($e) === $month);
            $mUsers = $patients->filter(fn (User $u) => $this->localMonth($u->created_at) === $month)->count();

            return $this->summarizeSlice($mOrders, $mExpenses, $mUsers, $month);
        })->values();

        // 6-month chronological chart series
        $chartMonths = collect(range(5, 0))->map(
            fn (int $ago) => now(self::TIMEZONE)->startOfMonth()->subMonths($ago)->format('Y-m')
        );
        $chartSeries = $chartMonths->map(function (string $month) use ($monthlyRows) {
            $row = $monthlyRows->firstWhere('month', $month);
            return [
                'month' => $month,
                'gross_revenue' => $row['gross_revenue'] ?? 0.0,
                'commission_total' => $row['commission_total'] ?? 0.0,
                'expenses_total' => $row['expenses_total'] ?? 0.0,
                'net_profit' => $row['net_profit'] ?? 0.0,
                'total_orders' => $row['total_orders'] ?? 0,
                'completed_orders' => $row['completed_orders'] ?? 0,
                'items_performed' => $row['items_performed'] ?? 0,
                'new_users' => $row['new_users'] ?? 0,
            ];
        })->values();

        // Service type breakdown (always computed on all orders for the selected month so admin compares sectors)
        $monthAllServiceOrders = $selectedMonth === 'all'
            ? $orders
            : $orders->filter(fn (Order $o) => $this->localMonth($o->created_at) === $selectedMonth)->values();

        $serviceDefs = [
            'lab' => 'پشکنینی تاقیگە',
            'nursing' => 'پەرستاری ماڵەوە',
            'other' => 'خزمەتگوزاری تر',
        ];
        $serviceBreakdown = collect($serviceDefs)->map(function (string $label, string $key) use ($monthAllServiceOrders) {
            $slice = $monthAllServiceOrders->filter(fn (Order $o) => $this->classifyOrderService($o) === $key);
            $completed = $slice->where('status', 'completed');
            return [
                'key' => $key,
                'label' => $label,
                'orders_count' => $slice->count(),
                'completed_count' => $completed->count(),
                'revenue' => (float) $completed->sum('total_price'),
            ];
        })->filter(fn (array $row) => $row['orders_count'] > 0 || $row['key'] !== 'other')->values();

        // Status breakdown in period
        $statusBreakdown = [
            [
                'key' => 'completed',
                'label' => 'تەواوکراو',
                'count' => $summary['completed_orders'],
            ],
            [
                'key' => 'active',
                'label' => 'چالاک / چاوەڕوان',
                'count' => $summary['active_orders'],
            ],
            [
                'key' => 'cancelled',
                'label' => 'هەڵوەشاوە',
                'count' => $summary['cancelled_orders'],
            ],
        ];

        // Top requested items / tests from completed orders in period
        $topItems = $periodOrders
            ->where('status', 'completed')
            ->flatMap(function (Order $order) {
                $svc = $this->classifyOrderService($order);
                if ($order->items->isEmpty()) {
                    $fallbackName = match ($svc) {
                        'lab' => 'پشکنینی تاقیگە',
                        'nursing' => 'خزمەتگوزاری پەرستاری',
                        default => 'خزمەتگوزاری گشتی',
                    };
                    return [[
                        'name' => $fallbackName,
                        'service_type' => $svc,
                        'quantity' => 1,
                        'revenue' => (float) ($order->total_price ?? 0),
                    ]];
                }

                return $order->items->map(function ($item) use ($svc) {
                    $qty = max(1, (int) ($item->quantity ?? 1));
                    return [
                        'name' => trim((string) ($item->item_name ?: 'خزمەتگوزاری')),
                        'service_type' => $svc,
                        'quantity' => $qty,
                        'revenue' => (float) ($item->price ?? 0) * $qty,
                    ];
                });
            })
            ->groupBy('name')
            ->map(function (Collection $group, string $name) {
                return [
                    'name' => $name,
                    'service_type' => (string) ($group->first()['service_type'] ?? 'other'),
                    'count' => (int) $group->sum('quantity'),
                    'revenue' => (float) $group->sum('revenue'),
                ];
            })
            ->sortByDesc('count')
            ->values()
            ->take(10);

        // Top Labs in period
        $topLabs = $periodOrders
            ->where('status', 'completed')
            ->filter(fn (Order $o) => !empty($o->assigned_lab_id))
            ->groupBy('assigned_lab_id')
            ->map(function (Collection $group) {
                /** @var Order $first */
                $first = $group->first();
                return [
                    'id' => $first->assigned_lab_id,
                    'name' => $first->assignedLab->name ?? 'تاقیگە',
                    'orders_count' => $group->count(),
                    'revenue' => (float) $group->sum('total_price'),
                ];
            })
            ->sortByDesc('orders_count')
            ->values()
            ->take(5);

        // Top Nurses in period (merge ratings)
        $nurseRatings = Nurse::pluck('rating', 'user_id');
        $topNurses = $periodOrders
            ->where('status', 'completed')
            ->filter(fn (Order $o) => !empty($o->assigned_nurse_id))
            ->groupBy('assigned_nurse_id')
            ->map(function (Collection $group) use ($nurseRatings) {
                /** @var Order $first */
                $first = $group->first();
                $uid = $first->assigned_nurse_id;
                return [
                    'id' => $uid,
                    'name' => $first->assignedNurse->name ?? 'پەرستار',
                    'orders_count' => $group->count(),
                    'revenue' => (float) $group->sum('total_price'),
                    'rating' => (float) ($nurseRatings[$uid] ?? 5.0),
                ];
            })
            ->sortByDesc('orders_count')
            ->values()
            ->take(5);

        // System-wide ecosystem counts
        $ecosystem = [
            'total_patients' => $patients->count(),
            'total_labs' => User::where('role', 'lab')->where('status', 'approved')->count(),
            'pending_labs' => User::where('role', 'lab')->where('status', 'pending')->count(),
            'total_nurses' => User::where('role', 'nurse')->where('status', 'approved')->count(),
            'pending_nurses' => User::where('role', 'nurse')->where('status', 'pending')->count(),
            'total_drivers' => User::where('role', 'driver')->where('status', 'approved')->count(),
            'pending_drivers' => User::where('role', 'driver')->where('status', 'pending')->count(),
            'online_drivers' => $this->safeCount(fn () => Driver::whereHas('user', fn ($q) => $q->where('role', 'driver')->where('status', 'approved'))
                ->whereIn('duty_status', ['available', 'busy'])->count()),
            'busy_drivers' => $this->safeCount(fn () => Driver::whereHas('user', fn ($q) => $q->where('role', 'driver')->where('status', 'approved'))
                ->where('duty_status', 'busy')->count()),
            'open_tickets' => $this->safeCount(fn () => SupportTicket::where('status', 'open')->count()),
            'total_tickets' => $this->safeCount(fn () => SupportTicket::count()),
            'total_lab_results' => $this->safeCount(fn () => LabResult::count()),
            'total_appointments' => $this->safeCount(fn () => Appointment::count()),
        ];

        // Branding for PDF export
        $branding = [
            'header_title' => AppSetting::get('report_header_title', 'دکتۆر ڕۆم - Dr. Room'),
            'header_subtitle' => AppSetting::get('report_header_subtitle', 'سیستەمی تەندروستی و پزیشکی ماڵەوە'),
            'footer_text' => AppSetting::get('report_footer_text', 'پەسەندکراوە لەلایەن بەڕێوەبەرایەتی Dr. Room'),
            'emergency_phone' => AppSetting::get('report_emergency_phone', '+964 750 000 0000'),
            'show_stamp' => (bool) AppSetting::get('report_show_stamp', true),
        ];

        // Period ledger (latest 60 orders)
        $ledgerOrders = $periodOrders->take(60)->map(function (Order $order) {
            $svc = $this->classifyOrderService($order);
            $providerName = $order->assignedLab->name
                ?? $order->assignedNurse->name
                ?? $order->assignedPharmacy->name
                ?? $order->assignedDriver->name
                ?? 'تەرخان نەکراوە';
            $itemsSummary = $order->items->isNotEmpty()
                ? $order->items->pluck('item_name')->filter()->join('، ')
                : match ($svc) {
                    'lab' => 'پشکنینی تاقیگە',
                    'nursing' => 'پەرستاری ماڵەوە',
                    default => 'خزمەتگوزاری پزیشکی',
                };
            $localTime = $order->created_at
                ? Carbon::parse($order->created_at)->timezone(self::TIMEZONE)
                : null;

            return [
                'id' => $order->id,
                'order_number' => $order->order_number ?? ('#ORD-' . str_pad((string) $order->id, 4, '0', STR_PAD_LEFT)),
                'patient_name' => $order->patient->name ?? 'نەخۆش',
                'patient_phone' => $order->patient->phone ?? '',
                'provider_name' => $providerName,
                'service_type' => $svc,
                'items_summary' => $itemsSummary,
                'status' => (string) ($order->status ?? 'pending'),
                'payment_method' => strtolower((string) ($order->payment_method ?? 'cash')),
                'total_price' => (float) ($order->total_price ?? 0),
                'commission_amount' => (float) ($order->commission_amount ?? 0),
                'delivery_fee' => (float) ($order->delivery_fee ?? 0),
                'discount_amount' => (float) ($order->discount_amount ?? 0),
                'date' => $localTime?->format('Y-m-d') ?? '',
                'time' => $localTime?->format('h:i A') ?? '',
            ];
        })->values();

        return response()->json([
            'success' => true,
            'data' => [
                'version' => 2,
                'generated_at' => now(self::TIMEZONE)->format('Y-m-d H:i'),
                'current_month' => $currentMonth,
                'selected_month' => $selectedMonth,
                'service_type' => $serviceFilter,
                'months' => $months,
                'summary' => $summary,
                'overall' => $overall,
                'monthly_rows' => $monthlyRows,
                'chart_series' => $chartSeries,
                'service_breakdown' => $serviceBreakdown,
                'status_breakdown' => $statusBreakdown,
                'top_items' => $topItems,
                'top_labs' => $topLabs,
                'top_nurses' => $topNurses,
                'ecosystem' => $ecosystem,
                'branding' => $branding,
                'ledger_orders' => $ledgerOrders,
            ],
        ]);
    }

    private function summarizeSlice(Collection $orders, Collection $expenses, int $newUsers, string $month): array
    {
        $completed = $orders->where('status', 'completed');
        $cancelled = $orders->whereIn('status', ['cancelled', 'rejected']);
        $active = $orders->reject(fn (Order $o) => in_array($o->status, ['completed', 'cancelled', 'rejected'], true));

        $grossRevenue = (float) $completed->sum('total_price');
        $commissionTotal = (float) $completed->sum(fn (Order $o) => (float) ($o->commission_amount ?? 0));
        $providerNet = (float) $completed->sum(function (Order $o) {
            if ($o->provider_net_amount !== null) {
                return (float) $o->provider_net_amount;
            }
            return max(0.0, (float) ($o->total_price ?? 0) - (float) ($o->commission_amount ?? 0));
        });
        $deliveryFees = (float) $completed->sum(fn (Order $o) => (float) ($o->delivery_fee ?? 0));

        $nonCancelled = $orders->reject(fn (Order $o) => in_array($o->status, ['cancelled', 'rejected'], true));
        $discountTotal = (float) $nonCancelled->sum(fn (Order $o) => (float) ($o->discount_amount ?? 0));
        $discountedOrders = $nonCancelled->filter(
            fn (Order $o) => (float) ($o->discount_amount ?? 0) > 0 || !empty($o->coupon_code)
        )->count();

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
        $expensesTotal = (float) $expenses->sum('amount');

        $totalOrders = $orders->count();
        $completedCount = $completed->count();
        $completionRate = $totalOrders > 0 ? round(($completedCount / $totalOrders) * 100, 1) : 0.0;

        return [
            'month' => $month,
            'total_orders' => $totalOrders,
            'completed_orders' => $completedCount,
            'active_orders' => $active->count(),
            'cancelled_orders' => $cancelled->count(),
            'completion_rate' => $completionRate,
            'items_performed' => $itemsPerformed,
            'unique_patients' => $uniquePatients,
            'completed_patients' => $completedPatients,
            'new_users' => $newUsers,
            'gross_revenue' => $grossRevenue,
            'commission_total' => $commissionTotal,
            'provider_net' => $providerNet,
            'delivery_fees' => $deliveryFees,
            'discount_total' => $discountTotal,
            'discounted_orders' => $discountedOrders,
            'cash_revenue' => $cashRevenue,
            'online_revenue' => $onlineRevenue,
            'expenses_total' => $expensesTotal,
            'net_profit' => $commissionTotal - $expensesTotal,
        ];
    }

    private function classifyOrderService(Order $order): string
    {
        $st = strtolower(trim((string) ($order->service_type ?? '')));
        if (str_contains($st, 'lab') || str_contains($st, 'تاقیگە') || !empty($order->assigned_lab_id)) {
            return 'lab';
        }
        if (str_contains($st, 'nurs') || str_contains($st, 'پەرستار') || !empty($order->assigned_nurse_id)) {
            return 'nursing';
        }
        return 'other';
    }

    private function localMonth($dt): ?string
    {
        if (!$dt) {
            return null;
        }
        try {
            return Carbon::parse($dt)->timezone(self::TIMEZONE)->format('Y-m');
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function expenseMonth(Expense $expense): ?string
    {
        $date = $expense->expense_date ?? $expense->created_at;
        if (!$date) {
            return null;
        }
        try {
            return Carbon::parse($date)->format('Y-m');
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function safeCount(callable $fn): int
    {
        try {
            return (int) $fn();
        } catch (\Throwable $e) {
            return 0;
        }
    }
}

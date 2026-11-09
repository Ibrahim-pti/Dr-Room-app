<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminTransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = Transaction::with('user:id,name,phone')->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('method')) {
            $query->where('method', $request->method);
        }

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        if ($request->filled('search')) {
            $term = '%' . $request->search . '%';
            $query->where(fn ($q) => $q
                ->where('reference', 'like', $term)
                ->orWhere('description', 'like', $term)
                ->orWhereHas('user', fn ($u) => $u->where('name', 'like', $term)->orWhere('phone', 'like', $term)));
        }

        return $query->paginate((int)$request->input('per_page', 50));
    }

    /** Headline revenue figures for the payments screen. */
    public function summary()
    {
        $completed = Transaction::completed();

        return response()->json([
            'total_revenue'   => (float)(clone $completed)->sum('amount'),
            'today'           => (float)(clone $completed)->whereDate(DB::raw('COALESCE(paid_at, created_at)'), today())->sum('amount'),
            'this_month'      => (float)(clone $completed)->whereMonth(DB::raw('COALESCE(paid_at, created_at)'), now()->month)
                                                          ->whereYear(DB::raw('COALESCE(paid_at, created_at)'), now()->year)->sum('amount'),
            'transaction_count' => (clone $completed)->count(),
            'pending_count'   => Transaction::where('status', 'pending')->count(),
            'failed_count'    => Transaction::where('status', 'failed')->count(),
            'refunded_total'  => (float)Transaction::where('status', 'refunded')->sum('amount'),
            'by_method'       => Transaction::completed()
                ->select('method', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
                ->groupBy('method')
                ->get()
                ->map(fn ($row) => [
                    'method' => $row->method,
                    'label'  => Transaction::METHOD_LABELS[$row->method] ?? $row->method,
                    'total'  => (float)$row->total,
                    'count'  => (int)$row->count,
                ]),
            'last_7_days'     => Transaction::completed()
                ->where(DB::raw('COALESCE(paid_at, created_at)'), '>=', now()->subDays(6)->startOfDay())
                ->select(DB::raw('DATE(COALESCE(paid_at, created_at)) as day'), DB::raw('SUM(amount) as total'))
                ->groupBy('day')
                ->orderBy('day')
                ->get(),
        ]);
    }

    public function updateStatus(Request $request, string $id)
    {
        $request->validate([
            'status' => 'required|in:pending,completed,failed,refunded',
        ]);

        $transaction = Transaction::findOrFail($id);
        $before = $transaction->status;

        $transaction->update([
            'status'  => $request->status,
            'paid_at' => $request->status === 'completed' ? ($transaction->paid_at ?? now()) : $transaction->paid_at,
        ]);

        // Keep linked order payment_status in sync
        if ($transaction->payable_type === \App\Models\Order::class && $transaction->payable_id) {
            $order = \App\Models\Order::find($transaction->payable_id);
            if ($order) {
                if ($request->status === 'completed') {
                    $order->update(['payment_status' => 'paid']);
                } elseif ($request->status === 'refunded') {
                    $order->update(['payment_status' => 'refunded']);
                }
            }
        }

        ActivityLog::record('updated', $transaction, "مامەڵە {$transaction->reference}", [
            'from' => $before,
            'to'   => $request->status,
        ]);

        return response()->json($transaction);
    }

    /**
     * Generate an official monthly financial statement / invoice
     * broken down by provider or for all providers.
     */
    public function statement(Request $request)
    {
        $year = (int) ($request->input('year') ?: now()->year);
        $month = (int) ($request->input('month') ?: now()->month);
        $providerType = $request->input('provider_type', 'all'); // 'all', 'lab', 'nurse', 'pharmacy'
        $providerId = $request->input('provider_id');

        $startDate = \Carbon\Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endDate = $startDate->copy()->endOfMonth();

        $query = \App\Models\Order::with([
            'patient:id,name,phone',
            'assignedNurse:id,name,phone',
            'assignedLab:id,name,phone',
            'items'
        ])
        ->whereBetween('created_at', [$startDate, $endDate]);

        // Filter by status: include active/completed orders
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        } else {
            $query->whereIn('status', ['completed', 'accepted', 'pending']);
        }

        $providerName = 'تەواوی دابینکارەکان (گشتی)';
        $providerPhone = '+964 750 000 0000';
        $providerRole = 'سەکۆی فەرمی دکتۆر ڕۆم';

        if ($providerId && $providerType !== 'all') {
            $providerUser = \App\Models\User::find($providerId);
            if ($providerUser) {
                $providerName = $providerUser->name;
                $providerPhone = $providerUser->phone ?? '+964 750 000 0000';
                if ($providerType === 'nurse' || $providerUser->role === 'nurse') {
                    $providerRole = 'پەرستاری پەسەندکراو';
                    $query->where('assigned_nurse_id', $providerId);
                } elseif ($providerType === 'lab' || $providerUser->role === 'lab') {
                    $providerRole = 'تاقیگەی باوەڕپێکراو';
                    $query->where('assigned_lab_id', $providerId);
                } elseif ($providerType === 'pharmacy' || $providerUser->role === 'pharmacy') {
                    $providerRole = 'دەرمانخانەی هاوبەش';
                    $query->where('assigned_pharmacy_id', $providerId);
                }
            }
        } elseif ($providerType === 'nurse') {
            $providerRole = 'تەواوی پەرستارەکان';
            $query->where(fn($q) => $q->whereNotNull('assigned_nurse_id')->orWhere('service_type', 'home_nursing'));
        } elseif ($providerType === 'lab') {
            $providerRole = 'تەواوی تاقیگەکان';
            $query->where(fn($q) => $q->whereNotNull('assigned_lab_id')->orWhere('service_type', 'lab_test'));
        }

        $orders = $query->latest()->get();

        $totalOrders = $orders->count();
        $grossRevenue = (float) $orders->sum('total_price');

        $totalCommission = (float) $orders->sum(function ($order) {
            if ($order->commission_amount > 0) {
                return (float) $order->commission_amount;
            }
            return (float) ($order->total_price * 0.10);
        });

        $netPayout = max(0.0, $grossRevenue - $totalCommission);

        $kurdishMonths = [
            1 => 'کانوونی دووەم (١)',
            2 => 'شوبات (٢)',
            3 => 'ئازار (٣)',
            4 => 'نیسان (٤)',
            5 => 'ئایار (٥)',
            6 => 'حوزەیران (٦)',
            7 => 'تەممووز (٧)',
            8 => 'ئاب (٨)',
            9 => 'ئەیلوول (٩)',
            10 => 'تشرینی یەکەم (١٠)',
            11 => 'تشرینی دووەم (١١)',
            12 => 'کانوونی یەکەم (١٢)',
        ];

        $transactions = $orders->map(function ($order, $idx) {
            $comm = (float) ($order->commission_amount > 0 ? $order->commission_amount : $order->total_price * 0.10);
            $serviceName = 'خزمەتگوزاری پزیشکی';
            if ($order->items && $order->items->isNotEmpty()) {
                $serviceName = $order->items->pluck('item_name')->filter()->join('، ');
                if (empty($serviceName)) {
                    $serviceName = 'خزمەتگوزاری سەرەکی';
                }
            } elseif ($order->service_type === 'home_nursing') {
                $serviceName = 'پەرستاری لە ماڵەوە';
            } elseif ($order->service_type === 'lab_test') {
                $serviceName = 'پشکنینی تاقیگە';
            }

            return [
                'index' => $idx + 1,
                'id' => $order->id,
                'invoice_no' => 'INV-' . str_pad($order->id, 5, '0', STR_PAD_LEFT),
                'date' => $order->created_at ? $order->created_at->format('Y-m-d') : '',
                'patient_name' => $order->patient->name ?? 'نەخۆش',
                'service' => $serviceName,
                'amount' => (float) $order->total_price,
                'commission' => $comm,
                'net_payout' => max(0.0, (float) $order->total_price - $comm),
                'payment_method' => $order->payment_method ?? 'کاش',
                'status' => $order->payment_status ?? $order->status,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'statement_number' => 'DR-STMT-' . $year . str_pad($month, 2, '0', STR_PAD_LEFT) . '-' . ($providerId ?: 'ALL'),
                'generated_at' => now()->format('Y-m-d H:i'),
                'period' => [
                    'year' => $year,
                    'month' => $month,
                    'month_name' => $kurdishMonths[$month] ?? "مانگی $month",
                    'start_date' => $startDate->format('Y-m-d'),
                    'end_date' => $endDate->format('Y-m-d'),
                ],
                'provider' => [
                    'id' => $providerId,
                    'type' => $providerType,
                    'name' => $providerName,
                    'phone' => $providerPhone,
                    'role' => $providerRole,
                ],
                'summary' => [
                    'total_orders' => $totalOrders,
                    'gross_revenue' => $grossRevenue,
                    'commission_amount' => $totalCommission,
                    'net_payout' => $netPayout,
                ],
                'transactions' => $transactions,
            ],
        ]);
    }

    /**
     * Return list of providers (labs and nurses) for the filter dropdown
     */
    public function providers()
    {
        $labs = \App\Models\User::where('role', 'lab')
            ->select('id', 'name', 'phone')
            ->orderBy('name')
            ->get();

        $nurses = \App\Models\User::where('role', 'nurse')
            ->select('id', 'name', 'phone')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'labs' => $labs,
                'nurses' => $nurses,
            ],
        ]);
    }
}

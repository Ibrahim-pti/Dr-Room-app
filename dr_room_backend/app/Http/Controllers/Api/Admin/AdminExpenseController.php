<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Expense;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class AdminExpenseController extends Controller
{
    public const TIMEZONE = 'Asia/Baghdad';
    public const CATEGORIES = 'salaries,transport,lab_supplies,marketing,maintenance,rent,other';

    public function index(Request $request)
    {
        $query = Expense::with('creator:id,name');

        if ($request->filled('category') && $request->category !== 'all') {
            $query->where('category', $request->category);
        }

        if ($request->filled('search')) {
            $term = trim((string) $request->search);
            if ($term !== '') {
                $query->where(function ($q) use ($term) {
                    $q->where('title', 'like', "%{$term}%")
                      ->orWhere('notes', 'like', "%{$term}%");
                });
            }
        }

        if ($request->input('period') !== 'all' && $request->filled('month') && $request->filled('year')) {
            $query->whereMonth('expense_date', (int) $request->month)
                  ->whereYear('expense_date', (int) $request->year);
        }

        $perPage = max(1, min(200, (int) $request->input('per_page', 20)));
        $expenses = $query
            ->orderBy('expense_date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $expenses,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'required|string|in:' . self::CATEGORIES,
            'amount' => 'required|numeric|min:0.01',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
            'receipt' => 'nullable|file|mimes:jpg,jpeg,png,webp,pdf|max:10240',
        ]);

        $receiptPath = null;
        if ($request->hasFile('receipt')) {
            $receiptPath = $request->file('receipt')->store('expense_receipts', 'public');
        }

        $expense = Expense::create([
            'title' => $validated['title'],
            'category' => $validated['category'],
            'amount' => $validated['amount'],
            'currency' => 'IQD',
            'expense_date' => $validated['expense_date'],
            'notes' => $validated['notes'] ?? null,
            'receipt_path' => $receiptPath,
            'created_by' => Auth::id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'خەرجی بە سەرکەوتوویی تۆمارکرا',
            'data' => $expense->load('creator:id,name'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'required|string|in:' . self::CATEGORIES,
            'amount' => 'required|numeric|min:0.01',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
            'receipt' => 'nullable|file|mimes:jpg,jpeg,png,webp,pdf|max:10240',
            'remove_receipt' => 'nullable|boolean',
        ]);

        $updateData = [
            'title' => $validated['title'],
            'category' => $validated['category'],
            'amount' => $validated['amount'],
            'expense_date' => $validated['expense_date'],
            'notes' => $validated['notes'] ?? null,
        ];

        if ($request->hasFile('receipt')) {
            $this->deleteStoredReceipt($expense->receipt_path);
            $updateData['receipt_path'] = $request->file('receipt')->store('expense_receipts', 'public');
        } elseif ($request->boolean('remove_receipt')) {
            $this->deleteStoredReceipt($expense->receipt_path);
            $updateData['receipt_path'] = null;
        }

        $expense->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'خەرجی نوێکرایەوە',
            'data' => $expense->fresh()->load('creator:id,name'),
        ]);
    }

    public function destroy($id)
    {
        $expense = Expense::findOrFail($id);
        $this->deleteStoredReceipt($expense->receipt_path);
        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'خەرجی بە سەرکەوتوویی سڕایەوە',
        ]);
    }

    public function summary(Request $request)
    {
        $now = now(self::TIMEZONE);
        $isAll = $request->input('period') === 'all';
        $year = (int) $request->input('year', $now->year);
        $month = (int) $request->input('month', $now->month);

        $expensesQuery = Expense::query();
        $ordersQuery = Order::where('status', 'completed');

        if (!$isAll) {
            if ($request->filled('month') || !$request->filled('year')) {
                $month = max(1, min(12, $month));
                $expensesQuery->whereYear('expense_date', $year)
                              ->whereMonth('expense_date', $month);

                $startUtc = Carbon::create($year, $month, 1, 0, 0, 0, self::TIMEZONE)
                    ->startOfMonth()
                    ->utc();
                $endUtc = Carbon::create($year, $month, 1, 0, 0, 0, self::TIMEZONE)
                    ->endOfMonth()
                    ->utc();
                $ordersQuery->whereBetween('created_at', [$startUtc, $endUtc]);
            } else {
                $expensesQuery->whereYear('expense_date', $year);
                $startUtc = Carbon::create($year, 1, 1, 0, 0, 0, self::TIMEZONE)
                    ->startOfYear()
                    ->utc();
                $endUtc = Carbon::create($year, 12, 31, 23, 59, 59, self::TIMEZONE)
                    ->endOfYear()
                    ->utc();
                $ordersQuery->whereBetween('created_at', [$startUtc, $endUtc]);
            }
        }

        if ($request->filled('category') && $request->category !== 'all') {
            $expensesQuery->where('category', $request->category);
        }

        $totalExpenses = (float) (clone $expensesQuery)->sum('amount');
        $expensesCount = (int) (clone $expensesQuery)->count();

        $byCategory = (clone $expensesQuery)
            ->selectRaw('category, SUM(amount) as total_amount, COUNT(*) as count')
            ->groupBy('category')
            ->orderByDesc('total_amount')
            ->get()
            ->map(function ($row) use ($totalExpenses) {
                $amt = (float) $row->total_amount;
                return [
                    'category' => $row->category,
                    'total_amount' => $amt,
                    'count' => (int) $row->count,
                    'percent' => $totalExpenses > 0 ? round(($amt / $totalExpenses) * 100, 1) : 0.0,
                ];
            })
            ->values();

        $totalRevenue = (float) (clone $ordersQuery)->sum('total_price');
        $totalCommission = (float) (clone $ordersQuery)->sum('commission_amount');
        $completedOrdersCount = (int) (clone $ordersQuery)->count();

        $netProfit = $totalCommission - $totalExpenses;

        // Monthly budget cap (stored in AppSetting as monthly_budget_YYYY_MM with global default fallback)
        $monthlyBudget = 0.0;
        $budgetIsCustom = false;
        if (!$isAll) {
            [$monthlyBudget, $budgetIsCustom] = $this->budgetFor($year, $month);
        }

        $budgetRemaining = $monthlyBudget > 0 ? ($monthlyBudget - $totalExpenses) : 0.0;
        $budgetUsedPercent = $monthlyBudget > 0
            ? round(($totalExpenses / $monthlyBudget) * 100, 1)
            : 0.0;

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $isAll ? 'all' : sprintf('%04d-%02d', $year, $month),
                'total_expenses' => $totalExpenses,
                'expenses_count' => $expensesCount,
                'total_commission_revenue' => $totalCommission,
                'total_gross_volume' => $totalRevenue,
                'completed_orders_count' => $completedOrdersCount,
                'net_profit' => (float) $netProfit,
                'monthly_budget' => $monthlyBudget,
                'budget_is_custom' => $budgetIsCustom,
                'budget_remaining' => (float) $budgetRemaining,
                'budget_used_percent' => $budgetUsedPercent,
                'by_category' => $byCategory,
            ],
        ]);
    }

    public function setBudget(Request $request)
    {
        $now = now(self::TIMEZONE);
        $validated = $request->validate([
            'amount' => 'required|numeric|min:0',
            'year' => 'nullable|integer|min:2020|max:2100',
            'month' => 'nullable|integer|min:1|max:12',
            'apply_default' => 'nullable|boolean',
        ]);

        $year = (int) ($validated['year'] ?? $now->year);
        $month = (int) ($validated['month'] ?? $now->month);
        $amount = (float) $validated['amount'];

        $key = sprintf('monthly_budget_%04d_%02d', $year, $month);
        AppSetting::set($key, $amount, 'budget', "Monthly budget cap for {$year}-{$month}");

        $selected = Carbon::create($year, $month, 1, 0, 0, 0, self::TIMEZONE)->startOfMonth();
        if (($validated['apply_default'] ?? false) || $selected->greaterThanOrEqualTo($now->copy()->startOfMonth())) {
            AppSetting::set('monthly_budget_default', $amount, 'budget', 'Default monthly budget cap');
        }

        return response()->json([
            'success' => true,
            'message' => 'بودجەی مانگانە پاشەکەوتکرا',
            'data' => [
                'year' => $year,
                'month' => $month,
                'monthly_budget' => $amount,
            ],
        ]);
    }

    /** @return array{0: float, 1: bool} */
    private function budgetFor(int $year, int $month): array
    {
        $key = sprintf('monthly_budget_%04d_%02d', $year, $month);
        $custom = AppSetting::get($key);
        if ($custom !== null && $custom !== '') {
            return [(float) $custom, true];
        }

        $default = AppSetting::get('monthly_budget_default', 0);
        return [(float) ($default ?: 0), false];
    }

    private function deleteStoredReceipt(?string $path): void
    {
        if (empty($path) || str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return;
        }
        $relative = ltrim($path, '/');
        if (Storage::disk('public')->exists($relative)) {
            Storage::disk('public')->delete($relative);
        }
    }
}

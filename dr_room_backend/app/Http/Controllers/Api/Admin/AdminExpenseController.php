<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminExpenseController extends Controller
{
    public function index(Request $request)
    {
        $query = Expense::with('creator:id,name');

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('month') && $request->filled('year')) {
            $query->whereMonth('expense_date', $request->month)
                  ->whereYear('expense_date', $request->year);
        }

        $expenses = $query->orderBy('expense_date', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $expenses,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'required|string|in:salaries,transport,lab_supplies,marketing,maintenance,rent,other',
            'amount' => 'required|numeric|min:0.01',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
            'receipt' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:10240',
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
            'category' => 'required|string|in:salaries,transport,lab_supplies,marketing,maintenance,rent,other',
            'amount' => 'required|numeric|min:0.01',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
            'receipt' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:10240',
        ]);

        if ($request->hasFile('receipt')) {
            $validated['receipt_path'] = $request->file('receipt')->store('expense_receipts', 'public');
        }

        $expense->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'خەرجی نوێکرایەوە',
            'data' => $expense,
        ]);
    }

    public function destroy($id)
    {
        $expense = Expense::findOrFail($id);
        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'خەرجی بە سەرکەوتوویی سڕایەوە',
        ]);
    }

    public function summary(Request $request)
    {
        $year = $request->get('year', now()->year);
        $month = $request->get('month', now()->month);

        $expensesQuery = Expense::whereYear('expense_date', $year);
        if ($request->filled('month')) {
            $expensesQuery->whereMonth('expense_date', $month);
        }

        $totalExpenses = (clone $expensesQuery)->sum('amount');

        $byCategory = (clone $expensesQuery)
            ->selectRaw('category, SUM(amount) as total_amount, COUNT(*) as count')
            ->groupBy('category')
            ->get();

        // Calculate Revenue for the same period
        $ordersQuery = Order::where('status', 'completed')->whereYear('created_at', $year);
        if ($request->filled('month')) {
            $ordersQuery->whereMonth('created_at', $month);
        }

        $totalRevenue = (clone $ordersQuery)->sum('total_price');
        $totalCommission = (clone $ordersQuery)->sum('commission_amount');
        if ($totalCommission <= 0) {
            // fallback if commissions were not tracked historically
            $totalCommission = $totalRevenue * 0.10;
        }

        $netProfit = $totalCommission - $totalExpenses;

        return response()->json([
            'success' => true,
            'data' => [
                'total_expenses' => (float) $totalExpenses,
                'total_commission_revenue' => (float) $totalCommission,
                'total_gross_volume' => (float) $totalRevenue,
                'net_profit' => (float) $netProfit,
                'by_category' => $byCategory,
            ]
        ]);
    }
}


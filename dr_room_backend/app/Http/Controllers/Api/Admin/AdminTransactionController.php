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
            'today'           => (float)(clone $completed)->whereDate('created_at', today())->sum('amount'),
            'this_month'      => (float)(clone $completed)->whereMonth('created_at', now()->month)
                                                          ->whereYear('created_at', now()->year)->sum('amount'),
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
                ->where('created_at', '>=', now()->subDays(6)->startOfDay())
                ->select(DB::raw('DATE(created_at) as day'), DB::raw('SUM(amount) as total'))
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

        ActivityLog::record('updated', $transaction, "مامەڵە {$transaction->reference}", [
            'from' => $before,
            'to'   => $request->status,
        ]);

        return response()->json($transaction);
    }
}

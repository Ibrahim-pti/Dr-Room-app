<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class LabDashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $lab = $user->lab;

        // lab_results is still an id + timestamps shell — no lab_id, no status,
        // no patient. Until that migration lands there is nothing real to count,
        // and the dashboard must show zeros rather than invent numbers.
        $schemaReady = Schema::hasColumn('lab_results', 'status');

        $todayRequests = 0;
        $completedTests = 0;
        $pendingTests = 0;
        $recentRequests = collect();

        if ($schemaReady) {
            $scoped = fn() => LabResult::where('lab_id', $user->id);

            $todayRequests = $scoped()->whereDate('created_at', today())->count();
            $completedTests = $scoped()->where('status', 'completed')->count();
            $pendingTests = $scoped()->whereIn('status', ['pending', 'in_progress'])->count();

            $recentRequests = $scoped()->with('patient')->latest()->take(5)->get();
        }

        return view('lab.dashboard.index', compact(
            'user',
            'lab',
            'schemaReady',
            'todayRequests',
            'completedTests',
            'pendingTests',
            'recentRequests'
        ));
    }
}

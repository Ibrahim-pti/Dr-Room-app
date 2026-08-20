<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\LabReview;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class LabDashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $lab = $user->lab;

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

        $viewsCount = $lab ? ($lab->views_count ?? 0) : 0;
        $totalReviews = $lab ? $lab->reviews()->count() : 0;
        $avgRating = $lab ? $lab->reviews()->avg('rating') : null;
        $rating = $avgRating ? round($avgRating, 1) : ($lab?->rating ?? 5.0);

        $recentReviews = $lab ? $lab->reviews()->with('patient:id,name,profile_image')->latest()->take(4)->get() : collect();

        return view('lab.dashboard.index', compact(
            'user',
            'lab',
            'schemaReady',
            'todayRequests',
            'completedTests',
            'pendingTests',
            'recentRequests',
            'viewsCount',
            'totalReviews',
            'rating',
            'recentReviews'
        ));
    }
}

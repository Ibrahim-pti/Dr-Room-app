<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

class NurseReviewController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;

        if (! $nurse) {
            return view('nurse.reviews.index', [
                'nurse' => null,
                'reviews' => collect(),
                'breakdown' => [],
            ]);
        }

        $reviews = $nurse->reviews()
            ->with('patient:id,name')
            ->latest()
            ->paginate(15);

        // Counts per star, used for the distribution bars.
        $counts = $nurse->reviews()
            ->selectRaw('rating, COUNT(*) as total')
            ->groupBy('rating')
            ->pluck('total', 'rating');

        $breakdown = [];
        foreach (range(5, 1) as $star) {
            $breakdown[$star] = (int) ($counts[$star] ?? 0);
        }

        return view('nurse.reviews.index', compact('nurse', 'reviews', 'breakdown'));
    }
}

<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabReviewController extends Controller
{
    public function index()
    {
        $lab = Auth::user()->lab;
        if (!$lab) {
            return redirect()->route('lab.profile.index')->with('error', 'تکایە سەرەتا پرۆفایلی تاقیگەکەت تەواو بکە.');
        }

        $reviews = $lab->reviews()
            ->with('patient:id,name,profile_image,phone')
            ->latest()
            ->paginate(15);

        // Calculate breakdown
        $breakdown = [];
        $totalReviews = $lab->reviews()->count();
        foreach (range(5, 1) as $star) {
            $count = $lab->reviews()->where('rating', $star)->count();
            $percentage = $totalReviews > 0 ? round(($count / $totalReviews) * 100) : 0;
            $breakdown[$star] = [
                'count' => $count,
                'percentage' => $percentage,
            ];
        }

        $avgRating = $lab->reviews()->avg('rating');
        $rating = $avgRating ? round($avgRating, 1) : 5.0;
        $viewsCount = $lab->views_count ?? 0;

        return view('lab.reviews.index', compact('lab', 'reviews', 'breakdown', 'rating', 'totalReviews', 'viewsCount'));
    }
}

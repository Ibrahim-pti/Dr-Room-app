<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Nurse;
use App\Models\NurseReview;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseReviewController extends Controller
{
    /** Public list of reviews for one nurse, newest first. */
    public function index($nurseId)
    {
        $nurse = Nurse::findOrFail($nurseId);

        $reviews = $nurse->reviews()
            ->with('patient:id,name')
            ->latest()
            ->get()
            ->map(fn ($review) => [
                'id'           => $review->id,
                'rating'       => $review->rating,
                'comment'      => $review->comment,
                'patient_name' => $review->patient?->name,
                'created_at'   => $review->created_at?->toIso8601String(),
            ]);

        // Star breakdown the app draws as bars (5 → 1).
        $breakdown = [];
        foreach (range(5, 1) as $star) {
            $breakdown[$star] = $nurse->reviews()->where('rating', $star)->count();
        }

        return response()->json([
            'rating'        => (float) $nurse->rating,
            'total_reviews' => $nurse->total_reviews,
            'breakdown'     => $breakdown,
            'reviews'       => $reviews,
        ]);
    }

    /**
     * Creates or replaces the signed-in patient's review for this nurse.
     * The unique index means a second submission edits the first.
     */
    public function store(Request $request, $nurseId)
    {
        $nurse = Nurse::findOrFail($nurseId);

        $data = $request->validate([
            'rating'  => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review = NurseReview::updateOrCreate(
            ['nurse_id' => $nurse->id, 'patient_id' => Auth::id()],
            ['rating' => $data['rating'], 'comment' => $data['comment'] ?? null],
        );

        $nurse->refreshRating();

        return response()->json([
            'message'       => 'Review saved',
            'review'        => $review,
            'rating'        => (float) $nurse->fresh()->rating,
            'total_reviews' => $nurse->fresh()->total_reviews,
        ], 201);
    }
}

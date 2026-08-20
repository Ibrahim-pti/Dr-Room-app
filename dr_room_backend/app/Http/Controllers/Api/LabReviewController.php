<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lab;
use App\Models\LabReview;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabReviewController extends Controller
{
    /**
     * Public list of reviews for one lab, newest first.
     */
    public function index($labId)
    {
        $lab = Lab::where('id', $labId)
            ->orWhere('user_id', $labId)
            ->firstOrFail();

        $reviews = $lab->reviews()
            ->with('patient:id,name,profile_image')
            ->latest()
            ->get()
            ->map(fn ($review) => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'patient_name' => $review->patient?->name ?? 'نەخۆش',
                'patient_image' => $review->patient?->profile_image ? asset('storage/' . $review->patient->profile_image) : null,
                'created_at' => $review->created_at?->toIso8601String(),
                'formatted_date' => $review->created_at?->diffForHumans(),
            ]);

        // The star breakdown (5 → 1)
        $breakdown = [];
        foreach (range(5, 1) as $star) {
            $breakdown[$star] = $lab->reviews()->where('rating', $star)->count();
        }

        return response()->json([
            'success' => true,
            'rating' => (float) ($lab->rating ?? 5.0),
            'total_reviews' => (int) ($lab->total_reviews ?? $reviews->count()),
            'views_count' => (int) ($lab->views_count ?? 0),
            'breakdown' => $breakdown,
            'reviews' => $reviews,
        ]);
    }

    /**
     * Submit or update signed-in patient's review for this lab.
     */
    public function store(Request $request, $labId)
    {
        $lab = Lab::where('id', $labId)
            ->orWhere('user_id', $labId)
            ->firstOrFail();

        $data = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $userId = Auth::id();
        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
        }

        $review = LabReview::updateOrCreate(
            ['lab_id' => $lab->id, 'patient_id' => $userId],
            ['rating' => $data['rating'], 'comment' => $data['comment'] ?? null]
        );

        $lab->recalculateRating();

        return response()->json([
            'success' => true,
            'message' => 'هەڵسەنگاندنەکەت بە سەرکەوتوویی تۆمارکرا.',
            'data' => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'lab_rating' => (float) $lab->fresh()->rating,
                'total_reviews' => (int) $lab->fresh()->total_reviews,
            ],
        ]);
    }
}

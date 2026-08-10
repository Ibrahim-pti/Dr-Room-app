<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Doctor;
use App\Models\DoctorReview;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorReviewController extends Controller
{
    /** Public list of reviews for one doctor, newest first. */
    public function index($doctorId)
    {
        $doctor = Doctor::findOrFail($doctorId);

        $reviews = $doctor->reviews()
            ->with('patient:id,name')
            ->latest()
            ->get()
            ->map(fn ($review) => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'patient_name' => $review->patient?->name,
                'created_at' => $review->created_at?->toIso8601String(),
            ]);

        // The star breakdown the app draws as bars (5 → 1).
        $breakdown = [];
        foreach (range(5, 1) as $star) {
            $breakdown[$star] = $doctor->reviews()->where('rating', $star)->count();
        }

        return response()->json([
            'rating' => (float) $doctor->rating,
            'total_reviews' => $doctor->total_reviews,
            'breakdown' => $breakdown,
            'reviews' => $reviews,
        ]);
    }

    /**
     * Creates or replaces the signed-in patient's review for this doctor.
     * The unique index means a second submission edits the first.
     */
    public function store(Request $request, $doctorId)
    {
        $doctor = Doctor::findOrFail($doctorId);

        $data = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review = DoctorReview::updateOrCreate(
            ['doctor_id' => $doctor->id, 'patient_id' => Auth::id()],
            ['rating' => $data['rating'], 'comment' => $data['comment'] ?? null],
        );

        $doctor->refreshRating();

        return response()->json([
            'message' => 'Review saved',
            'review' => $review,
            'rating' => (float) $doctor->fresh()->rating,
            'total_reviews' => $doctor->fresh()->total_reviews,
        ], 201);
    }
}

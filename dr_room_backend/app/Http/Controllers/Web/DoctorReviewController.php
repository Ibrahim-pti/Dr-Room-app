<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

class DoctorReviewController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;

        if (! $doctor) {
            return view('doctor.reviews.index', [
                'doctor' => null,
                'reviews' => collect(),
                'breakdown' => [],
            ]);
        }

        $reviews = $doctor->reviews()
            ->with('patient:id,name')
            ->latest()
            ->paginate(15);

        // Counts per star, used for the distribution bars.
        $counts = $doctor->reviews()
            ->selectRaw('rating, COUNT(*) as total')
            ->groupBy('rating')
            ->pluck('total', 'rating');

        $breakdown = [];
        foreach (range(5, 1) as $star) {
            $breakdown[$star] = (int) ($counts[$star] ?? 0);
        }

        return view('doctor.reviews.index', compact('doctor', 'reviews', 'breakdown'));
    }
}

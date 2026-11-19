<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeedbackResponse;
use App\Models\FeedbackSurvey;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminFeedbackController extends Controller
{
    public function index()
    {
        $surveys = FeedbackSurvey::withCount('responses')
            ->withAvg('responses', 'rating')
            ->with(['responses' => function ($q) {
                $q->with('user:id,name,phone')->latest('id')->limit(30);
            }])
            ->latest('id')
            ->get();

        $totalResponses = FeedbackResponse::count();
        $overallAvg = $totalResponses > 0
            ? round((float) FeedbackResponse::avg('rating'), 2)
            : 0.0;

        return response()->json([
            'success' => true,
            'stats' => [
                'total_surveys' => $surveys->count(),
                'active_surveys' => $surveys->where('is_active', true)->count(),
                'total_responses' => $totalResponses,
                'overall_avg_rating' => $overallAvg,
            ],
            'data' => $surveys,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'title_kmr' => 'nullable|string|max:255',
            'title_ar' => 'nullable|string|max:255',
            'title_en' => 'nullable|string|max:255',
            'rating_question' => 'required|string|max:500',
            'rating_question_kmr' => 'nullable|string|max:500',
            'rating_question_ar' => 'nullable|string|max:500',
            'rating_question_en' => 'nullable|string|max:500',
            'suggestion_question' => 'required|string|max:500',
            'suggestion_question_kmr' => 'nullable|string|max:500',
            'suggestion_question_ar' => 'nullable|string|max:500',
            'suggestion_question_en' => 'nullable|string|max:500',
            'is_active' => 'boolean',
        ]);

        $validated['created_by'] = Auth::id();
        $validated['is_active'] = $request->has('is_active') ? $request->boolean('is_active') : true;

        $survey = FeedbackSurvey::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'فیدباک بە سەرکەوتوویی دروستکرا',
            'data' => $survey,
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $survey = FeedbackSurvey::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'title_kmr' => 'nullable|string|max:255',
            'title_ar' => 'nullable|string|max:255',
            'title_en' => 'nullable|string|max:255',
            'rating_question' => 'required|string|max:500',
            'rating_question_kmr' => 'nullable|string|max:500',
            'rating_question_ar' => 'nullable|string|max:500',
            'rating_question_en' => 'nullable|string|max:500',
            'suggestion_question' => 'required|string|max:500',
            'suggestion_question_kmr' => 'nullable|string|max:500',
            'suggestion_question_ar' => 'nullable|string|max:500',
            'suggestion_question_en' => 'nullable|string|max:500',
            'is_active' => 'boolean',
        ]);

        $survey->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'فیدباک نوێکرایەوە',
            'data' => $survey,
        ]);
    }

    public function toggleStatus(int $id)
    {
        $survey = FeedbackSurvey::findOrFail($id);
        $survey->is_active = !$survey->is_active;
        $survey->save();

        return response()->json([
            'success' => true,
            'message' => $survey->is_active ? 'فیدباک چالاک کرا' : 'فیدباک ناچالاک کرا',
            'is_active' => $survey->is_active,
        ]);
    }

    public function destroy(int $id)
    {
        $survey = FeedbackSurvey::findOrFail($id);
        $survey->delete();

        return response()->json([
            'success' => true,
            'message' => 'فیدباک سڕایەوە',
        ]);
    }

    public function responses(int $id)
    {
        $survey = FeedbackSurvey::findOrFail($id);
        $responses = $survey->responses()
            ->with('user:id,name,phone')
            ->latest('id')
            ->get();

        $distribution = [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0];
        foreach ($responses as $r) {
            $star = (int) $r->rating;
            if (isset($distribution[$star])) {
                $distribution[$star]++;
            }
        }

        return response()->json([
            'success' => true,
            'survey' => $survey,
            'distribution' => $distribution,
            'avg_rating' => $responses->count() > 0 ? round((float) $responses->avg('rating'), 2) : 0.0,
            'data' => $responses,
        ]);
    }
}

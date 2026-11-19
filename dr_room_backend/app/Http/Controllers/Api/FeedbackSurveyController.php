<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FeedbackResponse;
use App\Models\FeedbackSurvey;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FeedbackSurveyController extends Controller
{
    /**
     * Return the latest active survey that the authenticated user has not yet answered.
     */
    public function active()
    {
        $userId = Auth::id();

        $survey = FeedbackSurvey::query()
            ->where('is_active', true)
            ->whereDoesntHave('responses', function ($q) use ($userId) {
                $q->where('user_id', $userId);
            })
            ->latest('id')
            ->first();

        return response()->json([
            'success' => true,
            'data' => $survey,
        ]);
    }

    /**
     * Submit a user's one-time response to an active feedback survey.
     */
    public function respond(Request $request, int $id)
    {
        $survey = FeedbackSurvey::findOrFail($id);

        if (!$survey->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'ئەم فیدباکە لە ئێستادا ناچالاکە',
            ], 422);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'is_satisfied' => 'nullable|string|in:satisfied,neutral,unsatisfied',
            'suggestion' => 'nullable|string|max:2000',
            'locale' => 'nullable|string|max:10',
        ]);

        $userId = Auth::id();

        $response = FeedbackResponse::firstOrCreate(
            [
                'survey_id' => $survey->id,
                'user_id' => $userId,
            ],
            [
                'rating' => $validated['rating'],
                'is_satisfied' => $validated['is_satisfied'] ?? null,
                'suggestion' => isset($validated['suggestion']) ? trim($validated['suggestion']) : null,
                'locale' => $validated['locale'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'سوپاس بۆ ناردنی هەڵسەنگاندنەکەت!',
            'data' => $response,
        ], 201);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PillVisionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PillIdentifierController extends Controller
{
    /**
     * Identify a pill/medicine from a photo.
     *
     * The app sends the photo as base64 (not multipart) because that's the
     * exact shape the vision APIs expect inline, so it's forwarded as-is
     * instead of being decoded and re-encoded.
     *
     * The actual work — and the fallback between AI providers when one runs
     * out of free quota — lives in PillVisionService.
     */
    public function identify(Request $request, PillVisionService $vision): JsonResponse
    {
        $request->validate([
            'image_base64' => 'required|string',
        ]);

        if (!$vision->hasConfiguredProvider()) {
            return response()->json([
                'error' => 'AI service is not configured. Add GEMINI_API_KEY (or GROQ_API_KEY / MISTRAL_API_KEY) to the backend .env file.',
            ], 503);
        }

        $outcome = $vision->identify($request->input('image_base64'));

        if ($outcome === null) {
            return response()->json([
                'error' => 'The AI services are busy or unavailable right now. Try again, or search the medicine by name.',
            ], 502);
        }

        // The provider is reported so a wrong answer can be traced back to
        // whichever model produced it.
        return response()->json($outcome['result'] + ['provider' => $outcome['provider']]);
    }
}

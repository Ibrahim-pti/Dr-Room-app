<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PillIdentifierController extends Controller
{
    /**
     * Identify a pill/medicine from a photo using Gemini Vision.
     *
     * The app sends the photo as base64 (not multipart) because that's the
     * exact shape Gemini's inline_data expects, so it's forwarded as-is
     * instead of being decoded and re-encoded.
     */
    public function identify(Request $request)
    {
        $request->validate([
            'image_base64' => 'required|string',
        ]);

        $apiKey = config('services.gemini.key');
        if (!$apiKey) {
            return response()->json([
                'error' => 'AI service is not configured. Add GEMINI_API_KEY to the backend .env file.',
            ], 503);
        }

        $prompt = <<<PROMPT
You are a pharmaceutical visual identification assistant embedded in a healthcare app.
Look at the attached photo of a pill, tablet, or medicine box/label and try to identify it.

Respond with ONLY strict JSON (no markdown fences) matching exactly this shape:
{
  "identified": boolean,
  "name": string,
  "category": string,
  "common_uses": string,
  "typical_dosage": string,
  "warnings": string,
  "confidence": "low" | "medium" | "high"
}

Rules:
- Never invent a specific medicine name unless you can actually read text on the packaging or clearly recognize the pill's imprint/shape/color combination.
- If you cannot confidently identify it, set "identified" to false, "confidence" to "low", and use the other string fields to briefly explain why (e.g. "Image is blurry, please retake in better light") instead of guessing.
- "typical_dosage" and "warnings" must be general reference information only, not a personal prescription.
PROMPT;

        try {
            $response = Http::timeout(30)->post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}",
                [
                    'contents' => [[
                        'parts' => [
                            ['text' => $prompt],
                            ['inline_data' => [
                                'mime_type' => 'image/jpeg',
                                'data' => $request->input('image_base64'),
                            ]],
                        ],
                    ]],
                    'generationConfig' => [
                        'response_mime_type' => 'application/json',
                        'temperature' => 0.2,
                    ],
                ]
            );

            if (!$response->successful()) {
                Log::error('Gemini pill identify request failed', ['body' => $response->body()]);
                return response()->json(['error' => 'The AI service request failed. Please try again.'], 502);
            }

            $text = $response->json('candidates.0.content.parts.0.text');
            $parsed = is_string($text) ? json_decode($text, true) : null;

            if (!is_array($parsed)) {
                Log::error('Gemini pill identify returned unparseable text', ['text' => $text]);
                return response()->json(['error' => 'The AI returned an unexpected response.'], 502);
            }

            return response()->json($parsed);
        } catch (\Throwable $e) {
            Log::error('Gemini pill identify exception', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Could not reach the AI service.'], 502);
        }
    }
}

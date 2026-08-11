<?php

namespace App\Services;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Identifies a medicine from a photo, trying each configured AI provider in
 * turn.
 *
 * Every provider here has a free tier, and each one caps how many requests a
 * day it will answer. Chaining them means running out of quota on one does not
 * take the scanner down — the next one picks the request up.
 *
 * A provider is only skipped over when the *call* fails (no key, quota
 * exhausted, timeout, malformed reply). A provider that answers properly with
 * "I cannot identify this" has done its job, and asking the next one the same
 * question about the same blurry photo would only cost the patient time.
 */
class PillVisionService
{
    /**
     * Kept below the app's own 30s request timeout so that even a couple of
     * dead providers still leave room for a live one to answer.
     */
    private const TIMEOUT_SECONDS = 12;

    private const PROMPT = <<<PROMPT
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

    /**
     * @return array{result: array<string, mixed>, provider: string}|null
     *         null when no provider could be reached at all.
     */
    public function identify(string $base64Image): ?array
    {
        $attempted = false;

        foreach ($this->providers() as $name => $provider) {
            $keys = $this->keys($provider);

            // Several keys for one provider multiply the daily allowance: when
            // the first is out of quota for the day the next one carries on.
            foreach ($keys as $index => $key) {
                $attempted = true;
                $withKey = ['key' => $key] + $provider;

                $parsed = $name === 'gemini'
                    ? $this->callGemini($withKey, $base64Image)
                    : $this->callOpenAiCompatible($name, $withKey, $base64Image);

                if ($parsed !== null) {
                    return [
                        'result' => $parsed,
                        'provider' => count($keys) > 1 ? $name . '#' . ($index + 1) : $name,
                    ];
                }
            }
        }

        if (!$attempted) {
            Log::warning('Pill identify called with no AI provider configured');
        }

        return null;
    }

    /** True when at least one provider has a key, so the API can say so. */
    public function hasConfiguredProvider(): bool
    {
        foreach ($this->providers() as $provider) {
            if ($this->keys($provider) !== []) {
                return true;
            }
        }

        return false;
    }

    /**
     * A provider's key setting may hold several comma-separated keys.
     *
     * @param array<string, mixed> $provider
     * @return list<string>
     */
    private function keys(array $provider): array
    {
        return array_values(array_filter(
            array_map('trim', explode(',', (string) ($provider['key'] ?? '')))
        ));
    }

    /**
     * Providers in the order they should be tried. Gemini leads because its
     * free tier is both the largest and the strongest at reading packaging.
     *
     * @return array<string, array<string, mixed>>
     */
    private function providers(): array
    {
        return [
            'gemini' => config('services.gemini'),
            'groq' => config('services.groq'),
            'mistral' => config('services.mistral'),
        ];
    }

    /**
     * @param array<string, mixed> $provider
     * @return array<string, mixed>|null
     */
    private function callGemini(array $provider, string $base64Image): ?array
    {
        $model = $provider['vision_model'];

        try {
            // The key goes in the header rather than the query string: the
            // ?key= form answers an unrelated 404 for models a project cannot
            // use, which hides the real reason a call was refused.
            $response = Http::withHeaders(['x-goog-api-key' => $provider['key']])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post(
                "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent",
                [
                    'contents' => [[
                        'parts' => [
                            ['text' => self::PROMPT],
                            ['inline_data' => [
                                'mime_type' => 'image/jpeg',
                                'data' => $base64Image,
                            ]],
                        ],
                    ]],
                    'generationConfig' => [
                        'response_mime_type' => 'application/json',
                        'temperature' => 0.2,
                    ],
                ]
            );
        } catch (\Throwable $e) {
            Log::warning('gemini pill identify threw', ['message' => $e->getMessage()]);
            return null;
        }

        if (!$this->succeeded('gemini', $response)) {
            return null;
        }

        return $this->decode('gemini', $response->json('candidates.0.content.parts.0.text'));
    }

    /**
     * Groq and Mistral both speak the OpenAI chat-completions dialect, so one
     * method covers both — only the host, model and key differ.
     *
     * @param array<string, mixed> $provider
     * @return array<string, mixed>|null
     */
    private function callOpenAiCompatible(string $name, array $provider, string $base64Image): ?array
    {
        try {
            $response = Http::withToken($provider['key'])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post($provider['endpoint'], [
                    'model' => $provider['vision_model'],
                    'messages' => [[
                        'role' => 'user',
                        'content' => [
                            ['type' => 'text', 'text' => self::PROMPT],
                            ['type' => 'image_url', 'image_url' => [
                                'url' => 'data:image/jpeg;base64,' . $base64Image,
                            ]],
                        ],
                    ]],
                    'response_format' => ['type' => 'json_object'],
                    'temperature' => 0.2,
                ]);
        } catch (\Throwable $e) {
            Log::warning("{$name} pill identify threw", ['message' => $e->getMessage()]);
            return null;
        }

        if (!$this->succeeded($name, $response)) {
            return null;
        }

        return $this->decode($name, $response->json('choices.0.message.content'));
    }

    private function succeeded(string $name, Response $response): bool
    {
        if ($response->successful()) {
            return true;
        }

        // 429 is the everyday case this whole chain exists for, so it is logged
        // as information rather than as a fault.
        Log::log(
            $response->status() === 429 ? 'info' : 'error',
            "{$name} pill identify request failed",
            ['status' => $response->status(), 'body' => $response->body()]
        );

        return false;
    }

    /**
     * Models occasionally wrap their JSON in a markdown fence despite being
     * asked not to, so the fence is stripped before decoding.
     *
     * @return array<string, mixed>|null
     */
    private function decode(string $name, mixed $text): ?array
    {
        if (!is_string($text)) {
            Log::error("{$name} pill identify returned no text");
            return null;
        }

        $text = trim($text);
        $text = preg_replace('/^```(?:json)?\s*|\s*```$/i', '', $text) ?? $text;

        $parsed = json_decode($text, true);

        if (!is_array($parsed) || !array_key_exists('identified', $parsed)) {
            Log::error("{$name} pill identify returned unparseable text", ['text' => $text]);
            return null;
        }

        return $parsed;
    }
}

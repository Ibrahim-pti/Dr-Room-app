<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Stichoza\GoogleTranslate\GoogleTranslate;

class TranslationService
{
    /**
     * Translates a single string into a target language with multiple failover providers.
     *
     * @param string $text The text to translate.
     * @param string $target Target language code (e.g. 'en', 'ar', 'ku').
     * @param string $source Source language code (defaults to 'ckb' for Kurdish Sorani).
     * @return string
     */
    public static function translate(string $text, string $target, string $source = 'ckb'): string
    {
        $text = trim($text);
        if ($text === '') {
            return '';
        }

        if (strtolower($source) === strtolower($target)) {
            return $text;
        }

        // Provider 1: MyMemory Translated API (Reliable, fast, supports ckb)
        try {
            $url = 'https://api.mymemory.translated.net/get?q=' . urlencode($text) . '&langpair=' . urlencode($source) . '|' . urlencode($target);
            $response = Http::timeout(6)->get($url);
            if ($response->successful()) {
                $json = $response->json();
                $translated = $json['responseData']['translatedText'] ?? null;
                if (!empty($translated) 
                    && stripos($translated, 'MYMEMORY WARNING') === false
                    && stripos($translated, 'PLEASE SELECT TWO DISTINCT LANGUAGES') === false
                    && stripos($translated, 'IS AN INVALID TARGET LANGUAGE') === false) {
                    $decoded = html_entity_decode(trim($translated), ENT_QUOTES | ENT_HTML5, 'UTF-8');
                    if (!empty($decoded)) {
                        return $decoded;
                    }
                }
            }
        } catch (\Throwable $e) {
            Log::warning('TranslationService: MyMemory failed: ' . $e->getMessage());
        }

        // Provider 2: Stichoza GoogleTranslate
        try {
            $tr = new GoogleTranslate($target);
            $tr->setSource($source);
            $translated = $tr->translate($text);
            if (!empty($translated)) {
                return trim($translated);
            }
        } catch (\Throwable $e) {
            try {
                $trAuto = new GoogleTranslate($target);
                $translated = $trAuto->translate($text);
                if (!empty($translated)) {
                    return trim($translated);
                }
            } catch (\Throwable $e2) {
                Log::warning('TranslationService: GoogleTranslate failed: ' . $e2->getMessage());
            }
        }

        // Fallback: return original text
        return $text;
    }
}

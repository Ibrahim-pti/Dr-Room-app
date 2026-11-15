<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Stichoza\GoogleTranslate\GoogleTranslate;

class TranslationService
{
    /**
     * Translates a single string into a target language using Google Translate.
     *
     * @param string $text The text to translate.
     * @param string $target Target language code (e.g. 'en', 'ar', 'ku', 'kmr', 'ckb').
     * @param string $source Source language code (defaults to 'ckb' for Kurdish Sorani).
     * @return string
     */
    public static function translate(string $text, string $target, string $source = 'ckb'): string
    {
        $text = trim($text);
        if ($text === '') {
            return '';
        }

        $normTarget = strtolower($target);
        $normSource = strtolower($source);

        if ($normSource === $normTarget) {
            return $text;
        }

        $isBadini = in_array($normTarget, ['kmr', 'ku', 'badini'], true);
        $actualTarget = $isBadini ? 'ku' : $normTarget;

        $translated = self::translateViaClients5($text, $actualTarget, $source);

        if ($translated === '') {
            $translated = self::translateViaStichoza($text, $actualTarget, $source);
        }

        if ($isBadini && $translated !== '') {
            if (preg_match('/[a-zA-ZçÇêÊîÎşŞûÛ]/u', $translated)) {
                return self::hawarToKurdishArabic($translated);
            }
            return $translated;
        }

        return $translated !== '' ? $translated : $text;
    }

    /**
     * Primary Google Translate endpoint (`clients5.google.com/translate_a/t`),
     * which avoids the 429 rate-limits common on `translate.google.com` from server IPs.
     */
    private static function translateViaClients5(string $text, string $target, string $source): string
    {
        try {
            $curlOpts = defined('CURLOPT_IPRESOLVE') && defined('CURL_IPRESOLVE_V4')
                ? [CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4]
                : [];

            $response = Http::timeout(5)
                ->connectTimeout(3)
                ->withHeaders(['User-Agent' => 'Mozilla/5.0'])
                ->withOptions($curlOpts !== [] ? ['curl' => $curlOpts] : [])
                ->get('https://clients5.google.com/translate_a/t', [
                    'client' => 'dict-chrome-ex',
                    'sl'     => $source ?: 'auto',
                    'tl'     => $target,
                    'q'      => $text,
                ]);

            if (!$response->successful()) {
                return '';
            }

            $json = $response->json();
            if (!is_array($json) || $json === []) {
                return '';
            }

            // Format is either ["translated"] (explicit sl) or [["translated", "detected_sl"], ...] (auto sl)
            $parts = [];
            foreach ($json as $entry) {
                if (is_string($entry)) {
                    $parts[] = $entry;
                } elseif (is_array($entry) && isset($entry[0]) && is_string($entry[0])) {
                    $parts[] = $entry[0];
                }
            }

            $joined = trim(implode('', $parts));
            return $joined;
        } catch (\Throwable $e) {
            Log::warning('TranslationService: clients5 Google Translate failed: ' . $e->getMessage());
            return '';
        }
    }

    /**
     * Fallback via Stichoza GoogleTranslate with strict IPv4 and short timeouts.
     */
    private static function translateViaStichoza(string $text, string $target, string $source): string
    {
        $options = [
            'timeout'         => 5,
            'connect_timeout' => 3,
        ];
        if (defined('CURLOPT_IPRESOLVE') && defined('CURL_IPRESOLVE_V4')) {
            $options['curl'] = [CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4];
        }

        try {
            $tr = new GoogleTranslate($target, $source ?: null, $options);
            $raw = $tr->translate($text);
            return !empty($raw) ? trim($raw) : '';
        } catch (\Throwable $e) {
            Log::warning('TranslationService: Stichoza GoogleTranslate failed: ' . $e->getMessage());
            return '';
        }
    }

    /**
     * Converts Hawar (Latin) Kurmanji to Kurdish-Arabic (Badini) script.
     */
    public static function hawarToKurdishArabic(string $text): string
    {
        $text = trim($text);
        if ($text === '') {
            return '';
        }

        $tokens = preg_split('/([^\p{L}\p{N}]+)/u', $text, -1, PREG_SPLIT_DELIM_CAPTURE);
        $output = '';

        foreach ($tokens as $token) {
            if ($token === '') {
                continue;
            }

            if (!preg_match('/[a-zA-ZçÇêÊîÎşŞûÛ]/u', $token)) {
                $output .= $token;
                continue;
            }

            $output .= self::transliterateWord($token);
        }

        return $output;
    }

    /**
     * Transliterates a single Latin Hawar word to Kurdish Arabic script.
     */
    private static function transliterateWord(string $w): string
    {
        $len = mb_strlen($w, 'UTF-8');
        $wordAr = '';

        for ($i = 0; $i < $len; $i++) {
            $ch = mb_substr($w, $i, 1, 'UTF-8');
            $lower = mb_strtolower($ch, 'UTF-8');
            $next = ($i + 1 < $len) ? mb_strtolower(mb_substr($w, $i + 1, 1, 'UTF-8')) : '';
            $isStart = ($i === 0);
            $isEnd = ($i === $len - 1);

            if ($lower === 'x' && $next === 'w') {
                $wordAr .= 'خو';
                $i++;
                continue;
            }
            if ($lower === 'l' && $next === 'l') {
                $wordAr .= 'ڵ';
                $i++;
                continue;
            }
            if ($lower === 'r' && $next === 'r') {
                $wordAr .= 'ڕ';
                $i++;
                continue;
            }
            if ($lower === 's' && $next === 'h') {
                $wordAr .= 'ش';
                $i++;
                continue;
            }
            if ($lower === 'c' && $next === 'h') {
                $wordAr .= 'چ';
                $i++;
                continue;
            }

            switch ($lower) {
                case 'a': $wordAr .= $isStart ? 'ئا' : 'ا'; break;
                case 'b': $wordAr .= 'ب'; break;
                case 'c': $wordAr .= 'ج'; break;
                case 'ç': $wordAr .= 'چ'; break;
                case 'd': $wordAr .= 'د'; break;
                case 'e': $wordAr .= $isStart ? 'ئە' : 'ە'; break;
                case 'ê': $wordAr .= $isStart ? 'ئێ' : 'ێ'; break;
                case 'f': $wordAr .= 'ف'; break;
                case 'g': $wordAr .= 'گ'; break;
                case 'h': $wordAr .= $isEnd ? 'هـ' : 'ه'; break;
                case 'i':
                    if ($isStart) {
                        $wordAr .= 'ئـ';
                    }
                    break;
                case 'î': $wordAr .= $isStart ? 'ئی' : 'ی'; break;
                case 'j': $wordAr .= 'ژ'; break;
                case 'k': $wordAr .= 'ک'; break;
                case 'l': $wordAr .= 'ل'; break;
                case 'm': $wordAr .= 'م'; break;
                case 'n': $wordAr .= 'ن'; break;
                case 'o': $wordAr .= $isStart ? 'ئۆ' : 'ۆ'; break;
                case 'p': $wordAr .= 'پ'; break;
                case 'q': $wordAr .= 'ق'; break;
                case 'r': $wordAr .= 'ر'; break;
                case 's': $wordAr .= 'س'; break;
                case 'ş': $wordAr .= 'ش'; break;
                case 't': $wordAr .= 'ت'; break;
                case 'u': $wordAr .= $isStart ? 'ئو' : 'و'; break;
                case 'û': $wordAr .= $isStart ? 'ئوو' : 'وو'; break;
                case 'v': $wordAr .= 'ڤ'; break;
                case 'w': $wordAr .= 'و'; break;
                case 'x': $wordAr .= 'خ'; break;
                case 'y': $wordAr .= 'ی'; break;
                case 'z': $wordAr .= 'ز'; break;
                default:  $wordAr .= $ch; break;
            }
        }

        return $wordAr;
    }
}

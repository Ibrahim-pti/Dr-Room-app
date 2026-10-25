<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Stichoza\GoogleTranslate\GoogleTranslate;

class TranslationService
{
    /**
     * Dictionary of specific medical, geographic, and common terms for Badini (Arabic script).
     */
    private static array $badiniDictionary = [
        'testker' => 'تێستکەر',
        'tester' => 'تێستەر',
        'cejd' => 'جەددە',
        'jeddah' => 'جەددە',
        'taqîgeh' => 'تاقیگەهـ',
        'taqigeh' => 'تاقیگەهـ',
        'laboratuar' => 'تاقیگەهـ',
        'nexweşxane' => 'نەخۆشخانە',
        'nexwesxane' => 'نەخۆشخانە',
        'dermanxane' => 'دەرمانخانە',
        'nojdar' => 'نوژدار',
        'bijîşk' => 'نوژدار',
        'bijisk' => 'نوژدار',
        'navnîşan' => 'ناڤنیشان',
        'navnisan' => 'ناڤنیشان',
        'nav' => 'ناڤ',
        'pispor' => 'پسبۆر',
        'pişkinîn' => 'پشکنین',
        'piskinin' => 'پشکنین',
        'xizmetguzarî' => 'خزمەتگوزاری',
        'xizmetguzari' => 'خزمەتگوزاری',
        'daxwazî' => 'داخوازی',
        'daxwazi' => 'داخوازی',
        'pakêj' => 'پاکێج',
        'pakej' => 'پاکێج',
        'xebat' => 'خەبات',
        'xebatkar' => 'خەباتکار',
        'perestariyê' => 'پەرستاریێ',
        'perestarî' => 'پەرستاری',
        'erbil' => 'هەولێر',
        'hewlêr' => 'هەولێر',
        'duhok' => 'دهۆک',
        'dihok' => 'دهۆک',
        'sulaymaniyah' => 'سلێمانی',
        'silêmanî' => 'سلێمانی',
        'kirkuk' => 'کەرکووک',
        'kerkûk' => 'کەرکووک',
        'halabja' => 'هەڵەبجە',
        'helebce' => 'هەڵەبجە',
        'jadde' => 'جادە',
        'kolan' => 'کۆڵان',
    ];

    /**
     * Common Sorani terms to Badini terms in Arabic script.
     */
    private static array $soraniToBadini = [
        'ناو' => 'ناڤ',
        'ناوی' => 'ناڤێ',
        'ناوەکانی' => 'ناڤێن',
        'ناونیشان' => 'ناڤنیشان',
        'ناونیشانی' => 'ناڤنیشانێ',
        'پزیشک' => 'نوژدار',
        'پزیشکی' => 'نوژداری',
        'پزیشکان' => 'نوژداران',
        'پزیشکەکان' => 'نوژدارێن',
        'تاقیگە' => 'تاقیگەهـ',
        'تاقیگەی' => 'تاقیگەها',
        'تاقیگەکان' => 'تاقیگەهـ',
        'تێستەر' => 'تێستکەر',
        'تێست' => 'تێست',
        'شەقام' => 'جادە',
        'شەقامی' => 'جادا',
        'خوێن' => 'خوین',
        'پشکنین' => 'پشکنین',
        'پشکنینی' => 'پشکنینا',
        'پشکنینەکانی' => 'پشکنینێن',
        'دەرمانخانە' => 'دەرمانخانە',
        'دەرمانخانەی' => 'دەرمانخانەیا',
        'خزمەتگوزاری' => 'خزمەتگوزاری',
        'خزمەتگوزارییەکانی' => 'خزمەتگوزاریێن',
        'کاتی' => 'دەمێ',
        'کارکردن' => 'کارکرنێ',
        'ڕۆژ' => 'ڕۆژ',
        'ڕۆژی' => 'ڕۆژا',
        'نرخ' => 'بها',
        'نرخی' => 'بهایێ',
        'تەندروستی' => 'ساخلەمی',
        'سوپاس' => 'سوپاس',
        'باشە' => 'باشە',
    ];

    /**
     * Translates a single string into a target language with multiple failover providers.
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

        $isBadini = in_array($normTarget, ['kmr', 'ku', 'badini']);
        $actualTarget = $isBadini ? 'ku' : $normTarget;

        $translated = '';

        // Provider 1: MyMemory Translated API
        try {
            $url = 'https://api.mymemory.translated.net/get?q=' . urlencode($text) . '&langpair=' . urlencode($source) . '|' . urlencode($actualTarget);
            $response = Http::timeout(6)->get($url);
            if ($response->successful()) {
                $json = $response->json();
                $raw = $json['responseData']['translatedText'] ?? null;
                if (!empty($raw)
                    && stripos($raw, 'MYMEMORY WARNING') === false
                    && stripos($raw, 'PLEASE SELECT TWO DISTINCT LANGUAGES') === false
                    && stripos($raw, 'IS AN INVALID TARGET LANGUAGE') === false) {
                    $decoded = html_entity_decode(trim($raw), ENT_QUOTES | ENT_HTML5, 'UTF-8');
                    if (!empty($decoded)) {
                        $translated = $decoded;
                    }
                }
            }
        } catch (\Throwable $e) {
            Log::warning('TranslationService: MyMemory failed: ' . $e->getMessage());
        }

        // Provider 2: Stichoza GoogleTranslate
        if (empty($translated)) {
            try {
                $tr = new GoogleTranslate($actualTarget);
                $tr->setSource($source);
                $raw = $tr->translate($text);
                if (!empty($raw)) {
                    $translated = trim($raw);
                }
            } catch (\Throwable $e) {
                try {
                    $trAuto = new GoogleTranslate($actualTarget);
                    $raw = $trAuto->translate($text);
                    if (!empty($raw)) {
                        $translated = trim($raw);
                    }
                } catch (\Throwable $e2) {
                    Log::warning('TranslationService: GoogleTranslate failed: ' . $e2->getMessage());
                }
            }
        }

        // Post-processing for Badini / Kurmanji: Ensure Kurdish-Arabic script
        if ($isBadini) {
            if (!empty($translated)) {
                // If translation contains Latin letters from Google/MyMemory, convert to Kurdish Arabic script
                if (preg_match('/[a-zA-ZçÇêÊîÎşŞûÛ]/u', $translated)) {
                    return self::hawarToKurdishArabic($translated);
                }
                return self::applySoraniToBadini($translated);
            }
            // If external translation failed, convert Sorani text to Badini Kurdish
            return self::applySoraniToBadini($text);
        }

        // Fallback: return translated or original text
        return !empty($translated) ? $translated : $text;
    }

    /**
     * Converts Hawar (Latin) Kurmanji to Kurdish-Arabic (Badini) script.
     */
    public static function hawarToKurdishArabic(string $text): string
    {
        $text = trim($text);
        if ($text === '') return '';

        // Split into tokens (words and separators)
        $tokens = preg_split('/([^\p{L}\p{N}]+)/u', $text, -1, PREG_SPLIT_DELIM_CAPTURE);
        $output = '';

        foreach ($tokens as $token) {
            if ($token === '') continue;

            $lower = mb_strtolower($token, 'UTF-8');
            if (isset(self::$badiniDictionary[$lower])) {
                $output .= self::$badiniDictionary[$lower];
                continue;
            }

            if (!preg_match('/[a-zA-ZçÇêÊîÎşŞûÛ]/u', $token)) {
                $output .= $token;
                continue;
            }

            // Word transliteration from Latin Hawar to Kurdish Arabic alphabet
            $output .= self::transliterateWord($token);
        }

        return $output;
    }

    /**
     * Transliterates a single Latin word to Kurdish Arabic script.
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

            // Digraphs
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
                case 'c': $wordAr .= 'ج'; break; // In Kurdish Latin C is always J (e.g. Cejd -> جەددە)
                case 'ç': $wordAr .= 'چ'; break;
                case 'd': $wordAr .= 'د'; break;
                case 'e': 
                    if ($isStart) {
                        $wordAr .= 'ئە';
                    } elseif ($isEnd) {
                        $wordAr .= 'ە';
                    } else {
                        $wordAr .= 'ە';
                    }
                    break;
                case 'ê': $wordAr .= $isStart ? 'ئێ' : 'ێ'; break;
                case 'f': $wordAr .= 'ف'; break;
                case 'g': $wordAr .= 'گ'; break;
                case 'h': $wordAr .= 'هـ'; break;
                case 'i':
                    if ($isStart) $wordAr .= 'ئـ';
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

    /**
     * Converts Sorani terms to Badini terms in Arabic script.
     */
    public static function applySoraniToBadini(string $text): string
    {
        $words = preg_split('/([^\p{L}\p{N}]+)/u', $text, -1, PREG_SPLIT_DELIM_CAPTURE);
        $output = '';

        foreach ($words as $token) {
            if ($token === '') continue;
            if (isset(self::$soraniToBadini[$token])) {
                $output .= self::$soraniToBadini[$token];
            } else {
                $output .= $token;
            }
        }

        return $output;
    }
}

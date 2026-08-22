<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Stichoza\GoogleTranslate\GoogleTranslate;

class TranslateController extends Controller
{
    public function translate(Request $request)
    {
        // 1. Batch mode: { fields: { "title": "...", "content": "..." } }
        if ($request->has('fields') && is_array($request->fields)) {
            $results = [];
            $trEn = new GoogleTranslate('en');
            $trAr = new GoogleTranslate('ar');

            foreach ($request->fields as $key => $val) {
                $val = trim((string)$val);
                if (empty($val)) {
                    $results[$key] = ['en' => '', 'ar' => '', 'ckb' => ''];
                    continue;
                }

                try {
                    $trEn->setSource('ckb');
                    $en = $trEn->translate($val);
                } catch (\Exception $e) {
                    try {
                        $trEnFallback = new GoogleTranslate('en');
                        $en = $trEnFallback->translate($val);
                    } catch (\Exception $e2) {
                        $en = $val;
                    }
                }

                try {
                    $trAr->setSource('ckb');
                    $ar = $trAr->translate($val);
                } catch (\Exception $e) {
                    try {
                        $trArFallback = new GoogleTranslate('ar');
                        $ar = $trArFallback->translate($val);
                    } catch (\Exception $e2) {
                        $ar = $val;
                    }
                }

                $results[$key] = [
                    'en' => $en,
                    'ar' => $ar,
                    'ckb' => $val,
                ];
            }

            return response()->json([
                'success' => true,
                'translations' => $results,
            ]);
        }

        // 2. Single text mode: { text: "..." }
        $request->validate([
            'text' => 'required|string',
        ]);

        $text = trim($request->text);
        if (empty($text)) {
            return response()->json([
                'success' => false,
                'message' => 'Text cannot be empty'
            ], 400);
        }

        try {
            $trEn = new GoogleTranslate('en');
            $trEn->setSource('ckb');
            $en = $trEn->translate($text);

            $trAr = new GoogleTranslate('ar');
            $trAr->setSource('ckb');
            $ar = $trAr->translate($text);

            return response()->json([
                'success' => true,
                'translations' => [
                    'en' => $en,
                    'ar' => $ar,
                    'ckb' => $text,
                ]
            ]);
        } catch (\Exception $e) {
            try {
                // Fallback auto detect
                $trEn = new GoogleTranslate('en');
                $en = $trEn->translate($text);

                $trAr = new GoogleTranslate('ar');
                $ar = $trAr->translate($text);

                return response()->json([
                    'success' => true,
                    'translations' => [
                        'en' => $en,
                        'ar' => $ar,
                        'ckb' => $text,
                    ]
                ]);
            } catch (\Exception $e2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Translation failed: ' . $e2->getMessage()
                ], 500);
            }
        }
    }
}


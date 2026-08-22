<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Stichoza\GoogleTranslate\GoogleTranslate;

class TranslateController extends Controller
{
    public function translate(Request $request)
    {
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

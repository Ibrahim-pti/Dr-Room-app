<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TranslationService;
use Illuminate\Http\Request;

class TranslateController extends Controller
{
    public function translate(Request $request)
    {
        // 1. Batch mode: { fields: { "title": "...", "content": "..." } }
        if ($request->has('fields') && is_array($request->fields)) {
            $results = [];

            foreach ($request->fields as $key => $val) {
                $val = trim((string)$val);
                if (empty($val)) {
                    $results[$key] = ['en' => '', 'ar' => '', 'ckb' => '', 'kmr' => ''];
                    continue;
                }

                $en = TranslationService::translate($val, 'en', 'ckb');
                $ar = TranslationService::translate($val, 'ar', 'ckb');
                $kmr = TranslationService::translate($val, 'ku', 'ckb');

                $results[$key] = [
                    'en' => $en,
                    'ar' => $ar,
                    'ckb' => $val,
                    'kmr' => $kmr,
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

        $en = TranslationService::translate($text, 'en', 'ckb');
        $ar = TranslationService::translate($text, 'ar', 'ckb');
        $kmr = TranslationService::translate($text, 'ku', 'ckb');

        return response()->json([
            'success' => true,
            'translations' => [
                'en' => $en,
                'ar' => $ar,
                'ckb' => $text,
                'kmr' => $kmr,
            ]
        ]);
    }
}

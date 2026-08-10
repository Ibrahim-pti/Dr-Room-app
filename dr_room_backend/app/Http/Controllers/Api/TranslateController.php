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

        $text = $request->text;

        try {
            $tr = new GoogleTranslate();
            // Explicitly set source language to Kurdish (Sorani) to prevent auto-detect hallucinations
            $tr->setSource('ckb');
            
            $en = $tr->setTarget('en')->translate($text);
            
            // Re-instantiate or just change target for Arabic
            $ar = $tr->setTarget('ar')->translate($text);

            return response()->json([
                'success' => true,
                'translations' => [
                    'en' => $en,
                    'ar' => $ar,
                    'ckb' => $text, // The input is already in Kurdish
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Translation failed: ' . $e->getMessage()
            ], 500);
        }
    }
}

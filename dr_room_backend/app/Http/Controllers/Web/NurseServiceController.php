<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\TranslationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class NurseServiceController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        return view('nurse.services.index', compact('user', 'nurse'));
    }

    public function update(Request $request)
    {
        $nurse = Auth::user()->nurse;
        if (!$nurse) {
            return redirect()
                ->route('nurse.profile.index')
                ->with('error', 'تکایە سەرەتا زانیارییەکانی پڕۆفایل تەواو بکە.');
        }

        $request->validate([
            'custom_services' => 'nullable|array',
            'custom_services.*.name' => 'nullable|string|max:255',
            'custom_services.*.name_kmr' => 'nullable|string|max:255',
            'custom_services.*.name_en' => 'nullable|string|max:255',
            'custom_services.*.name_ar' => 'nullable|string|max:255',
            'custom_services.*.price' => 'nullable|numeric|min:0',
        ]);

        $customServicesList = [];
        if ($request->has('custom_services') && is_array($request->custom_services)) {
            foreach ($request->custom_services as $cs) {
                $name = trim((string) ($cs['name'] ?? ''));
                if ($name === '') {
                    continue;
                }

                $nameKmr = trim((string) ($cs['name_kmr'] ?? ''));
                $nameEn = trim((string) ($cs['name_en'] ?? ''));
                $nameAr = trim((string) ($cs['name_ar'] ?? ''));

                try {
                    if ($nameEn === '') {
                        $nameEn = TranslationService::translate($name, 'en');
                    }
                    if ($nameAr === '') {
                        $nameAr = TranslationService::translate($name, 'ar');
                    }
                    if ($nameKmr === '') {
                        $nameKmr = TranslationService::translate($name, 'ku');
                    }
                } catch (\Throwable $e) {
                    Log::error('Nurse service translation failed: ' . $e->getMessage());
                }

                $customServicesList[] = [
                    'name' => $name,
                    'name_kmr' => $nameKmr,
                    'name_en' => $nameEn,
                    'name_ar' => $nameAr,
                    'price' => isset($cs['price']) && $cs['price'] !== '' ? (float) $cs['price'] : 0,
                ];
            }
        }

        $nurse->update([
            'custom_services' => $customServicesList,
        ]);

        return back()->with('success', 'خزمەتگوزارییەکان و نرخەکان بە سەرکەوتوویی پاشەکەوت کران.');
    }

    public function translate(Request $request)
    {
        $request->validate([
            'custom_services' => 'nullable|array',
        ]);

        $translated = [];

        try {
            if ($request->has('custom_services') && is_array($request->custom_services)) {
                foreach ($request->custom_services as $idx => $cs) {
                    $kurdish = trim((string) ($cs['name'] ?? ''));
                    $kmr = trim((string) ($cs['name_kmr'] ?? ''));
                    $en = trim((string) ($cs['name_en'] ?? ''));
                    $ar = trim((string) ($cs['name_ar'] ?? ''));

                    if ($kurdish !== '') {
                        if ($en === '') {
                            $en = TranslationService::translate($kurdish, 'en');
                        }
                        if ($ar === '') {
                            $ar = TranslationService::translate($kurdish, 'ar');
                        }
                        if ($kmr === '') {
                            $kmr = TranslationService::translate($kurdish, 'ku');
                        }
                    }

                    $translated[$idx] = [
                        'name' => $kurdish,
                        'name_kmr' => $kmr,
                        'name_en' => $en,
                        'name_ar' => $ar,
                    ];
                }
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'custom_services_translated' => $translated,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'وەرگێڕان سەرکەوتوو نەبوو: ' . $e->getMessage(),
            ], 500);
        }
    }
}

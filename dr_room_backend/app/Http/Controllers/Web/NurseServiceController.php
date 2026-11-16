<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\TranslationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class NurseServiceController extends Controller
{
    public const DEFAULT_NURSING_CATEGORIES = [
        'دەرزی و سیرۆم',
        'پانسمانی برین',
        'چاودێری ماڵەوە',
        'چاودێری بەتەمەنان',
        'چاودێری منداڵ',
        'سۆندە و شلەمەنی',
        'پشکنینی خێرا',
        'ئۆکسجین و هەڵمگرتن',
        'فیزیۆتێراپی',
    ];

    public const DEFAULT_PRESETS = [
        ['category' => 'دەرزی و سیرۆم', 'name' => 'دانانی کانیۆلا و سێرووم', 'name_kmr' => 'دانانا کانیۆلا و سێرۆمێ', 'name_en' => 'Cannula & IV Infusion', 'name_ar' => 'تركيب كانيولا ومغذي', 'price' => 15000],
        ['category' => 'دەرزی و سیرۆم', 'name' => 'لێدانی دەرزی (ماسولکە و دەمار)', 'name_kmr' => 'لێدانا دەرزیێ (ماسۆلکە و دەمار)', 'name_en' => 'Injections (IM / IV)', 'name_ar' => 'حقن عضل ووريد', 'price' => 10000],
        ['category' => 'پانسمانی برین', 'name' => 'پانسمانی برین و سووتان', 'name_kmr' => 'پانسمانا برین و سۆتنێ', 'name_en' => 'Wound & Burn Dressing', 'name_ar' => 'تضميد الجروح والحروق', 'price' => 20000],
        ['category' => 'سۆندە و شلەمەنی', 'name' => 'دانان و گۆڕینی سۆندەی میز', 'name_kmr' => 'دانان و گوهۆڕینا سۆندەیا میزێ', 'name_en' => 'Urinary Catheter Care', 'name_ar' => 'تركيب وتبديل قسطرة البول', 'price' => 25000],
        ['category' => 'پشکنینی خێرا', 'name' => 'پێوانی زەخت و ڕێژەی شەکرە', 'name_kmr' => 'پیڤانا فشارا خوینێ و شەکرێ', 'name_en' => 'Blood Pressure & Glucose Check', 'name_ar' => 'فحص الضغط والسكري', 'price' => 8000],
        ['category' => 'پانسمانی برین', 'name' => 'لابردنی تەقەڵ و دروومان', 'name_kmr' => 'ڕاکرنا تەقەلێ برینێ', 'name_en' => 'Suture / Stitch Removal', 'name_ar' => 'إزالة الغرز الجراحية', 'price' => 15000],
        ['category' => 'ئۆکسجین و هەڵمگرتن', 'name' => 'دانیشتنی هەڵم و ئۆکسجین (Nebulizer)', 'name_kmr' => 'هەلمگرتن و ئۆکسجین', 'name_en' => 'Nebulizer & Oxygen Session', 'name_ar' => 'جلسة بخار وأوكسجين', 'price' => 12000],
        ['category' => 'چاودێری بەتەمەنان', 'name' => 'چاودێری بەتەمەنان لە ماڵەوە', 'name_kmr' => 'چاڤدێریا دانعەمران ل مالێ', 'name_en' => 'Elderly Home Care Visit', 'name_ar' => 'رعاية كبار السن في المنزل', 'price' => 30000],
    ];

    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        $savedCategories = collect($nurse?->custom_services ?? [])
            ->pluck('category')
            ->filter(fn ($c) => is_string($c) && trim($c) !== '')
            ->map(fn ($c) => trim($c));

        $nursingCategories = collect(self::DEFAULT_NURSING_CATEGORIES)
            ->merge($savedCategories)
            ->unique()
            ->values();

        $presets = self::DEFAULT_PRESETS;

        return view('nurse.services.index', compact('user', 'nurse', 'nursingCategories', 'presets'));
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
            'custom_services.*.category' => 'nullable|string|max:255',
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

                $category = trim((string) ($cs['category'] ?? ''));
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
                    'category' => $category,
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

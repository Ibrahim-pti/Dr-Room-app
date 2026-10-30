<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Lab;
use App\Models\LabTest;
use App\Models\LabPackage;

class LabApiController extends Controller
{
    /**
     * Get a list of all active labs
     */
    public function index(Request $request)
    {
        $query = User::with('lab')
            ->where('role', 'lab')
            ->where('status', 'approved');

        $users = $query->get();
            
        $labs = $users->map(function($user) {
            $lab = $user->lab;
            $rawImg = $lab && $lab->image_path ? $lab->image_path : null;
            $imageUrl = 'assets/images/laboratory.jpg';
            if ($rawImg) {
                if (str_starts_with($rawImg, 'http')) {
                    $imageUrl = $rawImg;
                } else {
                    $imageUrl = asset(ltrim($rawImg, '/'));
                }
            }

            $discount = $lab && $lab->discount !== null ? (int)$lab->discount : null;
            $isOpen = $lab ? (bool)($lab->is_active ?? true) : true;
            $ratingVal = ($lab && $lab->rating !== null) ? (float)$lab->rating : 0.0;
            $reviewsCount = ($lab && $lab->total_reviews !== null) ? (int)$lab->total_reviews : ($lab ? (int)$lab->reviews()->count() : 0);

            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'name_kmr' => $user->name_kmr ?? ($lab ? $lab->name_kmr : null) ?? $user->name,
                'phone' => $user->phone,
                'profile_image' => $imageUrl,
                'image' => $imageUrl,
                'city' => $lab ? ($lab->city ?? 'Erbil') : 'Erbil',
                'rating' => $ratingVal,
                'reviews' => $reviewsCount,
                'discount' => $discount,
                'is_open' => $isOpen,
                'opening_hours' => $lab && $lab->opening_hours ? $lab->opening_hours : '08:00 AM - 10:00 PM',
                'type' => 'General',
                'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : false,
                'location' => $lab ? $lab->location : null,
                'location_ar' => $lab ? $lab->location_ar : null,
                'location_en' => $lab ? $lab->location_en : null,
                'location_kmr' => $lab ? $lab->location_kmr : null,
                'about_us' => $lab ? $lab->about_us : null,
                'about_us_ar' => $lab ? $lab->about_us_ar : null,
                'about_us_en' => $lab ? $lab->about_us_en : null,
                'about_us_kmr' => $lab ? $lab->about_us_kmr : null,
            ];
        });

        // Dynamic distinct cities from the real labs data
        $dynamicCities = $labs->pluck('city')->unique()->filter()->values()->all();
        array_unshift($dynamicCities, 'All');

        // Dynamic rating thresholds
        $dynamicRatings = [
            ['key' => 'all', 'label' => 'All', 'min' => 0.0],
            ['key' => '4_5', 'label' => '4.5+', 'min' => 4.5],
            ['key' => '4_7', 'label' => '4.7+', 'min' => 4.7],
            ['key' => '4_9', 'label' => '4.9+', 'min' => 4.9],
        ];

        return response()->json([
            'success' => true,
            'data' => $labs,
            'filters' => [
                'cities' => $dynamicCities,
                'ratings' => $dynamicRatings,
                'total' => $labs->count(),
            ]
        ]);
    }

    /**
     * Get details for a specific lab
     */
    public function show($id)
    {
        $user = User::with(['lab.tests', 'lab.packages'])
            ->where('role', 'lab')
            ->where('status', 'approved')
            ->where(function($q) use ($id) {
                $q->where('id', $id)
                  ->orWhereHas('lab', function($lq) use ($id) {
                      $lq->where('id', $id);
                  });
            })
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Lab not found'
            ], 404);
        }

        $lab = $user->lab;
        if ($lab) {
            $lab->increment('views_count');
        }

        $rawImg = $lab && $lab->image_path ? $lab->image_path : null;
        $image = 'assets/images/laboratory.jpg';
        if ($rawImg) {
            $image = str_starts_with($rawImg, 'http') ? $rawImg : asset(ltrim($rawImg, '/'));
        }
        $discount = $lab && $lab->discount !== null ? (int)$lab->discount : null;
        $isOpen = $lab ? (bool)($lab->is_active ?? true) : true;
        
        $packages = ($lab && $lab->packages && $lab->packages->isNotEmpty()) ? $lab->packages->where('is_active', true)->values()->map(function($p) {
            return [
                'id' => (int)$p->id,
                'name' => (string)$p->name,
                'name_ar' => $p->name_ar,
                'name_en' => $p->name_en,
                'name_kmr' => $p->name_kmr,
                'desc' => (string)($p->description ?? 'پاکێجی تایبەتی تاقیگە بە داشکاندنی ناوازە'),
                'description_ar' => $p->description_ar,
                'description_en' => $p->description_en,
                'description_kmr' => $p->description_kmr,
                'price' => (int)$p->price,
                'original_price' => (int)($p->original_price ?? ($p->discount ? round($p->price / (1 - ($p->discount / 100))) : $p->price)),
                'discount' => (int)($p->discount ?? 0),
                'test_ids' => is_array($p->test_ids) ? array_values(array_map('intval', $p->test_ids)) : [],
            ];
        }) : [];

        $ratingVal = ($lab && $lab->rating !== null) ? (float)$lab->rating : 0.0;
        $reviewsCount = ($lab && $lab->total_reviews !== null) ? (int)$lab->total_reviews : ($lab ? (int)$lab->reviews()->count() : 0);

        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'name_ar' => $user->name_ar ?? $user->name,
            'name_en' => $user->name_en ?? $user->name,
            'name_kmr' => $user->name_kmr ?? ($lab ? $lab->name_kmr : null) ?? $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_image' => $image,
            'image' => $image,
            'images' => [
                $image,
                'assets/images/lab2.jpg',
                'assets/images/lab3.jpg',
                'assets/images/lab4.jpg',
            ],
            'city' => $lab ? ($lab->city ?? 'Erbil') : 'Erbil',
            'location' => $lab && $lab->location ? $lab->location : 'هەولێر - شەقامی پزیشکان',
            'location_ar' => $lab && $lab->location_ar ? $lab->location_ar : 'أربيل - شارع الأطباء',
            'location_en' => $lab && $lab->location_en ? $lab->location_en : 'Erbil - Doctors Street',
            'location_kmr' => $lab ? $lab->location_kmr : null,
            'rating' => $ratingVal,
            'reviews' => $reviewsCount,
            'views_count' => $lab ? (int)$lab->views_count : 0,
            'discount' => $discount,
            'is_open' => $isOpen,
            'opening_hours' => $lab && $lab->opening_hours ? $lab->opening_hours : '08:00 AM - 10:00 PM',
            'youtube_url' => $lab && $lab->youtube_url ? $lab->youtube_url : 'https://www.youtube.com/watch?v=ScMzIvxBSi4',
            'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : true,
            'about_us' => $lab && $lab->about_us ? $lab->about_us : 'تاقیگەیەکی پزیشکیی پێشکەوتووە لە پێناو دابینکردنی وردترین و خێراترین ئەنجامی پشکنینەکان بە ئامێری مۆدێرن و ستافێکی پسپۆڕ.',
            'about_us_ar' => $lab ? $lab->about_us_ar : 'مختبر طبي متطور يقدم أدق الفحوصات الطبية بأحدث الأجهزة والكوادر المتخصصة.',
            'about_us_en' => $lab ? $lab->about_us_en : 'Advanced medical diagnostic laboratory providing highly accurate and fast test results.',
            'about_us_kmr' => $lab ? $lab->about_us_kmr : null,
            'latitude' => $lab && $lab->latitude ? $lab->latitude : '36.1911',
            'longitude' => $lab && $lab->longitude ? $lab->longitude : '44.0092',
            'packages' => $packages,
            'tests' => ($lab && $lab->tests && $lab->tests->isNotEmpty()) ? $lab->tests->map(function($t) use ($discount) {
                $disc = $t->discount ?? ($discount ? $discount : null);
                $originalPrice = $disc ? round($t->price / (1 - ($disc / 100))) : null;
                return [
                    'id' => $t->id,
                    'name' => $t->name,
                    'name_en' => $t->name_en,
                    'name_ar' => $t->name_ar,
                    'price' => (int)$t->price,
                    'original_price' => $originalPrice,
                    'discount' => $disc,
                    'type' => $t->type ?? 'General Test',
                    'desc' => $t->description ?? $t->desc ?? 'پشکنینی پزیشکی ورد',
                ];
            }) : [],
        ];

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    /**
     * Get all available lab tests dynamically across all labs
     */
    public function allTests(Request $request)
    {
        $query = LabTest::with('lab.user')->where('is_active', true);

        if ($request->filled('category')) {
            $query->where('type', $request->category);
        }
        if ($request->filled('lab_id')) {
            $query->where('lab_id', $request->lab_id);
        }
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function($q) use ($s) {
                $q->where('name', 'like', "%$s%")
                  ->orWhere('name_en', 'like', "%$s%")
                  ->orWhere('name_ar', 'like', "%$s%")
                  ->orWhere('type', 'like', "%$s%");
            });
        }

        $tests = $query->get()->map(function($t) {
            $lab = $t->lab;
            $labUser = $lab ? $lab->user : null;
            $labName = $labUser ? $labUser->name : 'تاقیگەی پزیشکی';
            $discount = $t->discount ?: ($lab ? $lab->discount : null);
            $originalPrice = $discount ? round($t->price / (1 - ($discount / 100))) : null;

            $nameLower = strtolower(trim($t->name));
            $dict = [
                'cbc' => [
                    'ku' => 'پشکنینی گشتی خوێن (CBC)',
                    'en' => 'Complete Blood Count (CBC)',
                    'ar' => 'فحص الدم الشامل (CBC)',
                    'kmr' => 'پشکنینا گشتی یا خوینێ (CBC)',
                ],
                'esr' => [
                    'ku' => 'خێرایی نیشتنی خوێن (ESR)',
                    'en' => 'Erythrocyte Sedimentation Rate (ESR)',
                    'ar' => 'سرعة ترسيب الدم (ESR)',
                    'kmr' => 'بلەزیا نیشتنا خوینێ (ESR)',
                ],
                'fbs' => [
                    'ku' => 'شەکرەی بەڕۆژوو (FBS)',
                    'en' => 'Fasting Blood Sugar (FBS)',
                    'ar' => 'فحص سكر الدم الصائم (FBS)',
                    'kmr' => 'شەکرا بڕۆژی (FBS)',
                ],
                'hba1c' => [
                    'ku' => 'شەکرەی سێ مانگی (HbA1c)',
                    'en' => 'Glycated Hemoglobin (HbA1c)',
                    'ar' => 'السكر التراكمي (HbA1c)',
                    'kmr' => 'شەکرا سێ هەیڤی (HbA1c)',
                ],
                'lipid profile' => [
                    'ku' => 'چەوری و کۆلیسترۆڵ (Lipid Profile)',
                    'en' => 'Lipid Profile',
                    'ar' => 'تحليل دهون الدم (Lipid Profile)',
                    'kmr' => 'چەوری و کۆلیسترۆڵ (Lipid Profile)',
                ],
                'vitamin d' => [
                    'ku' => 'پشکنینی ڤیتامین دی (Vitamin D)',
                    'en' => 'Vitamin D (25-OH)',
                    'ar' => 'فحص فيتامين د (Vitamin D)',
                    'kmr' => 'پشکنینا ڤیتامین دی (Vitamin D)',
                ],
            ];

            $nameKu = $t->name;
            $nameEn = (!empty($t->name_en) && strtolower(trim($t->name_en)) !== $nameLower) ? $t->name_en : null;
            $nameAr = (!empty($t->name_ar) && strtolower(trim($t->name_ar)) !== $nameLower) ? $t->name_ar : null;
            $nameKmr = (!empty($t->name_kmr) && strtolower(trim($t->name_kmr)) !== $nameLower) ? $t->name_kmr : null;

            if (isset($dict[$nameLower])) {
                $nameKu = $dict[$nameLower]['ku'];
                $nameEn = $nameEn ?: $dict[$nameLower]['en'];
                $nameAr = $nameAr ?: $dict[$nameLower]['ar'];
                $nameKmr = $nameKmr ?: $dict[$nameLower]['kmr'];
            }

            return [
                'id' => (string) $t->id,
                'name' => $nameKu,
                'name_ku' => $nameKu,
                'name_en' => $nameEn ?: $t->name,
                'name_ar' => $nameAr ?: $t->name,
                'name_kmr' => $nameKmr ?: $nameKu,
                'price' => (double) $t->price,
                'original_price' => $originalPrice ? (double) $originalPrice : null,
                'discount' => $discount ? (int) $discount : null,
                'category' => $t->type ?: 'خوێن',
                'type' => $t->type ?: 'General',
                'lab_id' => $lab ? $lab->id : null,
                'lab_user_id' => $labUser ? $labUser->id : null,
                'lab' => $labName,
                'lab_name' => $labName,
                'lab_image' => $lab && $lab->image_path ? $lab->image_path : ($labUser && $labUser->profile_image ? 'storage/' . $labUser->profile_image : 'assets/images/laboratory.jpg'),
                'city' => $lab ? ($lab->city ?? 'Erbil') : 'Erbil',
                'home_sample_collection' => $lab ? (bool) $lab->home_sample_collection : true,
                'desc' => $t->description ?: 'پشکنینی ورد و خێرای تاقیگەیی',
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $tests,
            'total' => $tests->count(),
        ]);
    }

    /**
     * Get all lab packages dynamically from database
     */
    public function allPackages(Request $request)
    {
        $query = LabPackage::with(['lab.user'])->where('is_active', true);

        if ($request->filled('lab_id')) {
            $query->where('lab_id', $request->lab_id);
        }

        $packages = $query->get()->map(function($p) {
            $lab = $p->lab;
            $labUser = $lab ? $lab->user : null;
            $labName = $labUser ? $labUser->name : 'تاقیگەی پزیشکی';

            return [
                'id' => (string) $p->id,
                'name' => $p->name,
                'name_ar' => $p->name_ar ?? $p->name,
                'name_en' => $p->name_en ?? $p->name,
                'desc' => $p->description ?: 'پاکێجی پشکنینی پزیشکی',
                'description_ar' => $p->description_ar,
                'description_en' => $p->description_en,
                'price' => (double) $p->price,
                'original_price' => $p->original_price ? (double) $p->original_price : ($p->discount ? round($p->price / (1 - ($p->discount / 100))) : null),
                'discount' => $p->discount ? (int) $p->discount : 0,
                'lab_id' => $lab ? $lab->id : null,
                'lab_user_id' => $labUser ? $labUser->id : null,
                'lab_name' => $labName,
                'tests_count' => is_array($p->test_ids) ? count($p->test_ids) : $p->tests->count(),
                'tests' => $p->tests->pluck('name')->toArray(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $packages,
            'total' => $packages->count(),
        ]);
    }

    /**
     * Get real sampling specialists and home care staff dynamically from database
     */
    public function staff(Request $request)
    {
        $query = \App\Models\Nurse::with('user')
            ->where('is_approved', true)
            ->where('is_available', true);

        if ($request->filled('city')) {
            $query->where('city', $request->city);
        }

        $staff = $query->get()->map(function($nurse) {
            $user = $nurse->user;
            $name = $user ? $user->name : ($nurse->name ?? 'کارمەندی تەندروستی');

            return [
                'id' => (string) ($user ? $user->id : $nurse->id),
                'nurse_id' => (string) $nurse->id,
                'name' => $name,
                'name_en' => $user ? ($user->name_en ?? $nurse->name_en) : $nurse->name_en,
                'name_ar' => $user ? ($user->name_ar ?? $nurse->name_ar) : $nurse->name_ar,
                'name_ku' => $user ? ($user->name_ku ?? $nurse->name_ku ?? $nurse->name_ckb) : ($nurse->name_ku ?? $nurse->name_ckb),
                'title' => $nurse->specialty ?: 'پسپۆڕی وەرگرتنی نموونە و پشکنین',
                'specialty' => $nurse->specialty,
                'specialty_en' => $nurse->specialty_en ?? null,
                'specialty_ar' => $nurse->specialty_ar ?? null,
                'lab_name' => 'تیمی نموونەگری دکتۆر ڕووم',
                'lab_id' => null,
                'lab_user_id' => $user ? $user->id : null,
                'rating' => (float) ($nurse->rating ?: 4.9),
                'reviews_count' => (int) ($nurse->total_reviews ?: 0),
                'city' => $nurse->city ?? 'Erbil',
                'home_visit' => true,
                'fee' => (double) ($nurse->fee ?: 5000.0),
                'image' => $nurse->image_path
                    ? (str_starts_with($nurse->image_path, 'http') ? $nurse->image_path : asset('storage/' . $nurse->image_path))
                    : ($user && $user->profile_image ? asset('storage/' . $user->profile_image) : null),
                'is_available' => (bool) $nurse->is_available,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $staff,
            'total' => $staff->count(),
        ]);
    }
}

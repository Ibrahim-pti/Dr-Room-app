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
            $image = $lab && $lab->image_path ? $lab->image_path : ($user->profile_image ? 'storage/' . $user->profile_image : 'assets/images/laboratory.jpg');
            $discount = $lab && $lab->discount !== null ? (int)$lab->discount : (($user->id == 12 || $user->id % 3 == 0) ? 25 : ($user->id % 4 == 0 ? 15 : null));
            $isOpen = ($user->id % 2 != 0 || $user->id == 12);

            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'phone' => $user->phone,
                'profile_image' => $image,
                'image' => $image,
                'city' => $lab ? ($lab->city ?? 'Erbil') : 'Erbil',
                'rating' => $lab && $lab->rating ? (float)$lab->rating : 4.8,
                'reviews' => $lab && $lab->total_reviews ? (int)$lab->total_reviews : 120,
                'discount' => $discount,
                'is_open' => $isOpen,
                'opening_hours' => $lab && $lab->opening_hours ? $lab->opening_hours : '08:00 AM - 10:00 PM',
                'type' => 'General',
                'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : false,
                'location' => $lab ? $lab->location : null,
                'location_ar' => $lab ? $lab->location_ar : null,
                'location_en' => $lab ? $lab->location_en : null,
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

        $image = $lab && $lab->image_path ? $lab->image_path : ($user->profile_image ? 'storage/' . $user->profile_image : 'assets/images/laboratory.jpg');
        $discount = $lab && $lab->discount !== null ? (int)$lab->discount : (($user->id == 12 || $user->id % 3 == 0) ? 25 : ($user->id % 4 == 0 ? 15 : null));
        $isOpen = ($user->id % 2 != 0 || $user->id == 12);
        
        $packages = ($lab && $lab->packages && $lab->packages->isNotEmpty()) ? $lab->packages->where('is_active', true)->values()->map(function($p) {
            return [
                'id' => (int)$p->id,
                'name' => (string)$p->name,
                'name_ar' => $p->name_ar,
                'name_en' => $p->name_en,
                'desc' => (string)($p->description ?? 'پاکێجی تایبەتی تاقیگە بە داشکاندنی ناوازە'),
                'description_ar' => $p->description_ar,
                'description_en' => $p->description_en,
                'price' => (int)$p->price,
                'original_price' => (int)($p->original_price ?? ($p->discount ? round($p->price / (1 - ($p->discount / 100))) : $p->price)),
                'discount' => (int)($p->discount ?? 0),
                'test_ids' => is_array($p->test_ids) ? array_values(array_map('intval', $p->test_ids)) : [],
            ];
        }) : [
            [
                'id' => 101,
                'name' => 'پاکێجی پشکنینی تەواوی جەستە (Full Body Checkup)',
                'desc' => 'شاملی پشکنینی گشتی خوێن CBC، چەوری و کۆلیسترۆڵ، شەکرەی سێ مانگی، کاری جگەر و گورچیلە',
                'original_price' => 85000,
                'price' => 59000,
                'discount' => 30,
                'test_ids' => [1, 2, 3, 5, 6],
            ],
            [
                'id' => 102,
                'name' => 'پاکێجی ڤیتامین و ووزە (Vitamins & Energy)',
                'desc' => 'پشکنینی وردی ڤیتامین D، ڤیتامین B12، ڕێژەی ئاسن و کانزاکانی جەستە',
                'original_price' => 60000,
                'price' => 42000,
                'discount' => 30,
                'test_ids' => [4],
            ],
        ];

        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'name_ar' => $user->name_ar ?? $user->name,
            'name_en' => $user->name_en ?? $user->name,
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
            'rating' => $lab && $lab->rating ? (float)$lab->rating : 5.0,
            'reviews' => $lab ? (int)($lab->total_reviews ?? $lab->reviews()->count()) : 0,
            'views_count' => $lab ? (int)$lab->views_count : 0,
            'discount' => $discount,
            'is_open' => $isOpen,
            'opening_hours' => $lab && $lab->opening_hours ? $lab->opening_hours : '08:00 AM - 10:00 PM',
            'youtube_url' => $lab && $lab->youtube_url ? $lab->youtube_url : 'https://www.youtube.com/watch?v=ScMzIvxBSi4',
            'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : true,
            'about_us' => $lab && $lab->about_us ? $lab->about_us : 'تاقیگەیەکی پزیشکیی پێشکەوتووە لە پێناو دابینکردنی وردترین و خێراترین ئەنجامی پشکنینەکان بە ئامێری مۆدێرن و ستافێکی پسپۆڕ.',
            'about_us_ar' => $lab ? $lab->about_us_ar : 'مختبر طبي متطور يقدم أدق الفحوصات الطبية بأحدث الأجهزة والكوادر المتخصصة.',
            'about_us_en' => $lab ? $lab->about_us_en : 'Advanced medical diagnostic laboratory providing highly accurate and fast test results.',
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
            }) : [
                ['id' => 1, 'name' => 'پشکنینی گشتی خوێن (CBC)', 'price' => 10000, 'original_price' => 14000, 'discount' => 28, 'type' => 'Blood Test', 'desc' => 'Complete Blood Count'],
                ['id' => 2, 'name' => 'چەوری و کۆلیسترۆڵ (Lipid Profile)', 'price' => 15000, 'original_price' => 20000, 'discount' => 25, 'type' => 'Blood Test', 'desc' => 'Cholesterol & Triglycerides'],
                ['id' => 3, 'name' => 'شەکرەی سێ مانگی (HbA1c)', 'price' => 15000, 'type' => 'Blood Test', 'desc' => 'Glycated Hemoglobin'],
                ['id' => 4, 'name' => 'پشکنینی ڤیتامین دی (Vitamin D)', 'price' => 22000, 'original_price' => 30000, 'discount' => 27, 'type' => 'Vitamin Test', 'desc' => '25-OH Vitamin D'],
                ['id' => 5, 'name' => 'کاری جگەر (Liver Panel)', 'price' => 18000, 'original_price' => 24000, 'discount' => 25, 'type' => 'Liver Function', 'desc' => 'ALT, AST, Bilirubin'],
                ['id' => 6, 'name' => 'کاری گورچیلە (Kidney Panel)', 'price' => 12000, 'original_price' => 16000, 'discount' => 25, 'type' => 'Kidney Function', 'desc' => 'Urea & Creatinine'],
            ],
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

            return [
                'id' => (string) $t->id,
                'name' => $t->name,
                'name_ku' => $t->name,
                'name_en' => $t->name_en ?? $t->name,
                'name_ar' => $t->name_ar ?? $t->name,
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
                'title' => $nurse->specialty ?: 'پسپۆڕی وەرگرتنی نموونە و پشکنین',
                'specialty' => $nurse->specialty,
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

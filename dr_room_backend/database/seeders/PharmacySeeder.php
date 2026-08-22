<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Medication;
use App\Models\PharmacyOffer;
use App\Models\PharmacyReview;
use App\Models\MedicationCategory;
use Illuminate\Support\Facades\Hash;

class PharmacySeeder extends Seeder
{
    public function run(): void
    {
        // ─── 0. Medication Categories (پۆلێنەکانی دەرمان) ───────────────────
        $categories = [
            ['name' => 'هەمووی', 'name_ar' => 'الكل', 'name_en' => 'All', 'icon' => '💊', 'sort_order' => 1],
            ['name' => 'ئازارشکێن', 'name_ar' => 'مسكنات الألم', 'name_en' => 'Painkillers', 'icon' => '⚡', 'sort_order' => 2],
            ['name' => 'دژەهەوکردن', 'name_ar' => 'مضادات الالتهاب', 'name_en' => 'Anti-inflammatory', 'icon' => '🛡️', 'sort_order' => 3],
            ['name' => 'ڤیتامین', 'name_ar' => 'فيتامينات', 'name_en' => 'Vitamins', 'icon' => '🍊', 'sort_order' => 4],
            ['name' => 'گەدە و هەرس', 'name_ar' => 'المعدة والجهاز الهضمي', 'name_en' => 'Stomach & Digestion', 'icon' => '🫀', 'sort_order' => 5],
            ['name' => 'منداڵان', 'name_ar' => 'أدوية الأطفال', 'name_en' => 'Children', 'icon' => '👶', 'sort_order' => 6],
            ['name' => 'تەندروستی گشتی', 'name_ar' => 'صحة عامة', 'name_en' => 'General Health', 'icon' => '🌿', 'sort_order' => 7],
        ];

        foreach ($categories as $cat) {
            MedicationCategory::updateOrCreate([
                'name' => $cat['name']
            ], array_merge($cat, ['is_active' => true]));
        }
        // ─── 1. Pharmacy Shifa (Main Demo Pharmacy from Screenshot) ─────────────────────
        $shifaUser = User::where('email', 'shifa_pharmacy@example.com')->orWhere('phone', '07503332211')->first();
        if (!$shifaUser) {
            $shifaUser = User::create([
                'name' => 'دەرمانخانەی شیفا',
                'name_ar' => 'صيدلية الشفاء',
                'name_en' => 'Shifa Pharmacy',
                'email' => 'shifa_pharmacy@example.com',
                'phone' => '07503332211',
                'role' => 'pharmacy',
                'status' => 'approved',
                'password' => Hash::make('password'),
            ]);
        } else {
            $shifaUser->update([
                'name' => 'دەرمانخانەی شیفا',
                'name_ar' => 'صيدلية الشفاء',
                'name_en' => 'Shifa Pharmacy',
                'role' => 'pharmacy',
                'status' => 'approved',
            ]);
        }

        $shifaPharmacy = Pharmacy::updateOrCreate([
            'user_id' => $shifaUser->id
        ], [
            'image_path' => 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800',
            'bio' => 'دەرمانخانەی شیفا پێشکەشکردنی باشترین دەرمان و پێداویستی پزیشکی بە بەرزترین کوالێتی و گەیاندنی خێرا.',
            'rating' => 4.9,
            'total_reviews' => 48,
            'phone' => '07503332211',
            'location' => 'شەقامی ۱۰۰ مەتری - نزیک نەخۆشخانەی ڕزگاری',
            'city' => 'هەولێر',
            'delivery_fee' => 3000,
            'delivery_time' => '۲۰-۳۰ خولەک',
            'is_approved' => true,
            'is_open' => true,
            'facebook_url' => 'https://facebook.com/shifa.pharmacy',
            'latitude' => 36.1911,
            'longitude' => 44.0092,
            'gallery_images' => [
                'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800',
                'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800',
                'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800',
            ],
        ]);

        // Offers for Shifa Pharmacy
        PharmacyOffer::updateOrCreate([
            'user_id' => $shifaUser->id,
            'title' => 'ئۆفەری داشکاندنی دەرمانەکان 🎉',
        ], [
            'promo_code' => 'PHARMA10',
            'description' => 'داشکاندنی ١٠٪ بە کۆدی PHARMA10 لە کاتی کڕین',
            'discount_percentage' => 10.00,
            'is_active' => true,
            'start_date' => now(),
            'end_date' => now()->addDays(60),
            'image_path' => 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600',
        ]);

        // Medications for Shifa Pharmacy
        $shifaMeds = [
            [
                'name' => 'Augmentin (1g)',
                'category' => 'دژەهەوکردن',
                'description' => 'دژە هەوکردن و بەکتریای بەهێز بۆ چارەسەری هەوکردنی سنگ، قوڕگ و بۆڕییەکانی هەناسە',
                'price' => 9500,
                'original_price' => null,
                'discount_percent' => null,
                'badge' => 'ئۆرجیناڵ ⭐',
                'dosage_form' => 'پاکەت',
                'stock' => 30,
                'requires_prescription' => true,
                'image_path' => 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400',
            ],
            [
                'name' => 'Panadol Extra (500mg)',
                'category' => 'ئازارشکێن',
                'description' => 'بۆ چارەسەری ئازاری سەر، ددان و تای بەرز و ئازارە بەهێزەکان',
                'price' => 2000,
                'original_price' => 2500,
                'discount_percent' => 20,
                'badge' => 'داشکاندن 20%',
                'dosage_form' => 'پاکەت',
                'stock' => 45,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
            ],
            [
                'name' => 'Vitamin C 1000mg',
                'category' => 'ڤیتامین',
                'description' => 'تەقێنراو - بەهێزکەری بەرگری جەستە و کەمکردنەوەی هەڵامەت',
                'price' => 4500,
                'original_price' => 6000,
                'discount_percent' => 25,
                'badge' => 'داشکاندن 25%',
                'dosage_form' => 'قوتوو',
                'stock' => 25,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1550572017-ed24c5208f60?w=400',
            ],
            [
                'name' => 'Omeprazole 20mg',
                'category' => 'گەدە و هەرس',
                'description' => 'چارەسەری ترشەڵۆک و کەمکردنەوەی سوزش و دڵەکزێ',
                'price' => 3500,
                'original_price' => null,
                'discount_percent' => null,
                'badge' => null,
                'dosage_form' => 'پاکەت',
                'stock' => 0, // Out of stock demo
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400',
            ],
            [
                'name' => 'Baby Care Milk',
                'category' => 'منداڵان',
                'description' => 'شیری تەواوکەری خۆراکی منداڵان و کۆرپە دەوڵەمەند بە ڤیتامین و ئاسن',
                'price' => 14000,
                'original_price' => 16500,
                'discount_percent' => 15,
                'badge' => 'داشکاندن 15%',
                'dosage_form' => 'قوتوو',
                'stock' => 12,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400',
            ],
            [
                'name' => 'Ibuprofen 400mg',
                'category' => 'ئازارشکێن',
                'description' => 'بۆ ئازاری جومگە، ماسولکە و سەرئێشەی بەهێز',
                'price' => 3000,
                'original_price' => null,
                'discount_percent' => null,
                'badge' => null,
                'dosage_form' => 'پاکەت',
                'stock' => 18,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400',
            ],
            [
                'name' => 'Gaviscon Double Action',
                'category' => 'گەدە و هەرس',
                'description' => 'شرووبی هێورکەرەوەی دڵەکزێ و ترشانی گەدە',
                'price' => 7000,
                'original_price' => 8500,
                'discount_percent' => 18,
                'badge' => 'داشکاندن 18%',
                'dosage_form' => 'شوشە',
                'stock' => 20,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
            ],
            [
                'name' => 'Multi-Vitamin Gummies for Kids',
                'category' => 'منداڵان',
                'description' => 'شوکەری چێژبەخش بە تامی میوە بۆ بەهێزکردنی بیری منداڵ',
                'price' => 11000,
                'original_price' => 13500,
                'discount_percent' => 18,
                'badge' => 'نوێ',
                'dosage_form' => 'قوتوو',
                'stock' => 15,
                'requires_prescription' => false,
                'image_path' => 'https://images.unsplash.com/photo-1550572017-ed24c5208f60?w=400',
            ]
        ];

        foreach ($shifaMeds as $m) {
            Medication::updateOrCreate([
                'user_id' => $shifaUser->id,
                'name' => $m['name'],
            ], array_merge($m, ['is_active' => true]));
        }

        // ─── 2. City Pharmacy (دەرمانخانەی شاری پزیشکی) ─────────────────────
        $cityUser = User::where('email', 'city_pharmacy@example.com')->orWhere('phone', '07504445566')->first();
        if (!$cityUser) {
            $cityUser = User::create([
                'name' => 'دەرمانخانەی شاری پزیشکی (City Pharmacy)',
                'name_ar' => 'صيدلية المدينة الطبية',
                'name_en' => 'City Pharmacy',
                'email' => 'city_pharmacy@example.com',
                'phone' => '07504445566',
                'role' => 'pharmacy',
                'status' => 'approved',
                'password' => Hash::make('password'),
            ]);
        }

        Pharmacy::updateOrCreate([
            'user_id' => $cityUser->id
        ], [
            'image_path' => 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
            'bio' => 'دەرمانخانەی مۆدێرن لە هەولێر، بەردەستکردنی دەرمانی دەگمەن.',
            'rating' => 4.9,
            'total_reviews' => 62,
            'phone' => '07504445566',
            'location' => 'هەولێر، شەقامی ٤٠ مەتری - نزیک نەخۆشخانەی نانەکەلی',
            'city' => 'هەولێر',
            'delivery_fee' => 2500,
            'delivery_time' => '۱۵-۲۵ خولەک',
            'is_approved' => true,
            'is_open' => true,
            'gallery_images' => [
                'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
                'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=600',
            ]
        ]);

        Medication::updateOrCreate([
            'user_id' => $cityUser->id,
            'name' => 'Paracetamol 500mg',
        ], [
            'category' => 'ئازارشکێن',
            'description' => 'بۆ چارەسەری ئازاری کەم و مامناوەند',
            'price' => 1500,
            'stock' => 50,
            'is_active' => true,
            'image_path' => 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400'
        ]);

        // ─── 3. Zhyan Pharmacy (دەرمانخانەی ژیان) ─────────────────────
        $zhyanUser = User::where('email', 'zhyan_pharmacy@example.com')->orWhere('phone', '07707778899')->first();
        if (!$zhyanUser) {
            $zhyanUser = User::create([
                'name' => 'دەرمانخانەی ژیان (Zhyan 24/7 Pharmacy)',
                'name_ar' => 'صيدلية الحياة',
                'name_en' => 'Zhyan 24/7 Pharmacy',
                'email' => 'zhyan_pharmacy@example.com',
                'phone' => '07707778899',
                'role' => 'pharmacy',
                'status' => 'approved',
                'password' => Hash::make('password'),
            ]);
        }

        Pharmacy::updateOrCreate([
            'user_id' => $zhyanUser->id
        ], [
            'image_path' => 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=600',
            'bio' => 'خزمەتگوزاری بەردەوامی ٢٤ کاتژمێری لە شاری سلێمانی.',
            'rating' => 4.8,
            'total_reviews' => 35,
            'phone' => '07707778899',
            'location' => 'سلێمانی، شەقامی تووی مەلیك - بەرامبەر پارکی ئازادی',
            'city' => 'سلێمانی',
            'delivery_fee' => 3000,
            'delivery_time' => '۲۰-۳۰ خولەک',
            'is_approved' => true,
            'is_open' => true,
        ]);

        Medication::updateOrCreate([
            'user_id' => $zhyanUser->id,
            'name' => 'Amoxicillin 500mg',
        ], [
            'category' => 'دژەهەوکردن',
            'description' => 'دژە بەکتریا بۆ هەوکردنی سنگ و قوڕگ',
            'price' => 4000,
            'stock' => 40,
            'is_active' => true,
            'image_path' => 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400'
        ]);

        // ─── 4. Rozh Pharmacy (دەرمانخانەی ڕۆژ) ─────────────────────
        $rozhUser = User::where('email', 'rozh_pharmacy@example.com')->orWhere('phone', '07509990011')->first();
        if (!$rozhUser) {
            $rozhUser = User::create([
                'name' => 'دەرمانخانەی ڕۆژ (Rozh Pharmacy)',
                'name_ar' => 'صيدلية رۆژ',
                'name_en' => 'Rozh Pharmacy',
                'email' => 'rozh_pharmacy@example.com',
                'phone' => '07509990011',
                'role' => 'pharmacy',
                'status' => 'approved',
                'password' => Hash::make('password'),
            ]);
        }

        Pharmacy::updateOrCreate([
            'user_id' => $rozhUser->id
        ], [
            'image_path' => 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=600',
            'bio' => 'دەرمانخانەی ڕۆژ لە شاری دهۆک.',
            'rating' => 4.7,
            'total_reviews' => 19,
            'phone' => '07509990011',
            'location' => 'دهۆک، شەقامی گشتی کاوە - تەنیشت سەنتەری پزیشکی',
            'city' => 'دهۆک',
            'delivery_fee' => 2000,
            'delivery_time' => '۲۰-۳۵ خولەک',
            'is_approved' => true,
            'is_open' => false,
        ]);
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Nurse;
use Illuminate\Support\Facades\Hash;

class NurseSeeder extends Seeder
{
    public function run(): void
    {
        $nurses = [
            [
                'name' => 'ئاڤان ئەحمەد محەمەد',
                'name_en' => 'Avan Ahmed Mohammed',
                'name_ar' => 'أفان أحمد محمد',
                'phone' => '07509910001',
                'email' => 'avan.nurse@drroom.com',
                'specialty' => 'پەرستاری فریاکەوتن و برینپێچی',
                'specialty_en' => 'Emergency & Wound Care Nurse',
                'specialty_ar' => 'تمريض الطوارئ وتضميد الجروح',
                'bio' => 'پەرستاری خاوەن بڕوانامە بە زیاتر لە ٧ ساڵ ئەزموون لە چاودێری نەخۆش لە ماڵەوە، بەستنی کانولا، و دەرزی لێدان.',
                'city' => 'هەولێر',
                'address' => 'هەولێر، بەختیاری، شەقامی ٤٠ مەتری',
                'service_type' => 'home_nursing',
                'rating' => 4.9,
                'total_reviews' => 58,
                'fee' => 25000,
                'experience_years' => 7,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'ڕێبوار کەریم عەزیز',
                'name_en' => 'Rebwar Karim Aziz',
                'name_ar' => 'ريبوار كريم عزيز',
                'phone' => '07509910002',
                'email' => 'rebwar.nurse@drroom.com',
                'specialty' => 'پەرستاری برین و بەستنی کانولا',
                'specialty_en' => 'Wound Care & IV Cannulation',
                'specialty_ar' => 'العناية بالجروح وتركيب الكانيولا',
                'bio' => 'شارەزا لە پێدانی چارەسەری دەماری و گۆڕینی برینی نەشتەرگەری و پێدانی دەرمان.',
                'city' => 'سلێمانی',
                'address' => 'سلێمانی، سەرچنار',
                'service_type' => 'home_nursing',
                'rating' => 4.8,
                'total_reviews' => 42,
                'fee' => 20000,
                'experience_years' => 5,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'سروە عوسمان مستەفا',
                'name_en' => 'Srwa Osman Mustafa',
                'name_ar' => 'سروة عثمان مصطفى',
                'phone' => '07509910003',
                'email' => 'srwa.nurse@drroom.com',
                'specialty' => 'چاودێری بەساڵاچووان و دەرزی لێدان',
                'specialty_en' => 'Elderly Care & Injections',
                'specialty_ar' => 'رعاية كبار السن والحقن',
                'bio' => 'پێشکەشکردنی چاودێری تەواو بۆ بەساڵاچووان، پێوانی پەستانی خوێن و شەکرە و پێدانی دەرمان.',
                'city' => 'دهۆک',
                'address' => 'دهۆک، ماسیکێ',
                'service_type' => 'home_nursing',
                'rating' => 4.9,
                'total_reviews' => 67,
                'fee' => 30000,
                'experience_years' => 8,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'ئالان هێمن جەلال',
                'name_en' => 'Alan Hemin Jalal',
                'name_ar' => 'آلان هيمن جلال',
                'phone' => '07509910004',
                'email' => 'alan.nurse@drroom.com',
                'specialty' => 'پەرستاری گشتی و دەرزی وەرگرتن',
                'specialty_en' => 'General Nursing & Injections',
                'specialty_ar' => 'تمريض عام وحقن وريدي',
                'bio' => 'ئامادە بۆ خزمەتگوزاری ٢٤ کاتژمێری لە هەولێر و دەوروبەری.',
                'city' => 'هەولێر',
                'address' => 'هەولێر، ڕاستی',
                'service_type' => 'home_nursing',
                'rating' => 4.7,
                'total_reviews' => 35,
                'fee' => 20000,
                'experience_years' => 4,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'ژینۆ تارق سالح',
                'name_en' => 'Zhino Tariq Salih',
                'name_ar' => 'جينو طارق صالح',
                'phone' => '07509910005',
                'email' => 'zhino.nurse@drroom.com',
                'specialty' => 'پەرستاری تایبەت بە منداڵان',
                'specialty_en' => 'Pediatric Home Nurse',
                'specialty_ar' => 'تمريض الأطفال المنزلي',
                'bio' => 'پسپۆڕ لە چاودێری کۆرپە و منداڵان و پێدانی چارەسەر بە شێوازی هێمن و زانستی.',
                'city' => 'سلێمانی',
                'address' => 'سلێمانی، بەختیاری',
                'service_type' => 'home_nursing',
                'rating' => 4.9,
                'total_reviews' => 73,
                'fee' => 35000,
                'experience_years' => 9,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'هەڵمەت عەلی حەسەن',
                'name_en' => 'Halmat Ali Hassan',
                'name_ar' => 'هلمت علي حسن',
                'phone' => '07509910006',
                'email' => 'halmat.nurse@drroom.com',
                'specialty' => 'چاودێری چڕ و گۆڕینی برین',
                'specialty_en' => 'ICU & Advanced Wound Care',
                'specialty_ar' => 'العناية المركزة وتضميد الجروح المتقدم',
                'bio' => 'ئەزموونی چەندین ساڵە لە نەخۆشخانەکانی فریاکەوتن و چاودێری نەخۆشی تایبەت لە ماڵەوە.',
                'city' => 'هەولێر',
                'address' => 'هەولێر، ئازادی',
                'service_type' => 'home_nursing',
                'rating' => 4.8,
                'total_reviews' => 49,
                'fee' => 25000,
                'experience_years' => 6,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'شیلان نەبەز فەریق',
                'name_en' => 'Shilan Nabaz Fariq',
                'name_ar' => 'شيلان نبز فريق',
                'phone' => '07509910007',
                'email' => 'shilan.nurse@drroom.com',
                'specialty' => 'پەرستاری ماڵەوە و چاودێری پاش نەشتەرگەری',
                'specialty_en' => 'Post-op Recovery & Home Care',
                'specialty_ar' => 'رعاية ما بعد الجراحة والتمريض المنزلي',
                'bio' => 'چاودێری ورد و بەردەوام بۆ نەخۆش دوای نەشتەرگەری و گۆڕینی باندج و کاتی دەرمان.',
                'city' => 'دهۆک',
                'address' => 'دهۆک، نزارکێ',
                'service_type' => 'home_nursing',
                'rating' => 4.9,
                'total_reviews' => 61,
                'fee' => 30000,
                'experience_years' => 7,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
            [
                'name' => 'کاردۆ فەرهاد مەحموود',
                'name_en' => 'Kardo Farhad Mahmood',
                'name_ar' => 'كاردو فرهاد محمود',
                'phone' => '07509910008',
                'email' => 'kardo.nurse@drroom.com',
                'specialty' => 'پەرستاری فریاکەوتنی خێرا',
                'specialty_en' => 'Rapid Emergency Response',
                'specialty_ar' => 'استجابة الطوارئ السريعة',
                'bio' => 'پەرستاری کارامە لە فریاگوزاری و کارەکانی کاتژمێری شەوان لە کەرکووک.',
                'city' => 'کەرکووک',
                'address' => 'کەرکووک، ڕەحیماوا',
                'service_type' => 'home_nursing',
                'rating' => 4.8,
                'total_reviews' => 39,
                'fee' => 20000,
                'experience_years' => 5,
                'is_available' => true,
                'is_approved' => true,
                'image_path' => 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=400&h=300&fit=crop&crop=face,top&q=80',
            ],
        ];

        foreach ($nurses as $nurseData) {
            $user = User::where('email', $nurseData['email'])
                ->orWhere('phone', $nurseData['phone'])
                ->first();

            if (!$user) {
                $user = User::create([
                    'name' => $nurseData['name'],
                    'name_en' => $nurseData['name_en'],
                    'name_ar' => $nurseData['name_ar'],
                    'email' => $nurseData['email'],
                    'phone' => $nurseData['phone'],
                    'role' => 'nurse',
                    'status' => 'approved',
                    'password' => Hash::make('nurse123456'),
                ]);
            } else {
                $user->update([
                    'name' => $nurseData['name'],
                    'name_en' => $nurseData['name_en'],
                    'name_ar' => $nurseData['name_ar'],
                    'role' => 'nurse',
                    'status' => 'approved',
                ]);
            }

            $nurseFields = $nurseData;
            unset($nurseFields['name'], $nurseFields['name_en'], $nurseFields['name_ar'], $nurseFields['email'], $nurseFields['phone']);
            $nurseFields['phone'] = $nurseData['phone'];

            Nurse::updateOrCreate(
                ['user_id' => $user->id],
                array_merge($nurseFields, ['user_id' => $user->id])
            );
        }
    }
}

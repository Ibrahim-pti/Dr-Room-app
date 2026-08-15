<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use App\Models\Doctor;
use App\Models\DoctorService;
use App\Models\DoctorSchedule;
use App\Models\DoctorReview;
use App\Models\Pharmacy;
use App\Models\Medication;
use App\Models\PharmacyOffer;
use App\Models\Lab;
use App\Models\LabTest;
use App\Models\Nurse;
use App\Models\Banner;
use App\Models\Article;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Admin User
        $admin = User::firstOrCreate(
            ['email' => 'admin@drroom.com'],
            [
                'name' => 'Admin User',
                'phone' => '07500000000',
                'role' => 'admin',
                'status' => 'approved',
                'password' => Hash::make('admin123456'),
            ]
        );

        // 2. Categories / Medical Specialties
        $categories = [
            ['name' => 'دڵ و لوولەکانی خوێن', 'name_en' => 'Cardiology', 'name_ar' => 'أمراض القلب', 'icon' => 'heart'],
            ['name' => 'پێست و جوانکاری', 'name_en' => 'Dermatology', 'name_ar' => 'الجلدية والتجميل', 'icon' => 'dermatology'],
            ['name' => 'منداڵان و ساوایان', 'name_en' => 'Pediatrics', 'name_ar' => 'طب الأطفال', 'icon' => 'child'],
            ['name' => 'ئێسک و جومگە', 'name_en' => 'Orthopedics', 'name_ar' => 'العظام والمفاصل', 'icon' => 'bone'],
            ['name' => 'مێشک و دەمار', 'name_en' => 'Neurology', 'name_ar' => 'المخ والأعصاب', 'icon' => 'brain'],
            ['name' => 'چاو و بینین', 'name_en' => 'Ophthalmology', 'name_ar' => 'طب العيون', 'icon' => 'eye'],
            ['name' => 'ددان و پووک', 'name_en' => 'Dentistry', 'name_ar' => 'طب الأسنان', 'icon' => 'tooth'],
            ['name' => 'نەشتەرگەری گشتی', 'name_en' => 'General Surgery', 'name_ar' => 'الجراحة العامة', 'icon' => 'surgery'],
        ];

        foreach ($categories as $cat) {
            Category::firstOrCreate(['name' => $cat['name']], $cat);
        }

        // 3. Doctors
        $doctorsData = [
            [
                'name' => 'د. ئاری فاروق حمە',
                'name_en' => 'Dr. Ari Farooq Hama',
                'name_ar' => 'د. آري فاروق حمه',
                'specialty' => 'دڵ و لوولەکانی خوێن',
                'specialty_en' => 'Cardiology',
                'specialty_ar' => 'أمراض القلب',
                'bio' => 'پزیشکی پسپۆڕی نەخۆشییەکانی دڵ و قەستەرە. ئەندامی کۆمەڵەی دڵی ئەوروپی.',
                'bio_en' => 'Specialist Cardiologist & Interventionalist. Member of European Society of Cardiology.',
                'bio_ar' => 'أخصائي أمراض القلب والقسطرة. عضو جمعية القلب الأوروبية.',
                'clinic_name' => 'نەخۆشخانەی CMC - هەولێر',
                'clinic_name_en' => 'CMC Hospital - Erbil',
                'clinic_name_ar' => 'مستشفى CMC - أربيل',
                'address' => 'هەولێر - شەقامی ١٠٠ مەتری',
                'address_en' => 'Erbil - 100m Street',
                'address_ar' => 'أربيل - شارع 100م',
                'experience_years' => '14',
                'rating' => 4.9,
                'total_reviews' => 48,
                'consultation_fee' => 30000,
                'is_approved' => true,
                'phone' => '07501112233',
            ],
            [
                'name' => 'د. هێرۆ ئەحمەد عەزیز',
                'name_en' => 'Dr. Hero Ahmed Aziz',
                'name_ar' => 'د. هيرو أحمد عزيز',
                'specialty' => 'پێست و جوانکاری',
                'specialty_en' => 'Dermatology',
                'specialty_ar' => 'الجلدية والتجميل',
                'bio' => 'پسپۆڕی نەخۆشییەکانی پێست و لیزەر و جوانکاری. چارەسەری پەڵە و کێشەکانی قژ.',
                'bio_en' => 'Dermatologist & Aesthetic Laser Specialist. Hair and skin rejuvenation.',
                'bio_ar' => 'أخصائية الأمراض الجلدية والليزر والتجميل.',
                'clinic_name' => 'تاوەری سمارت - سلێمانی',
                'clinic_name_en' => 'Smart Health Tower - Sulaymaniyah',
                'clinic_name_ar' => 'برج سمارت - السليمانية',
                'address' => 'سلێمانی - شەقامی بازنەیی مەولەوی',
                'address_en' => 'Sulaymaniyah - Mawlawi Street',
                'address_ar' => 'السليمانية - شارع مولوي',
                'experience_years' => '11',
                'rating' => 4.8,
                'total_reviews' => 36,
                'consultation_fee' => 25000,
                'is_approved' => true,
                'phone' => '07502223344',
            ],
            [
                'name' => 'د. زانا حەمە ساڵح',
                'name_en' => 'Dr. Zana Hama Salih',
                'name_ar' => 'د. زانا حمه صالح',
                'specialty' => 'ئێسک و جومگە',
                'specialty_en' => 'Orthopedics',
                'specialty_ar' => 'العظام والمفاصل',
                'bio' => 'پسپۆڕی نەشتەرگەری ئێسک و بڕبڕەی پشت و گۆڕینی جومگەکان بە ناوبین (ئەندۆسکۆپی).',
                'bio_en' => 'Consultant Orthopedic & Spine Surgeon. Joint replacement and arthroscopy.',
                'bio_ar' => 'استشاري جراحة العظام والعمود الفقري وتبديل المفاصل.',
                'clinic_name' => 'نەخۆشخانەی میدیا - هەولێر',
                'clinic_name_en' => 'Medya Hospital - Erbil',
                'clinic_name_ar' => 'مستشفى ميديا - أربيل',
                'address' => 'هەولێر - شەقامی ٦٠ مەتری',
                'address_en' => 'Erbil - 60m Street',
                'address_ar' => 'أربيل - شارع 60م',
                'experience_years' => '16',
                'rating' => 4.9,
                'total_reviews' => 52,
                'consultation_fee' => 35000,
                'is_approved' => true,
                'phone' => '07503334455',
            ],
            [
                'name' => 'د. دەریا کەریم قادر',
                'name_en' => 'Dr. Darya Karim Qadir',
                'name_ar' => 'د. دريا كريم قادر',
                'specialty' => 'منداڵان و ساوایان',
                'specialty_en' => 'Pediatrics',
                'specialty_ar' => 'طب الأطفال',
                'bio' => 'پسپۆڕی نەخۆشییە باوەکانی منداڵان و گەشە و پێکوتە (ڤاکسین).',
                'bio_en' => 'Pediatrician & Child Growth Development Specialist.',
                'bio_ar' => 'أخصائية طب الأطفال وحديثي الولادة والنمو.',
                'clinic_name' => 'نەخۆشخانەی ڤاژین - دهۆک',
                'clinic_name_en' => 'Vajeen Hospital - Duhok',
                'clinic_name_ar' => 'مستشفى فاجين - دهوك',
                'address' => 'دهۆک - تاوەری کەی ئاڕ ئۆ',
                'address_en' => 'Duhok - KRO Tower',
                'address_ar' => 'دهوك - برج كي آر أو',
                'experience_years' => '9',
                'rating' => 4.7,
                'total_reviews' => 29,
                'consultation_fee' => 20000,
                'is_approved' => true,
                'phone' => '07504445566',
            ],
        ];

        foreach ($doctorsData as $docData) {
            $docUser = User::firstOrCreate(
                ['phone' => $docData['phone']],
                [
                    'name' => $docData['name'],
                    'email' => strtolower(str_replace([' ', '.'], '', $docData['name_en'])) . '@drroom.com',
                    'role' => 'doctor',
                    'status' => 'approved',
                    'password' => Hash::make('doctor123'),
                ]
            );

            $docFields = $docData;
            unset($docFields['name'], $docFields['name_en'], $docFields['name_ar']);

            $doc = Doctor::firstOrCreate(
                ['user_id' => $docUser->id],
                array_merge($docFields, ['user_id' => $docUser->id])
            );

            // Add Doctor Services
            DoctorService::firstOrCreate(
                ['doctor_id' => $doc->id, 'name_ckb' => 'پشکنینی گشتی کلینیک'],
                [
                    'name_en' => 'General Clinical Consultation',
                    'name_ar' => 'فحص واستشارة عامة',
                    'price' => $docData['consultation_fee'],
                ]
            );

            // Add Schedules
            DoctorSchedule::firstOrCreate(
                ['doctor_id' => $doc->id, 'day_of_week' => 'Sunday'],
                [
                    'start_time' => '16:00',
                    'end_time' => '20:00',
                    'slot_minutes' => 20,
                    'is_available' => true,
                ]
            );
            DoctorSchedule::firstOrCreate(
                ['doctor_id' => $doc->id, 'day_of_week' => 'Tuesday'],
                [
                    'start_time' => '16:00',
                    'end_time' => '20:00',
                    'slot_minutes' => 20,
                    'is_available' => true,
                ]
            );
        }

        // 4. Pharmacies & Medications & Offers
        $pharmaciesData = [
            [
                'name' => 'دەرمانخانەی شیفا',
                'name_en' => 'Shifa Pharmacy',
                'name_ar' => 'صيدلية الشفاء',
                'location' => 'شەقامی ١٠٠ مەتری - نزیک نەخۆشخانەی ڕزگاری',
                'location_en' => '100m Street - Near Rizgary Hospital',
                'location_ar' => 'شارع 100م - قرب مستشفى رزكاري',
                'phone' => '07507778899',
            ],
            [
                'name' => 'دەرمانخانەی سمارت',
                'name_en' => 'Smart Pharmacy',
                'name_ar' => 'صيدلية سمارت',
                'location' => 'شەقامی سالم - تاوەری پزیشکی',
                'location_en' => 'Salim Street - Medical Tower',
                'location_ar' => 'شارع سالم - البرج الطبي',
                'phone' => '07508889900',
            ],
        ];

        $medsList = [
            ['name' => 'Panadol Extra (500mg)', 'price' => 2000, 'stock' => 150, 'desc' => 'بۆ چارەسەری ئازاری سەر، ددان و تای بەرز'],
            ['name' => 'Augmentin (1g)', 'price' => 9500, 'stock' => 60, 'desc' => 'دژە هەوکردن و بەکتریای بەهێز'],
            ['name' => 'Nexium (40mg)', 'price' => 14000, 'stock' => 45, 'desc' => 'بۆ کەمکردنەوەی ترشەڵۆک و کڕانەوەی گەدە'],
            ['name' => 'Lipitor (20mg)', 'price' => 18000, 'stock' => 35, 'desc' => 'دابەزاندنی کۆلیسترۆڵ و چەوری خوێن'],
            ['name' => 'Vitamin D3 (50,000 IU)', 'price' => 8000, 'stock' => 90, 'desc' => 'قەرەبووی کەمی ڤیتامین دی بۆ بەهێزکردنی ئێسک'],
            ['name' => 'Omega-3 Fish Oil (1000mg)', 'price' => 12500, 'stock' => 40, 'desc' => 'تەندروستی دڵ و مێشک و بەرگری جەستە'],
        ];

        foreach ($pharmaciesData as $pharmData) {
            $pharmUser = User::firstOrCreate(
                ['phone' => $pharmData['phone']],
                [
                    'name' => $pharmData['name'],
                    'email' => strtolower(str_replace(' ', '', $pharmData['name_en'])) . '@drroom.com',
                    'role' => 'pharmacy',
                    'status' => 'approved',
                    'password' => Hash::make('pharmacy123'),
                ]
            );

            $pFields = $pharmData;
            unset($pFields['name'], $pFields['name_en'], $pFields['name_ar']);

            Pharmacy::firstOrCreate(
                ['user_id' => $pharmUser->id],
                array_merge($pFields, ['user_id' => $pharmUser->id, 'is_approved' => true])
            );

            foreach ($medsList as $m) {
                Medication::firstOrCreate(
                    ['user_id' => $pharmUser->id, 'name' => $m['name']],
                    [
                        'description' => $m['desc'],
                        'price' => $m['price'],
                        'stock' => $m['stock'],
                        'is_active' => true,
                    ]
                );
            }

            PharmacyOffer::firstOrCreate(
                ['user_id' => $pharmUser->id, 'title' => 'داشکاندنی سەرجەم ڤیتامینەکان'],
                [
                    'description' => 'داشکاندنی تایبەتی ٢٠٪ بۆ هەموو جۆرەکانی تەواوکەری خۆراکی.',
                    'discount_percentage' => 20.0,
                    'is_active' => true,
                ]
            );
        }

        // 5. Laboratories & Lab Tests
        $labData = [
            'name' => 'تاقیگەی پزیشکی ڕازی',
            'name_en' => 'Razi Medical Laboratory',
            'name_ar' => 'مختبر الرازي الطبي',
            'location' => 'هەولێر - شەقامی پزیشکان',
            'location_en' => 'Erbil - Doctors Street',
            'location_ar' => 'أربيل - شارع الأطباء',
            'phone' => '07505556677',
            'is_approved' => true,
        ];

        $labUser = User::firstOrCreate(
            ['phone' => $labData['phone']],
            [
                'name' => $labData['name'],
                'email' => 'razi.lab@drroom.com',
                'role' => 'lab',
                'status' => 'approved',
                'password' => Hash::make('lab123456'),
            ]
        );

        $lFields = $labData;
        unset($lFields['name'], $lFields['name_en'], $lFields['name_ar']);

        $lab = Lab::firstOrCreate(
            ['user_id' => $labUser->id],
            array_merge($lFields, ['user_id' => $labUser->id])
        );

        $tests = [
            ['name' => 'پشکنینی گشتی خوێن (CBC)', 'price' => 10000, 'type' => 'Blood Test', 'desc' => 'Complete Blood Count'],
            ['name' => 'چەوری و کۆلیسترۆڵ (Lipid Profile)', 'price' => 15000, 'type' => 'Blood Test', 'desc' => 'Cholesterol & Triglycerides'],
            ['name' => 'شەکرەی سێ مانگی (HbA1c)', 'price' => 15000, 'type' => 'Blood Test', 'desc' => 'Glycated Hemoglobin'],
            ['name' => 'پشکنینی ڤیتامین دی (Vitamin D)', 'price' => 20000, 'type' => 'Vitamin Test', 'desc' => '25-OH Vitamin D'],
            ['name' => 'کاری جگەر (Liver Function Test)', 'price' => 18000, 'type' => 'Liver Panel', 'desc' => 'ALT, AST, Bilirubin'],
            ['name' => 'کاری گورچیلە (Kidney Function Test)', 'price' => 12000, 'type' => 'Kidney Panel', 'desc' => 'Urea & Creatinine'],
        ];

        foreach ($tests as $t) {
            LabTest::firstOrCreate(
                ['lab_id' => $lab->id, 'name' => $t['name']],
                [
                    'price' => $t['price'],
                    'type' => $t['type'],
                    'description' => $t['desc'],
                    'is_active' => true,
                ]
            );
        }

        // 6. Home Care Nurses
        $nurseData = [
            'name' => 'شاژوان عوسمان ڕەشید',
            'name_en' => 'Shajwan Osman Rashid',
            'name_ar' => 'شاجوان عثمان رشيد',
            'specialty' => 'پەرستاری فریاکەوتن و برینپێچی',
            'specialty_en' => 'Emergency & Wound Care Nurse',
            'specialty_ar' => 'تمريض الطوارئ وتضميد الجروح',
            'phone' => '07506667788',
            'is_approved' => true,
        ];

        $nurseUser = User::firstOrCreate(
            ['phone' => $nurseData['phone']],
            [
                'name' => $nurseData['name'],
                'email' => 'shajwan.nurse@drroom.com',
                'role' => 'nurse',
                'status' => 'approved',
                'password' => Hash::make('nurse123456'),
            ]
        );

        $nFields = $nurseData;
        unset($nFields['name'], $nFields['name_en'], $nFields['name_ar']);

        Nurse::firstOrCreate(
            ['user_id' => $nurseUser->id],
            array_merge($nFields, ['user_id' => $nurseUser->id])
        );

        // 7. Banners
        Banner::firstOrCreate(
            ['title' => 'خزمەتگوزاری پەرستاری ٢٤ کاتژمێری لە ماڵەوە'],
            [
                'title_en' => '24/7 Home Nursing & Emergency Care',
                'title_ar' => 'خدمة التمريض المنزلي على مدار 24 ساعة',
                'image_path' => 'assets/images/banner1.png',
                'link_url' => '/nursing',
                'is_active' => true,
                'sort_order' => 1,
            ]
        );
        Banner::firstOrCreate(
            ['title' => 'داشکاندنی ٢٠٪ بۆ پشکنینە تاقیگەییەکان لە ماڵەوە'],
            [
                'title_en' => '20% Off Home Blood & Lab Tests',
                'title_ar' => 'خصم 20% على الفحوصات المختبرية المنزلية',
                'image_path' => 'assets/images/banner2.png',
                'link_url' => '/labs',
                'is_active' => true,
                'sort_order' => 2,
            ]
        );

        // 8. Health Articles
        $articles = [
            [
                'title' => 'ڕێنماییە سەرەتاییەکانی فریاکەوتنی CPR بۆ وەستانی دڵ',
                'title_en' => 'First Aid CPR Guidelines for Cardiac Arrest',
                'title_ar' => 'دليل الإسعافات الأولية للإنعاش قلبي رئوي (CPR)',
                'content' => "کاتێک کەسێک لەناکاو دەکەوێت و هەناسەدانی دەوەستێت، ئەنجامدانی فریاکەوتنی خێرا (CPR) دەتوانێت ژیانی ڕزگار بکات.\n\n١. بەپەلە پەیوەندی بە ژمارەی فریاکەوتن (122) بکە.\n٢. دەستت بخەرە سەر ناوەڕاستی سنگ.\n٣. بە توندی و خێرایی (١٠٠-١٢٠ جار لە خولەکێکدا) پەستاوتنی سنگ ئەنجام بدە.\n٤. تا گەیشتنی تیمەکانی تەندروستی بەردەوام بە.",
                'content_en' => "When someone suddenly collapses and stops breathing, immediate CPR can save their life.\n\n1. Call emergency services immediately.\n2. Place your hands in the center of the chest.\n3. Push hard and fast (100-120 compressions per minute).\n4. Continue until medical help arrives.",
                'content_ar' => "عندما ينهار شخص ما فجأة ويتوقف عن التنفس، يمكن للإنعاش القلبي الرئوي الفوري أن ينقذ حياته.\n\n1. اتصل بالطوارئ فوراً.\n2. ضع يديك في منتصف الصدر.\n3. اضغط بقوة وسرعة.\n4. استمر حتى وصول المساعدة الطبية.",
                'is_published' => true,
            ],
            [
                'title' => 'نیشانە سەرەتاییەکانی جەڵتەی دڵ و ڕێکارە فریاگوزارییەکان',
                'title_en' => 'Early Symptoms of Heart Attack and Emergency Measures',
                'title_ar' => 'الأعراض المبكرة للنوبة القلبية والإجراءات الطارئة',
                'content' => "جەڵتەی دڵ یەکێکە لە حاڵەتە کتوپڕەکان کە پێویستی بە وەڵامدانەوەی خێرا هەیە. نیشانە سەرەتاییەکان بریتین لە:\n- ئازار و پەستانی توند لە ناوەڕاستی سنگ.\n- ئازارێک کە بەرەو قۆڵی چەپ، مل یان فەک ڕادەکێشێت.\n- هەناسەتەنگی و ئارەقکردنەوەی سارد.\nلەکاتی بەدیبوونی ئەم نیشانانە، نەخۆشەکە لە شوێنێکی ئارام دابنیشێنە و بەپەلە داوای فریاکەوتن بکە.",
                'content_en' => "A heart attack requires immediate medical attention. Key early signs include chest pain, radiating discomfort to left arm, shortness of breath, and cold sweat.",
                'content_ar' => "تتطلب النوبة القلبية عناية طبية فورية. تشمل العلامات المبكرة الرئيسية ألم الصدر والألم الممتد للذراع والأيسر وضيق التنفس.",
                'is_published' => true,
            ],
            [
                'title' => 'گرنگی ڤیتامین دی بۆ ئێسک و سیستەمی بەرگری لەش',
                'title_en' => 'Importance of Vitamin D for Bone & Immunity',
                'title_ar' => 'أهمية فيتامين د لصحة العظام وجهاز المناعة',
                'content' => "ڤیتامین دی ڕۆڵێکی سەرەکی دەگێڕێت لە مژینی کالسیۆم و پتەوکردنی ئێسک و ددانەکان، لەگەڵ پاراستنی لەش لە نەخۆشییە درمەکان.\nنیشانەکانی کەمی ڤیتامین دی بریتین لە ماندوێتی بەردەوام، ئازاری ئێسک و ماسولکە، و هەڵوەرینی قژ.",
                'content_en' => "Vitamin D is essential for calcium absorption, strong bones, and immune function.",
                'content_ar' => "يلعب فيتامين د دوراً حيوياً في امتصاص الكالسيوم وتقوية العظام والمناعة.",
                'is_published' => true,
            ],
        ];

        foreach ($articles as $articleData) {
            Article::firstOrCreate(['title' => $articleData['title']], $articleData);
        }

        // 9. App Notifications
        \App\Models\AppNotification::firstOrCreate(
            ['title' => 'بەخێربێن بۆ ئەپڵیکەیشنی دکتۆر ڕووم!'],
            [
                'title_en' => 'Welcome to DrRoom Healthcare App!',
                'title_ar' => 'أهلاً بكم في تطبيق دكتور روم الطبي!',
                'message' => 'خۆشحاڵین بە هاتنت. ئێستا دەتوانیت بە ئاسانی نۆرەی پزیشک بگریت، دەرمان بکڕیت و پشکنینی تاقیگە ئەنجام بدەیت.',
                'message_en' => 'We are glad to have you. You can now easily book doctors, order medications, and request home lab tests.',
                'message_ar' => 'يسعدنا انضمامكم. يمكنك الآن حجز الأطباء وطلب الأدوية والفحوصات المنزلية بسهولة.',
                'type' => 'general',
                'is_read' => false,
            ]
        );
        \App\Models\AppNotification::firstOrCreate(
            ['title' => 'داشکاندنی تایبەت بۆ بەکارهێنەرانی نوێ'],
            [
                'title_en' => 'Special Discount for New Members',
                'title_ar' => 'خصم خاص للأعضاء الجدد',
                'message' => 'کۆدی داشکاندنی DRROOM20 بەکاربێنە بۆ بەدەستهێنانی داشکاندنی ٢٠٪ لە یەکەم داواکاری دەرماندا.',
                'message_en' => 'Use promo code DRROOM20 to get 20% off on your first pharmacy medication order.',
                'message_ar' => 'استخدم كود الخصم DRROOM20 للحصول على خصم 20% على أول طلب أدوية.',
                'type' => 'promo',
                'is_read' => false,
            ]
        );
    }
}


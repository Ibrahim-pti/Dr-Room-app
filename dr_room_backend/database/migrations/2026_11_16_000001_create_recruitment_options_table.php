<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recruitment_options', function (Blueprint $table) {
            $table->id();
            $table->string('type', 20)->index(); // 'education' | 'skill'
            $table->string('option_key', 80);
            $table->string('label_ckb');
            $table->string('label_kmr')->nullable();
            $table->string('label_ar')->nullable();
            $table->string('label_en')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['type', 'option_key']);
        });

        $now = now();
        $defaults = [
            // Education levels
            [
                'type' => 'education',
                'option_key' => 'diploma_lab',
                'label_ckb' => 'دبلۆم لە شیکاری نەخۆشییەکان',
                'label_kmr' => 'دبلۆم د شیکاریا نەخۆشیان دا',
                'label_ar' => 'دبلوم تحليلات مرضية',
                'label_en' => 'Diploma in Medical Lab Science',
                'sort_order' => 1,
            ],
            [
                'type' => 'education',
                'option_key' => 'bsc_lab',
                'label_ckb' => 'بەکالۆریۆس لە شیکاری نەخۆشییەکان / بایۆلۆجی',
                'label_kmr' => 'بەکالۆریۆس د شیکاریا نەخۆشیان / بایۆلۆجی دا',
                'label_ar' => 'بكالوريوس تحليلات مرضية / علوم حياة',
                'label_en' => 'B.Sc. in Medical Lab / Biology',
                'sort_order' => 2,
            ],
            [
                'type' => 'education',
                'option_key' => 'diploma_nursing',
                'label_ckb' => 'دبلۆم لە پەرستاری',
                'label_kmr' => 'دبلۆم د پەرستاریێ دا',
                'label_ar' => 'دبلوم تمريض',
                'label_en' => 'Diploma in Nursing',
                'sort_order' => 3,
            ],
            [
                'type' => 'education',
                'option_key' => 'bsc_nursing',
                'label_ckb' => 'بەکالۆریۆس لە پەرستاری',
                'label_kmr' => 'بەکالۆریۆس د پەرستاریێ دا',
                'label_ar' => 'بكالوريوس علوم تمريض',
                'label_en' => 'B.Sc. in Nursing',
                'sort_order' => 4,
            ],
            [
                'type' => 'education',
                'option_key' => 'high_school_course',
                'label_ckb' => 'ئامادەیی + خولی فێرکاری پەرستاری باوەڕپێکراو',
                'label_kmr' => 'ئامادەیی + خولا پەرستاریا باوەرپێکری',
                'label_ar' => 'إعدادية + دورة تمريض معتمدة',
                'label_en' => 'High School + Accredited Nursing Course',
                'sort_order' => 5,
            ],
            [
                'type' => 'education',
                'option_key' => 'other',
                'label_ckb' => 'بڕوانامەی تر / گشتی',
                'label_kmr' => 'باوەرنامەیا دی / گشتی',
                'label_ar' => 'مؤهل آخر / عام',
                'label_en' => 'Other Qualification',
                'sort_order' => 6,
            ],

            // Clinical skills
            [
                'type' => 'skill',
                'option_key' => 'venipuncture',
                'label_ckb' => 'کێشانی خوێن و دەرهێنانی نموونە بە پڕۆفیشناڵی',
                'label_kmr' => 'کێشانا خوینێ ب شێوەیەکێ پرۆفیشناڵ',
                'label_ar' => 'سحب الدم الوريدي باحترافية',
                'label_en' => 'Professional Venipuncture & Blood Draw',
                'sort_order' => 1,
            ],
            [
                'type' => 'skill',
                'option_key' => 'pediatric_draw',
                'label_ckb' => 'خوێن وەرگرتن بۆ منداڵان و دۆزینەوەی خوێنهێنەری سەخت',
                'label_kmr' => 'وەرگرتنا خوینا زارۆکان و دەمارێن زەحمەت',
                'label_ar' => 'سحب عينات الأطفال والأوردة الصعبة',
                'label_en' => 'Pediatric & Difficult Vein Phlebotomy',
                'sort_order' => 2,
            ],
            [
                'type' => 'skill',
                'option_key' => 'cannula_iv',
                'label_ckb' => 'دانانی کانۆلا و پێدانی سروم (IV)',
                'label_kmr' => 'دانانا کانۆلا و پێدانا سرۆمی (IV)',
                'label_ar' => 'تركيب الكانيولا وإعطاء السيروم الوريدي',
                'label_en' => 'IV Cannulation & Fluid Therapy',
                'sort_order' => 3,
            ],
            [
                'type' => 'skill',
                'option_key' => 'injections',
                'label_ckb' => 'دەرزیدان (ماسولکە و ژێرپێست)',
                'label_kmr' => 'دەرزیدان (ماسوولکە و بن پێستی)',
                'label_ar' => 'الحقن العضلي وتحت الجلد',
                'label_en' => 'IM & Subcutaneous Injections',
                'sort_order' => 4,
            ],
            [
                'type' => 'skill',
                'option_key' => 'wound_care',
                'label_ckb' => 'پانسمان و پێچانەوەی برین',
                'label_kmr' => 'پانسمان و پێچانا برینان',
                'label_ar' => 'تضميد الجروح والعناية المعقمة',
                'label_en' => 'Sterile Wound Dressing & Care',
                'sort_order' => 5,
            ],
            [
                'type' => 'skill',
                'option_key' => 'vital_signs',
                'label_ckb' => 'پێوانەی نیشانە زیندووەکان (پەستان، شەکرە، پلەی گەرمی)',
                'label_kmr' => 'پیڤانا فشارێ، شەکرێ و پلەیا گەرمێ',
                'label_ar' => 'قياس العلامات الحيوية والسكري',
                'label_en' => 'Vital Signs & Glucometer Monitoring',
                'sort_order' => 6,
            ],
            [
                'type' => 'skill',
                'option_key' => 'cold_chain',
                'label_ckb' => 'مامەڵە لەگەڵ تیوبەکان و گواستنەوەی ساردی نموونە (CBC / ESR)',
                'label_kmr' => 'سەرەدەری دگەل تیوبان و پاراستنا سارد یا نموونان',
                'label_ar' => 'التعامل مع الأنابيب وسلسلة التبريد للعينات',
                'label_en' => 'Specimen Tube Handling & Cold Chain',
                'sort_order' => 7,
            ],
            [
                'type' => 'skill',
                'option_key' => 'pharma_handling',
                'label_ckb' => 'پاراستن و گەیاندنی دەرمانی هەستیار بە پلەی گەرمی',
                'label_kmr' => 'پاراستن و گەهاندنا دەرمانێن هەستیار ب پلەیا گەرمێ',
                'label_ar' => 'حفظ ونقل الأدوية الحساسة للحرارة',
                'label_en' => 'Temperature-Sensitive Pharmacy Handling',
                'sort_order' => 8,
            ],
        ];

        foreach ($defaults as &$row) {
            $row['is_active'] = true;
            $row['created_at'] = $now;
            $row['updated_at'] = $now;
        }

        DB::table('recruitment_options')->insert($defaults);
    }

    public function down(): void
    {
        Schema::dropIfExists('recruitment_options');
    }
};

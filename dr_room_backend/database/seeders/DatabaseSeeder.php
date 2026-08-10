<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Admin User',
            'email' => 'admin@drroom.com',
            'role' => 'admin',
        ]);

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
                'title' => 'چۆنیەتی مامەڵەکردن لەگەڵ سووتانی پلە یەک و دوو',
                'title_en' => 'How to Treat First and Second-Degree Burns',
                'title_ar' => 'كيفية التعامل مع الحروق من الدرجة الأولى والثانية',
                'content' => "لە کاتی تێکچوونی پێست بەهۆی سووتانەوە:\n- بە هیچ جۆرێک سەهۆڵ یان ڕۆن مەخەرە سەر برینەکە.\n- بۆ ماوەی ١٠ تا ١٥ خولەک ئاوی سارد (نەک سەهۆڵ) بەسەر شوێنی سووتاویەکەدا برژێنە.\n- بڕێکی گونجاو مەرهەمی تایبەت بە سووتان بەکاربێنە و بە گازێکی خاوێن شوێنەکە داپۆشە.",
                'content_en' => "For burn injuries: Cool the burn with cool running water for 10-15 minutes. Do not apply ice or butter. Cover with a clean sterile bandage.",
                'content_ar' => "لإصابات الحروق: برّد الحرق بالماء الجاري البارد لمدة 10-15 دقيقة. لا تضع الثلج أو الزبدة. غطِّ الحرق بضمادة نظيفة ومعقمة.",
                'is_published' => true,
            ],
            [
                'title' => 'ڕێنمایی کۆنتڕۆڵکردنی خوێنربوونی توند لە کاتی برینداربوون',
                'title_en' => 'Severe Bleeding Control & Wound First Aid',
                'title_ar' => 'دليل التحكم في النزيف الحاد والإسعافات الأولية',
                'content' => "خوێنربوونی توند پێویستی بە هەنگاوی بەپەلە هەیە بۆ ڕێگریکردن لە شوکی خوێنربوون:\n- پارچە پەڕۆیەکی خاوێن یان گازی پزیشکی بپەستێنە سەر شوێنی برینەکە.\n- پەستانەکە بە بەردەوامی ڕابگرە.\n- لە شوێنی پێویستدا شوێنی برینداربوونەکە لە ئاستی دڵ بەرزتر ڕابگرە.",
                'content_en' => "Apply direct pressure with a clean cloth or bandage. Keep steady pressure on the wound. Elevate the wounded limb if possible.",
                'content_ar' => "اضغط بشكل مباشر باستخدام قماش نظيف أو ضمادة. حافظ على الضغط المستمر. ارفع الطرف المصاب إذا أمكن.",
                'is_published' => true,
            ],
        ];

        foreach ($articles as $articleData) {
            \App\Models\Article::create($articleData);
        }
    }
}

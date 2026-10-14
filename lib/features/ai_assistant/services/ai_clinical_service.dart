import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiClinicalVisionService {
  AiClinicalVisionService._();
  static final AiClinicalVisionService instance = AiClinicalVisionService._();

  // Gemini API Key (configurable via --dart-define=GEMINI_API_KEY)
  static final String _geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  ).isNotEmpty
      ? const String.fromEnvironment('GEMINI_API_KEY')
      : utf8.decode(base64.decode(
          'QVEuQWI4Uk42Sk1UUnR4emRYeDRpbkVNQ1hvdXZkRmIzSzN1RXAxZUp4TWRBcjV1Z3czSXc=',
        ));

  // Vision models to try in order of priority & reliability
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-3.7-flash',
  ];

  /// Analyzes a medical image (Medicine, Pill, Prescription) using Gemini Vision.
  Future<Map<String, dynamic>> analyzeMedicalImage({
    required File imageFile,
    required String mode,
    String language = 'ckb',
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine mime type from file extension
      final path = imageFile.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final prompt = _buildPrompt(mode, language: language);

      for (final model in _models) {
        try {
          final result = await _callGemini(
            model: model,
            prompt: prompt,
            base64Image: base64Image,
            mimeType: mimeType,
          );

          if (result != null) {
            result['mode'] = mode;
            _normalizeResult(result, mode, language: language);
            return result;
          }
        } catch (e) {
          debugPrint('Error with model $model: $e');
          // continue to next model fallback
        }
      }

      // If all live models failed, return a user-friendly error response in the expected format
      return _buildFallbackErrorResult(
        mode,
        null,
        language: language,
      );
    } catch (e) {
      debugPrint('AiClinicalVisionService exception: $e');
      return _buildFallbackErrorResult(
        mode,
        e.toString(),
        language: language,
      );
    }
  }

  Future<Map<String, dynamic>?> _callGemini({
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.15,
      }
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text =
            candidates[0]['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return _cleanAndParseJson(text);
        }
      }
    } else {
      debugPrint('Gemini API $model returned HTTP ${response.statusCode}: ${response.body}');
    }

    return null;
  }

  String _buildPrompt(String mode, {String language = 'ckb'}) {
    if (language == 'ar') {
      return '''
You are the Dr-Room AI Medicine & Pharmaceutical Specialist (أخصائي الذكاء الاصطناعي للأدوية والصيدلة في دكتور روم).
Carefully inspect and analyze the attached photo of a medicine, pill, tablet, blister strip, syrup, capsule, injection, medicine packaging, or medical prescription.

Identify and explain the medicine in Arabic (اللغة العربية الفصحى المبسطة):
1. Identify the exact medicine name (Commercial / Brand name and Generic / Scientific name in Arabic and English, e.g. Panadol Extra / Paracetamol).
2. Category / Therapeutic class (e.g. مسكن ألم، مضاد حيوي، مضاد حموضة، مضاد حساسية).
3. Primary uses (دواعي الاستعمال وما يعالجه الدواء).
4. Dosage, timing & instructions (طريقة الاستخدام والجرعة: متى وكم يؤخذ، قبل الأكل أو بعده).
5. Active ingredients & strength (المادة الفعالة والتركيز، مثلاً Paracetamol 500mg).
6. Warnings, precautions & contraindications (التحذيرات وموانع الاستعمال الهامة).

Return ONLY valid JSON matching this exact structure:
{
  "title": "الاسم التجاري والعلمي للدواء (مثال: Amoxicillin • أموكسيسيلين 500mg)",
  "category": "تصنيف الدواء (مثال: مضاد حيوي • Antibiotic)",
  "confidence": "99.0%",
  "summary": "ملخص واضح ومبسط باللغة العربية يشرح ما هو هذا الدواء وفائدته وتأثيره",
  "markers": [
    {
      "name": "المادة الفعالة",
      "value": "اسم المادة مع الجرعة (مثال: Paracetamol 500mg)",
      "status": "فعال",
      "isNormal": true
    },
    {
      "name": "الشكل الصيدلاني",
      "value": "كبسولات / أقراص / شراب / شريط",
      "status": "عادي",
      "isNormal": true
    },
    {
      "name": "الجرعة والتوقيت",
      "value": "مثال: 3 مرات يومياً (كل 8 ساعات)",
      "status": "إرشادات",
      "isNormal": true
    },
    {
      "name": "طريقة الاستعمال",
      "value": "بعد الأكل مع كوب ماء",
      "status": "هام",
      "isNormal": true
    }
  ],
  "recommendations": "إرشادات الاستخدام وكيفية حفظ الدواء في المنزل بالعربية",
  "warnings": "تحذيرات هامة حول الحساسية، الجرعات الزائدة، أو الحمل بالعربية"
}

Critical Rules:
- If the image does NOT contain a medicine, pill, blister pack, syrup, medical box, or prescription (for example: flowers, food, cars, animals, random objects):
  Set "title" to "الصورة ليست دواءً",
  "category": "تحليل غير معروف",
  "confidence": "0%",
  "summary": "هذه الصورة لا تحتوي على علبة دواء أو حبوب أو وصفة طبية. يرجى التقاط صورة واضحة لعلبة دواء أو حبوب أو روشتة فقط.",
  "markers": [
    {"name": "حالة الصورة", "value": "ليست دواء", "status": "مراجعة", "isNormal": false}
  ],
  "recommendations": "يرجى توجيه الكاميرا نحو علبة أو شريط الدواء والتقاط صورة واضحة.",
  "warnings": "هذا الماسح مخصص فقط للتعرف على الأدوية وتحليلها."
- Always write in fluent, warm, accurate Arabic.
- Always ensure "isNormal" is boolean true/false.
''';
    } else if (language == 'en') {
      return '''
You are the Dr-Room AI Medicine & Pharmaceutical Specialist.
Carefully inspect and analyze the attached photo of a medicine, pill, tablet, blister strip, syrup, capsule, injection, medicine packaging, or medical prescription.

Identify and explain the medicine in clear, accessible English:
1. Identify the exact medicine name (Commercial / Brand name and Generic / Scientific name, e.g. Panadol Extra / Paracetamol).
2. Category / Therapeutic class (e.g. Analgesic, Antibiotic, Antacid, Antihistamine).
3. Primary uses (Indications and what it treats).
4. Dosage, timing & instructions (How and when to take, before or after food).
5. Active ingredients & strength (Active ingredient and dose, e.g. Paracetamol 500mg).
6. Warnings, precautions & contraindications (Key warnings, who should avoid it, drug interactions).

Return ONLY valid JSON matching this exact structure:
{
  "title": "Commercial & Scientific name (e.g. Amoxicillin 500mg)",
  "category": "Medication Class (e.g. Antibiotic • Anti-infective)",
  "confidence": "99.0%",
  "summary": "A clear, accessible summary explaining what this medicine is, what it does, and how it works",
  "markers": [
    {
      "name": "Active Ingredient",
      "value": "Ingredient name with strength (e.g. Paracetamol 500mg)",
      "status": "Active",
      "isNormal": true
    },
    {
      "name": "Dosage Form",
      "value": "Capsule / Tablet / Syrup / Blister pack",
      "status": "Normal",
      "isNormal": true
    },
    {
      "name": "Dosage Schedule",
      "value": "e.g. 3 times daily (every 8 hours)",
      "status": "Guidance",
      "isNormal": true
    },
    {
      "name": "Administration",
      "value": "After meals with water",
      "status": "Important",
      "isNormal": true
    }
  ],
  "recommendations": "Usage advice and home storage instructions in English",
  "warnings": "Important warnings regarding allergies, overdose, or pregnancy in English"
}

Critical Rules:
- If the image does NOT contain a medicine, pill, blister pack, syrup, medical box, or prescription (for example: flowers, food, cars, animals, random objects):
  Set "title" to "Image is not medication",
  "category": "Unknown",
  "confidence": "0%",
  "summary": "This image does not appear to contain a medicine box, pill, or prescription. Please take a clear photo of your medicine or prescription.",
  "markers": [
    {"name": "Status", "value": "Not medicine", "status": "Review", "isNormal": false}
  ],
  "recommendations": "Please point the camera directly at the medicine packaging or blister pack and ensure good lighting.",
  "warnings": "This scanner is specifically designed for analyzing medications and prescriptions."
- Always write in fluent, professional English.
- Always ensure "isNormal" is boolean true/false.
''';
    } else if (language == 'kmr') {
      return '''
You are the Dr-Room AI Medicine & Pharmaceutical Specialist (تایبەتمەندێ ژیرییا دەستکرد بۆ دەرمان و حەبان ل دکتۆر ڕۆم).
Carefully inspect and analyze the attached photo of a medicine, pill, tablet, blister strip, syrup, capsule, injection, medicine packaging, or medical prescription.

Identify and explain the medicine in authentic Badini Kurdish (کوردییا بادینی ب ئەلفوبێیا کوردی-عەرەبی):
1. Identify the exact medicine name (Commercial / Brand name and Generic / Scientific name in Badini and English, e.g. Panadol Extra / Paracetamol).
2. Category / Therapeutic class (e.g. ئێش شکێن، ئەنتی بایۆتیک، دژی ترشاتیێ، دژی حەساسییەتێ).
3. Primary uses (بۆ چ دهێتە بکارئینان و چارەسەریا چ دکەت).
4. Dosage, timing & instructions (چەوانیا بکارئینانێ و ژەم: کەنگی و چەند دهێتە خوارن، بەری نانی یان پشتی نانی).
5. Active ingredients & strength (پێکهاتەیا چالاک و هێزا وێ بۆ نموونە 500mg).
6. Warnings, precautions & contraindications (هۆشدارییێن گرنگ، بۆ کێ نابیت، دگەل چ ناهێتە خوارن).

Return ONLY valid JSON matching this exact structure:
{
  "title": "ناڤێ بازرگانی و زانستی یێ دەرمانی (بۆ نموونە: Amoxicillin • ئامۆکسیسیلین 500mg)",
  "category": "گرووپێ دەرمانی (بۆ نموونە: دژی هەوکرنێ • Antibiotic)",
  "confidence": "99.0%",
  "summary": "پوختەیەکا زۆرا ڕوون و ب ساناهی ب زمانێ کوردییێ بادینی کا ئەڤ دەرمانە چییە و بۆ چ باشە و کارتێکرنا وی چییە",
  "markers": [
    {
      "name": "پێکهاتەیا چالاک",
      "value": "ناڤێ پێکهاتەیێ دگەل دۆزێ (بۆ نموونە: Paracetamol 500mg)",
      "status": "چالاک",
      "isNormal": true
    },
    {
      "name": "شێوازێ دەرمانی",
      "value": "کەپسول / حەب / شلەمەنی / شریت",
      "status": "نۆرمال",
      "isNormal": true
    },
    {
      "name": "شێوازێ خوارنێ",
      "value": "بۆ نموونە: ڕۆژێ ٣ جاران (هەر ٨ دەمژمێران)",
      "status": "شیرەت",
      "isNormal": true
    },
    {
      "name": "دەمێ بکارئینانێ",
      "value": "پشتی خوارنێ دگەل ئاڤەکا زۆر",
      "status": "گرنگ",
      "isNormal": true
    }
  ],
  "recommendations": "شیرەتێن بکارئینانێ و چەوانیا پاراستنا دەرمانی ل ماڵ ب بادینی",
  "warnings": "هۆشدارییێن گرنگ دەربارەی حەساسییەتێ، ژەما زێدە، یان ژنێن دووگیان ب بادینی"
}

Critical Rules:
- If the image does NOT contain a medicine, pill, blister pack, syrup, medical box, or prescription:
  Set "title" to "وێنە نە دەرمانە",
  "category": "شرۆڤەکرنا نەدیار",
  "confidence": "0%",
  "summary": "ئەڤ وێنەیە پاکێت یان حەبا دەرمانی نینە. هیڤیدارین بتنێ وێنەیێ پاکێتێ دەرمانی، حەب یان نڤیسا نوژداری بگری دا کو پێزانینێن دروست بدەینە تە.",
  "markers": [
    {"name": "ڕەوشا وێنەیی", "value": "نە دەرمانە", "status": "پێداچوون", "isNormal": false}
  ],
  "recommendations": "تکایە کامێرا خۆ ڕاگرە بەرامبەر پاکێت یان شریتێ دەرمانی و وێنەیەکێ ڕوون بگرە.",
  "warnings": "ئەڤ سکێنەرە تایبەتە ب نیاسین و شرۆڤەکرنا دەرمان و حەبان."
- Always write in fluent, natural Badini Kurdish (کوردییا بادینی).
- Always ensure "isNormal" is boolean true/false.
''';
    }

    // Kurdish (Central Kurdish / Sorani)
    return '''
You are the Dr-Room AI Medicine & Pharmaceutical Specialist (پسپۆڕی زیرەکی دەستکرد بۆ دەرمان و حەب لە دکتۆر رووم).
Carefully inspect and analyze the attached photo of a medicine, pill, tablet, blister strip, syrup, capsule, injection, medicine packaging, or medical prescription.

Identify and explain the medicine in Central Kurdish (کوردی سۆرانی):
1. Identify the exact medicine name (Commercial / Brand name and Generic / Scientific name in Kurdish and English, e.g. Panadol Extra / Paracetamol).
2. Category / Therapeutic class (e.g. ئازارشکێن، ئەنتی بایۆتیک، دژە ترشەڵۆک، دژە هەستیاری).
3. Primary uses (بۆچی بەکاردێت و چارەسەری چی دەکات).
4. Dosage, timing & instructions (چۆنیەتی بەکارهێنان و ژەم: کەی و چەند دەخورێت، پێش نان یان دوای نان).
5. Active ingredients & strength (پێکهاتەی چالاک و هێزەکەی بۆ نموونە 500mg).
6. Warnings, precautions & contraindications (هۆشدارییە گرنگەکان، بۆ کێ نابێت، لەگەڵ چی ناخورێت).

Return ONLY valid JSON matching this exact structure:
{
  "title": "ناوی بازرگانی و زانستی دەرمانەکە (بۆ نموونە: Amoxicillin • ئامۆکسیسیلین 500mg)",
  "category": "گرووپی دەرمانەکە (بۆ نموونە: دژەهەوکردن • Antibiotic)",
  "confidence": "99.0%",
  "summary": "پوختەیەکی زۆر ڕوون و تێگەیشتوو بە زمانی کوردی سادە کە ئەم دەرمانە چییە و بۆچی باشە و کاریگەرییەکەی چییە",
  "markers": [
    {
      "name": "پێکهاتەی چالاک",
      "value": "ناوی پێکهاتەکە لەگەڵ دۆز (بۆ نموونە: Paracetamol 500mg)",
      "status": "چالاک",
      "isNormal": true
    },
    {
      "name": "شێوازی دەرمان",
      "value": "کەپسول / حەب / شلەمەنی / شریت",
      "status": "ئاسایی",
      "isNormal": true
    },
    {
      "name": "شێوازی خواردن",
      "value": "بۆ نموونە: ڕۆژی ٣ جار (هەر ٨ کاتژمێر جارێک)",
      "status": "ڕێنمایی",
      "isNormal": true
    },
    {
      "name": "کاتی بەکارهێنان",
      "value": "دوای نان لەگەڵ ئاوی زۆر",
      "status": "گرنگ",
      "isNormal": true
    }
  ],
  "recommendations": "ڕێنمایی بەکارهێنان و چۆنیەتی پاراستنی دەرمانەکە لە ماڵەوە بە کوردی",
  "warnings": "هۆشداری گرنگ دەربارەی حەساسییەت، ژەمی زیادە، یان ئافرەتی دووگیان بە کوردی"
}

Critical Rules:
- If the image does NOT contain a medicine, pill, blister pack, syrup, medical box, or prescription (for example: flowers, food, cars, animals, random objects):
  Set "title" to "وێنەکە دەرمان نییە",
  "category": "شیکاریی نەناسراو",
  "confidence": "0%",
  "summary": "ئەم وێنەیە پاکەت یان حەبی دەرمان نییە. تکایە تەنها وێنەی پاکەتی دەرمان، حەب یان ڕەچەتەی پزیشکی بگرە بۆ ئەوەی زانیاری وردت پێبدەین.",
  "markers": [
    {"name": "دۆخی وێنە", "value": "دەرمان نییە", "status": "پێداچوونەوە", "isNormal": false}
  ],
  "recommendations": "تکایە کامێراکەت ڕابگرە بەرامبەر پاکەت یان شریتی دەرمانەکە و وێنەیەکی ڕوون بگرە.",
  "warnings": "ئەم سکانەرە تایبەتە بە ناسینەوە و شیکردنەوەی دەرمان و حەب."
- Always write in fluent, warm, correct Central Kurdish (سۆرانی).
- Always ensure "isNormal" is boolean true/false.
''';
  }

  void _normalizeResult(Map<String, dynamic> result, String mode, {String language = 'ckb'}) {
    final isAr = language == 'ar';
    final isEn = language == 'en';
    final isKmr = language == 'kmr';

    result['title'] = (result['title'] ?? (isAr ? 'تحليل الدواء' : (isEn ? 'Medicine Analysis' : (isKmr ? 'شرۆڤەکرنا دەرمانی' : 'شیکاریی دەرمان')))).toString();
    result['category'] = (result['category'] ?? (isAr ? 'الأدوية والحبوب' : (isEn ? 'Medication & Pills' : (isKmr ? 'دەرمان و حەب' : 'دەرمان و حەب')))).toString();
    result['confidence'] = (result['confidence'] ?? '99.0%').toString();
    result['summary'] = (result['summary'] ?? (isAr ? 'تم تحليل الدواء بواسطة الذكاء الاصطناعي.' : (isEn ? 'Medication analyzed by AI.' : (isKmr ? 'دەرمان ژ لایێ ژیرییا دەستکرد ڤە هاتە شرۆڤەکرن.' : 'شیکاریی دەرمانەکە لەلایەن ژیری دەستکردەوە ئەنجامدرا.')))).toString();
    result['recommendations'] = (result['recommendations'] ?? (isAr ? 'يرجى الالتزام بتعليمات الطبيب أو الصيدلي.' : (isEn ? 'Please follow the advice of your doctor or pharmacist.' : (isKmr ? 'هیڤیە ل دیف شیرەتێن نوژداری یان دەرمانسازی بکاربینی.' : 'تکایە بەپێی ڕێنمایی پزیشک یان دەرمانساز بەکاریبهێنە.')))).toString();
    result['warnings'] = (result['warnings'] ?? (isAr ? 'احفظ الأدوية بعيداً عن متناول الأطفال وفق الإرشادات الطبية.' : (isEn ? 'Keep medications away from children according to medical advice.' : (isKmr ? 'هەر دەرمانەکی پێدڤیە ل دیف شیرەتێن نوژداری و دوور ژ دەستێ زارۆکان بهێتە پاراستن.' : 'هەر دەرمانێک پێویستە بەپێی ڕێنمایی پزیشک و دوور لە دەستی منداڵان دابنرێت.')))).toString();

    final rawMarkers = result['markers'];
    final List<Map<String, dynamic>> normalizedMarkers = [];
    if (rawMarkers is List) {
      for (final item in rawMarkers) {
        if (item is Map) {
          normalizedMarkers.add({
            'name': (item['name'] ?? item['test'] ?? item['marker'] ?? (isAr ? 'فحص' : (isEn ? 'Marker' : 'پشکنین'))).toString(),
            'value': (item['value'] ?? item['result'] ?? '').toString(),
            'status': (item['status'] ?? (isAr ? 'عادي' : (isEn ? 'Normal' : (isKmr ? 'نۆرمال' : 'ئاسایی')))).toString(),
            'isNormal': item['isNormal'] == true ||
                item['is_normal'] == true ||
                (item['status']?.toString().contains('ئاسایی') ?? true) ||
                (item['status']?.toString().contains('عادي') ?? true) ||
                (item['status']?.toString().contains('نۆرمال') ?? true) ||
                (item['status']?.toString().toLowerCase().contains('normal') ?? true),
          });
        } else if (item != null) {
          normalizedMarkers.add({
            'name': item.toString(),
            'value': isAr ? 'مكتمل' : (isEn ? 'Completed' : (isKmr ? 'هاتەکرن' : 'ئەنجامدراوە')),
            'status': isAr ? 'عادي' : (isEn ? 'Normal' : (isKmr ? 'نۆرمال' : 'ئاسایی')),
            'isNormal': true,
          });
        }
      }
    }
    if (normalizedMarkers.isEmpty) {
      normalizedMarkers.add({
        'name': isAr ? 'المكون الأساسي' : (isEn ? 'Main Component' : (isKmr ? 'پێکهاتەیا سەرەکی' : 'پێکهاتەی سەرەکی')),
        'value': isAr ? 'تم التحليل' : (isEn ? 'Analyzed' : (isKmr ? 'هاتە شرۆڤەکرن' : 'شیکاریکرا')),
        'status': isAr ? 'عادي' : (isEn ? 'Normal' : (isKmr ? 'نۆرمال' : 'ئاسایی')),
        'isNormal': true,
      });
    }
    result['markers'] = normalizedMarkers;
  }

  Map<String, dynamic>? _cleanAndParseJson(String raw) {
    try {
      String clean = raw.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      } else if (clean.startsWith('```')) {
        clean = clean.substring(3);
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      clean = clean.trim();

      final dynamic parsed = jsonDecode(clean);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (e) {
      debugPrint('Failed to parse Gemini JSON: $e\nRaw: $raw');
    }
    return null;
  }

  Map<String, dynamic> _buildFallbackErrorResult(
    String mode,
    String? customError, {
    String language = 'ckb',
  }) {
    final isAr = language == 'ar';
    final isEn = language == 'en';
    final isKmr = language == 'kmr';

    String defaultErr;
    if (isAr) {
      defaultErr = 'تعذر الاتصال بخدمة الذكاء الاصطناعي. يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى.';
    } else if (isEn) {
      defaultErr = 'Could not connect to AI service. Please check your internet connection and try again.';
    } else if (isKmr) {
      defaultErr = 'نەهاتە گرێدان ب خزمەتگوزاریا ژیرییا دەستکرد ڤە. هیڤیە ژ هەبوونا هێلا ئینتەرنێتێ دڵنیا ببە و دووبارە بزاڤێ بکە.';
    } else {
      defaultErr = 'نەتوانرا پەیوەندی بە خزمەتگوزاری زیرەکی دەستکردەوە بکرێت. تکایە دڵنیابەرەوە لە هێڵی ئینتەرنێت و دووبارە هەوڵبدەرەوە.';
    }

    return {
      'mode': mode,
      'title': isAr ? 'تعذر إتمام التحليل' : (isEn ? 'Analysis Incomplete' : (isKmr ? 'شرۆڤەکرن تمام نەبوو' : 'سەرکەوتوو نەبوو لە شیکاری')),
      'category': isAr ? 'خطأ في الاتصال' : (isEn ? 'Connection Error' : (isKmr ? 'شاشییا گرێدانێ' : 'هەڵەی پەیوەندی')),
      'confidence': '0%',
      'summary': customError ?? defaultErr,
      'markers': [
        {
          'name': isAr ? 'حالة الخدمة' : (isEn ? 'Service Status' : (isKmr ? 'ڕەوشا سیستەمی' : 'دۆخی سیستەم')),
          'value': isAr ? 'غير متاح حالياً' : (isEn ? 'Currently Unavailable' : (isKmr ? 'د دەستبەردەست دا نینە' : 'لەکارکەوتووە')),
          'status': isAr ? 'خطأ' : (isEn ? 'Error' : (isKmr ? 'خەلەت' : 'هەڵە')),
          'isNormal': false,
        }
      ],
      'recommendations': isAr
          ? 'يرجى التأكد من وضوح الصورة وتوفر إضاءة مناسبة، ثم المحاولة مرة أخرى.'
          : (isEn
              ? 'Please ensure good lighting and clear focus on the medicine, then try again.'
              : (isKmr
                  ? 'هیڤیە ژ هەبوونا ڕووناهییا گونجای و تەرکیزێ ل سەر وێنەیی دڵنیا ببە، پاشان دووبارە وێنەیی بگرە.'
                  : 'تکایە دڵنیابەرەوە لە هەبوونی ڕووناکی گونجاو و تەرکیز لەسەر دەقەکە، پاشان دووبارە وێنەکە بگرەوە.')),
      'warnings': isAr
          ? 'إذا استمرت المشكلة، يرجى التحقق من اتصالك بالإنترنت.'
          : (isEn
              ? 'If the issue persists, please check your internet connection.'
              : (isKmr
                  ? 'ئەگەر ئاریشە یا بەردەوام بوو، ژ بەستراویا ئینتەرنێتا خۆ پشتڕاست ببە.'
                  : 'ئەگەر کێشەکە بەردەوام بوو، دڵنیابەرەوە لە بەستراوەیی ئینتەرنێتەکەت.')),
    };
  }
}

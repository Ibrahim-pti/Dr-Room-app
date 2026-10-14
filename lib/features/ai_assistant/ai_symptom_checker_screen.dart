import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import 'services/ai_clinical_service.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  final String? initialMode; // 'lab' or 'nursing'

  const AiSymptomCheckerScreen({super.key, this.initialMode});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  late String _currentMode; // 'lab' or 'nursing'
  bool _isAnalyzing = false;
  int _analysisStep = 0;
  File? _scannedImage;
  Map<String, dynamic>? _scanResult;
  final List<Map<String, dynamic>> _userScans = [];

  List<Map<String, dynamic>> _getLocalizedDefaultScans(String lang) {
    if (lang == 'ar') {
      return [
        {
          'mode': 'medicine',
          'title': 'Amoxicillin (أموكسيسيلين 500mg)',
          'category': 'مضاد حيوي • مكافحة العدوى',
          'date': 'اليوم 10:30 صباحاً',
          'confidence': '99.4%',
          'summary': 'مضاد حيوي واسع المجال يُستخدم لعلاج الالتهابات البكتيرية مثل التهاب الحلق، الصدر، والمسالك البولية.',
          'markers': [
            {'name': 'المادة الفعالة', 'value': 'Amoxicillin 500mg', 'status': 'فعال', 'isNormal': true},
            {'name': 'الشكل الصيدلاني', 'value': 'كبسولات (Capsule)', 'status': 'عادي', 'isNormal': true},
            {'name': 'الجرعة والتوقيت', 'value': '3 مرات يومياً (كل 8 ساعات)', 'status': 'إرشادات', 'isNormal': true},
            {'name': 'طريقة الاستعمال', 'value': 'بعد الأكل مع كوب ماء', 'status': 'هام', 'isNormal': true},
          ],
          'recommendations': 'أكمل الجرعة العلاجية كاملة حتى لو شعرت بتحسن لمنع مقاومة البكتيريا.',
          'warnings': 'لا تتناول هذا الدواء إذا كان لديك حساسية سابقة للبنسلين.',
        },
        {
          'mode': 'medicine',
          'title': 'Panadol Extra (بنادول إكسترا)',
          'category': 'مسكن للألم وخافض للحرارة',
          'date': 'أمس 04:15 مساءً',
          'confidence': '99.1%',
          'summary': 'يُستخدم لتسكين الصداع، آلام الأسنان، آلام العضلات، الشقيقة، وتخفيض درجات الحرارة.',
          'markers': [
            {'name': 'المادة الفعالة', 'value': 'Paracetamol + Caffeine', 'status': 'فعال', 'isNormal': true},
            {'name': 'الشكل الصيدلاني', 'value': 'أقراص (Tablet)', 'status': 'عادي', 'isNormal': true},
            {'name': 'الجرعة والتوقيت', 'value': '1-2 قرص عند الحاجة (كل 6 ساعات)', 'status': 'إرشادات', 'isNormal': true},
          ],
          'recommendations': 'لا تتجاوز 8 أقراص يومياً لحماية وظائف الكبد.',
          'warnings': 'تجنب تناوله مع أدوية أخرى تحتوي على الباراسيتامول، ويفضل عدم تناوله قبل النوم لاحتوائه على الكافيين.',
        },
      ];
    } else if (lang == 'en') {
      return [
        {
          'mode': 'medicine',
          'title': 'Amoxicillin 500mg',
          'category': 'Antibiotic • Anti-infective',
          'date': 'Today 10:30 AM',
          'confidence': '99.4%',
          'summary': 'Broad-spectrum antibiotic used to treat bacterial infections of the throat, chest, urinary tract, and skin.',
          'markers': [
            {'name': 'Active Ingredient', 'value': 'Amoxicillin 500mg', 'status': 'Active', 'isNormal': true},
            {'name': 'Form', 'value': 'Capsule', 'status': 'Normal', 'isNormal': true},
            {'name': 'Dosage & Schedule', 'value': '3 times daily (every 8 hours)', 'status': 'Guidance', 'isNormal': true},
            {'name': 'Administration', 'value': 'After meals with water', 'status': 'Important', 'isNormal': true},
          ],
          'recommendations': 'Complete the full course even if you feel better to prevent antibiotic resistance.',
          'warnings': 'Do not take if you have a known allergy to penicillin.',
        },
        {
          'mode': 'medicine',
          'title': 'Panadol Extra',
          'category': 'Analgesic & Antipyretic',
          'date': 'Yesterday 04:15 PM',
          'confidence': '99.1%',
          'summary': 'Used for effective relief of headache, migraine, toothache, muscle aches, and reducing fever.',
          'markers': [
            {'name': 'Active Ingredient', 'value': 'Paracetamol + Caffeine', 'status': 'Active', 'isNormal': true},
            {'name': 'Form', 'value': 'Tablet', 'status': 'Normal', 'isNormal': true},
            {'name': 'Dosage & Schedule', 'value': '1-2 tablets as needed (every 6 hours)', 'status': 'Guidance', 'isNormal': true},
          ],
          'recommendations': 'Do not exceed 8 tablets per day to avoid liver damage.',
          'warnings': 'Do not take with other paracetamol-containing products. Avoid before bedtime due to caffeine.',
        },
      ];
    }

    if (lang == 'kmr') {
      return [
        {
          'mode': 'medicine',
          'title': 'Amoxicillin (ئامۆکسیسیلین 500mg)',
          'category': 'دژی هەوکرنێ • ئەنتی بایۆتیک',
          'date': 'ئەڤرۆ ١٠:٣٠ سپێدێ',
          'confidence': '99.4%',
          'summary': 'ئەڤ دەرمانە ئەنتی بایۆتیکە و دهێتە بکارئینان بۆ چارەسەرکرنا هەوکرنا بەکتریایی وەک قورگ، سنگ، ڕێکا میزێ و برینان.',
          'markers': [
            {'name': 'پێکهاتەیا چالاک', 'value': 'Amoxicillin 500mg', 'status': 'چالاک', 'isNormal': true},
            {'name': 'شێوازێ دەرمانی', 'value': 'کەپسول (Capsule)', 'status': 'نۆرمال', 'isNormal': true},
            {'name': 'ژەم و دەم', 'value': 'ڕۆژێ ٣ جاران (هەر ٨ دەمژمێران)', 'status': 'شیرەت', 'isNormal': true},
            {'name': 'شێوازێ خوارنێ', 'value': 'پشتی خوارنێ دگەل ئاڤێ', 'status': 'گرنگ', 'isNormal': true},
          ],
          'recommendations': 'کۆرسێ دەرمانی هەتا دووماهییێ تمام بکە خۆ ئەگەر هەست ب باشبوونێ ژی بکەی دا بەکتریا سەرنەهەڵدەتەڤە.',
          'warnings': 'ئەگەر حەساسییەت ب پەنسلینێ هەبیت نابیت چ جاران ئەڤی دەرمانی بکاربینی.',
        },
        {
          'mode': 'medicine',
          'title': 'Panadol Extra (پانادۆڵ ئێکسسترا)',
          'category': 'ئێش شکێن و دابەزینەرا تایێ',
          'date': 'دوهی ٠٤:١٥ ئێڤاری',
          'confidence': '99.1%',
          'summary': 'دهێتە بکارئینان بۆ هێورکرنا ئێشانا سەرێ، شەقیقێ، ددانان، پشتا و ماسوولکان و دابەزاندنا تایێ.',
          'markers': [
            {'name': 'پێکهاتەیا چالاک', 'value': 'Paracetamol + Caffeine', 'status': 'چالاک', 'isNormal': true},
            {'name': 'شێوازێ دەرمانی', 'value': 'حەب (Tablet)', 'status': 'نۆرمال', 'isNormal': true},
            {'name': 'ژەم و دەم', 'value': '١-٢ حەب دەمێ پێدڤی (هەر ٦ دەمژمێران)', 'status': 'شیرەت', 'isNormal': true},
          ],
          'recommendations': 'ڕۆژانە پتر ژ ٨ حەبان مەخۆ دا کو زیان نەگەهیتە جگەرێ.',
          'warnings': 'دگەل دەرمانێن دی یێن پاراسیتامۆڵێ تێکەل نەکە، و بەری نڤستنێ ژبەر کافایینێ نەخۆی چێترە.',
        },
      ];
    }

    // Kurdish Sorani (ckb)
    return [
      {
        'mode': 'medicine',
        'title': 'Amoxicillin (ئامۆکسیسیلین 500mg)',
        'category': 'دژەهەوکردن • ئەنتی بایۆتیک',
        'date': 'ئەمڕۆ ١٠:٣٠ بەیانی',
        'confidence': '99.4%',
        'summary': 'ئەم دەرمانە ئەنتی بایۆتیکێکی کاریگەرە بۆ چارەسەری هەوکردنی بەکتریایی وەک هەوکردنی قوڕگ، سنگ، میزەڕۆ و برین.',
        'markers': [
          {'name': 'پێکهاتەی چالاک', 'value': 'Amoxicillin 500mg', 'status': 'چالاک', 'isNormal': true},
          {'name': 'شێوەی دەرمان', 'value': 'کەپسول (Capsule)', 'status': 'ئاسایی', 'isNormal': true},
          {'name': 'ژەم و کات', 'value': 'ڕۆژی ٣ جار (هەر ٨ کاتژمێر)', 'status': 'ڕێنمایی', 'isNormal': true},
          {'name': 'شێوازی خواردن', 'value': 'دوای نان لەگەڵ ئاو', 'status': 'گرنگ', 'isNormal': true},
        ],
        'recommendations': 'کۆرسەکە تا کۆتایی تەواو بکە تەنانەت ئەگەر هەستت بە باشبوونیش کرد.',
        'warnings': 'ئەگەر هەستیاریت (حەساسییەت) بە پەنسلین هەیە هەرگیز نابێت ئەم دەرمانە بخۆیت.',
      },
      {
        'mode': 'medicine',
        'title': 'Panadol Extra (پانادۆڵ ئێکسسترا)',
        'category': 'ئازارشکێن و دابەزێنەری تا',
        'date': 'دوێنێ ٠٤:١٥ ئێوارە',
        'confidence': '99.1%',
        'summary': 'بەکاردێت بۆ هێورکردنەوەی ئازاری سەرئێشە، شەقیقە، ددان، پشت و ماسولکە و دابەزاندنی تا.',
        'markers': [
          {'name': 'پێکهاتەی چالاک', 'value': 'Paracetamol + Caffeine', 'status': 'چالاک', 'isNormal': true},
          {'name': 'شێوەی دەرمان', 'value': 'حەب (Tablet)', 'status': 'ئاسایی', 'isNormal': true},
          {'name': 'ژەم و کات', 'value': '١-٢ حەب لە کاتی پێویست (هەر ٦ کاتژمێر)', 'status': 'ڕێنمایی', 'isNormal': true},
        ],
        'recommendations': 'ڕۆژانە زیاتر لە ٨ حەب مەخۆ تاوەکو زیان بە جگەر نەگات.',
        'warnings': 'لەگەڵ دەرمانی تری پاراسیتامۆڵ تێکەڵی مەکە، و پێش خەوتن نەیخۆیت چاکترە.',
      },
      {
        'mode': 'medicine',
        'title': 'Augmentin (ئۆگمێنتین 1g)',
        'category': 'دژەهەوکردنی بەهێز • دژە بەکتریا',
        'date': 'پێش دوو ڕۆژ',
        'confidence': '99.2%',
        'summary': 'ئۆگمێنتین ئەنتی بایۆتیکێکی زۆر بەهێزە بۆ هەوکردنی توندی سییەکان، جیوب، گوێی ناوەڕاست و پێست.',
        'markers': [
          {'name': 'پێکهاتەی چالاک', 'value': 'Amoxicillin + Clavulanate', 'status': 'چالاک', 'isNormal': true},
          {'name': 'شێوەی دەرمان', 'value': 'حەب (Tablet)', 'status': 'ئاسایی', 'isNormal': true},
          {'name': 'ژەم و کات', 'value': 'ڕۆژی ٢ جار (هەر ١٢ کاتژمێر)', 'status': 'ڕێنمایی', 'isNormal': true},
        ],
        'recommendations': 'لەگەڵ خواردندا بیخۆ بۆ ئەوەی گەدەت پارێزراو بێت.',
        'warnings': 'کۆرسەکە بە تەواوی وەربگرە و لە ژەم مەپەڕێنە.',
      },
      {
        'mode': 'medicine',
        'title': 'Omeprazole (ئۆمیپرازۆڵ 20mg)',
        'category': 'دژە ترشەڵۆک • پارێزەری گەدە',
        'date': 'پێش سێ ڕۆژ',
        'confidence': '99.3%',
        'summary': 'چارەسەری دڵەکزێ، کەمکردنەوەی ترشی گەدە و چاکبوونەوەی برینی گەدە و دوازدەگرێ دەکات.',
        'markers': [
          {'name': 'پێکهاتەی چالاک', 'value': 'Omeprazole 20mg', 'status': 'چالاک', 'isNormal': true},
          {'name': 'شێوەی دەرمان', 'value': 'کەپسول (Capsule)', 'status': 'ئاسایی', 'isNormal': true},
          {'name': 'ژەم و کات', 'value': 'ڕۆژی ١ جار بەیانیان بە گەدەی بەتاڵ', 'status': 'ڕێنمایی', 'isNormal': true},
        ],
        'recommendations': 'کەپسولەکە بە تەواوی بیلووشە و مەیجوو.',
        'warnings': 'دوور بکەوەرەوە لە خواردنی توند، ترش و چەور لە کاتی چارەسەردا.',
      },
    ];
  }

  List<Map<String, dynamic>> _getAllRecentScans(BuildContext context) {
    final lang = context.locale.languageCode;
    return [..._userScans, ..._getLocalizedDefaultScans(lang)];
  }

  @override
  void initState() {
    super.initState();
    _currentMode = 'medicine';
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );

      if (picked != null) {
        final imageFile = File(picked.path);
        setState(() {
          _scannedImage = imageFile;
          _isAnalyzing = true;
          _analysisStep = 1;
          _scanResult = null;
        });

        // Visual step progression while Gemini AI analyzes the image
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && _isAnalyzing) setState(() => _analysisStep = 2);
        });

        Future.delayed(const Duration(milliseconds: 2600), () {
          if (mounted && _isAnalyzing) setState(() => _analysisStep = 3);
        });

        // Call the real Gemini AI Clinical Vision Service with current locale
        final currentLang = mounted ? context.locale.languageCode : 'ckb';
        final realResult = await AiClinicalVisionService.instance.analyzeMedicalImage(
          imageFile: imageFile,
          mode: _currentMode,
          language: currentLang,
        );

        if (mounted) {
          realResult['date'] = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());

          setState(() {
            _analysisStep = 3;
            _isAnalyzing = false;
            _scanResult = realResult;
            _userScans.insert(0, realResult);
          });
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedImage = null;
      _scanResult = null;
      _isAnalyzing = false;
      _analysisStep = 0;
    });
  }

  void _showMedicineSearchModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = context.locale.languageCode;
    final library = AiClinicalVisionService.instance.getMedicineLibrary(language: currentLang);
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = library.where((m) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase().trim();
              return m['title'].toString().toLowerCase().contains(q) ||
                  m['category'].toString().toLowerCase().contains(q) ||
                  m['summary'].toString().toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.search_normal_1,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'گەڕان بۆ شیکاری دەرمان',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search box
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'ناوی دەرمان بنووسە (Panadol, Amox, Brufen...)',
                        hintStyle: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Iconsax.search_normal_1,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'هیچ دەرمانێک نەدۆزرایەوە',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final med = filtered[i];
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _scannedImage = null;
                                    _currentMode = 'medicine';
                                    _scanResult = Map<String, dynamic>.from(med);
                                    _scanResult!['date'] = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
                                    _userScans.insert(0, _scanResult!);
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.medication_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med['title'],
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              med['category'],
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ai_scanner_title'.tr(),
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ai_scanner_subtitle'.tr(),
                  style: _kStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_scanResult != null || _scannedImage != null)
            IconButton(
              tooltip: 'ai_scan_another'.tr(),
              icon: Icon(
                Iconsax.refresh,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main Scanner Viewport / Status ──
            if (_isAnalyzing)
              _buildScanningState(isDark)
            else if (_scanResult != null)
              _buildResultDetails(isDark)
            else
              _buildInitialScannerHub(isDark),

            const SizedBox(height: 24),

            // ── Recent Scans History ──
            _buildRecentScansSection(isDark),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ── 1. Initial Interactive Scanner Hub ──
  Widget _buildInitialScannerHub(bool isDark) {
    final isLab = _currentMode == 'lab';
    final primaryColor = isLab ? const Color(0xFF2563EB) : const Color(0xFF0D9488);

    return Column(
      children: [
        // Holographic Viewfinder Frame
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
                primaryColor.withValues(alpha: isDark ? 0.35 : 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 4 Corner brackets
              Positioned(top: 20, left: 20, child: _buildCornerBracket(isTop: true, isLeft: true, color: primaryColor)),
              Positioned(top: 20, right: 20, child: _buildCornerBracket(isTop: true, isLeft: false, color: primaryColor)),
              Positioned(bottom: 20, left: 20, child: _buildCornerBracket(isTop: false, isLeft: true, color: primaryColor)),
              Positioned(bottom: 20, right: 20, child: _buildCornerBracket(isTop: false, isLeft: false, color: primaryColor)),

              // Center Icon & Prompt
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: primaryColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ai_scan_box_title'.tr(),
                    textAlign: TextAlign.center,
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'ai_scan_box_desc'.tr(),
                      textAlign: TextAlign.center,
                      style: _kStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Direct Scan Buttons (Camera / Gallery) ──
        Row(
          children: [
            // Camera Scan Button
            Expanded(
              child: GestureDetector(
                onTap: () => _pickAndAnalyze(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLab
                          ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                          : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ai_camera'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Gallery Upload Button
            Expanded(
              child: GestureDetector(
                onTap: () => _pickAndAnalyze(ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.gallery, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ai_gallery'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Medicine by Name Button
        GestureDetector(
          onTap: _showMedicineSearchModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.search_normal_1,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'گەڕان و شیکاری بەپێی ناوی دەرمان',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Real-time Holographic Scanning State ──
  Widget _buildScanningState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Preview with Scanning Laser Line
          if (_scannedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.file(
                    _scannedImage!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  ),
                  // Animated Laser Scan Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF10B981),
                            Color(0xFF2563EB),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .moveY(begin: 0, end: 215, duration: 1200.ms, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 22),

          // Step Progress Indicators
          _buildAnalysisStepItem(
            stepNumber: 1,
            title: 'ai_scanning_step1'.tr(),
            isActive: _analysisStep >= 1,
            isDone: _analysisStep > 1,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 2,
            title: 'ai_scanning_step2'.tr(),
            isActive: _analysisStep >= 2,
            isDone: _analysisStep > 2,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 3,
            title: 'ai_scanning_step3'.tr(),
            isActive: _analysisStep >= 3,
            isDone: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStepItem({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isDone,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF10B981)
                : (isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B).withValues(alpha: 0.2)),
          ),
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Center(
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: _kStyle(
              color: isDone
                  ? const Color(0xFF10B981)
                  : (isActive ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF94A3B8)),
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Diagnostic Clinical Analysis Result Details ──
  Widget _buildResultDetails(bool isDark) {
    final res = _scanResult!;
    const primaryColor = Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Thumbnail + Title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_scannedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _scannedImage!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white, size: 30),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${res['confidence']} • ${'ai_verified_analysis'.tr()}',
                        style: _kStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      res['title'],
                      style: _kStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      res['category'],
                      style: _kStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Summary Card
        _buildMedicalInfoCard(
          title: 'ai_summary_title'.tr(),
          content: res['summary'],
          icon: Icons.medication_rounded,
          iconColor: const Color(0xFF10B981),
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        // Key Biomarkers / Procedures Breakdown Card
        if (res['markers'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ai_details_title'.tr(),
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((res['markers'] as List).map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m['name'],
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              m['value'],
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m['status'],
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Recommendations Card
        _buildMedicalInfoCard(
          title: 'ai_recommendations_title'.tr(),
          content: res['recommendations'],
          icon: Iconsax.lamp_on,
          iconColor: const Color(0xFF3B82F6),
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        // Warnings Card
        _buildMedicalInfoCard(
          title: 'ai_warnings_title'.tr(),
          content: res['warnings'],
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Primary Action: Scan another medicine
        GestureDetector(
          onTap: _resetScanner,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.refresh, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'ai_scan_another'.tr(),
                  style: _kStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Recent Clinical Scans History ──
  Widget _buildRecentScansSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ai_recent_scans'.tr(),
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ai_accuracy_badge'.tr(),
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final recentList = _getAllRecentScans(context);
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = recentList[idx];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentMode = item['mode'];
                    _scanResult = item;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['category'],
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
              );
            },
          );
        },
      ),
    ],
  );
}

  Widget _buildCornerBracket({required bool isTop, required bool isLeft, required Color color}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
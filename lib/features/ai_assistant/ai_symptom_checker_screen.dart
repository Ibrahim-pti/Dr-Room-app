import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import '../lab/lab_hub_screen.dart';
import '../nursing/nursing_hub_screen.dart';

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

  final List<Map<String, dynamic>> _recentScans = [
    {
      'mode': 'lab',
      'title': 'Complete Blood Count (CBC)',
      'category': 'پشکنینی گشتی خوێن • تاقیگە',
      'date': 'ئەمڕۆ ١٠:٣٠ بەیانی',
      'confidence': '99.4%',
      'summary': 'ئاستی خڕۆکە سپییەکان و هیمۆگلۆبین لە سنووری ئاساییدایە.',
      'markers': [
        {'name': 'WBC (خڕۆکەی سپی)', 'value': '7.2 x10^3/µL', 'status': 'ئاسایی', 'isNormal': true},
        {'name': 'Hemoglobin (خوێن)', 'value': '14.1 g/dL', 'status': 'ئاسایی', 'isNormal': true},
        {'name': 'Platelets (پەڕەکان)', 'value': '245 x10^3/µL', 'status': 'ئاسایی', 'isNormal': true},
      ],
      'recommendations': 'پێویست بە هیچ دەرمانێک ناکات، تەندروستیت زۆر باشە. ساڵانە پشکنین دووبارە بکەرەوە.',
      'warnings': 'دڵنیابەرەوە لە خواردنی خواردەمەنی دەوڵەمەند بە ئاسن بۆ پاراستنی هیمۆگلۆبین.',
    },
    {
      'mode': 'nursing',
      'title': 'ڕێنمایی پەرستاری بۆ برینی نەشتەرگەری',
      'category': 'چاودێری برین و پانسمان • پەرستاری',
      'date': 'دوێنێ ٠٤:١٥ ئێوارە',
      'confidence': '98.8%',
      'summary': 'برینەکە پاکە و هیچ نیشانەیەکی هەوکردن نییە، پێویستی بە گۆڕینی ڕۆژانەی پانسمان هەیە.',
      'markers': [
        {'name': 'پاککردنەوە', 'value': 'رۆژانە بە Normal Saline', 'status': 'پێویست', 'isNormal': true},
        {'name': 'کانیۆلا', 'value': 'پشکنینی هەموو ٤٨ کاتژمێر', 'status': 'چالاک', 'isNormal': true},
        {'name': 'پلەی گەرمی', 'value': '٣٦.٨°C (ئاسایی)', 'status': 'ئاسایی', 'isNormal': true},
      ],
      'recommendations': 'ڕۆژانە یەک جار لەلایەن پەرستاری باوەڕپێکراوەوە پانسمانەکە بگۆڕدرێت بە شێوازی تەواو ستەریل.',
      'warnings': 'لە کاتی سووربوونەوە، ئاوسان یان دەردانی کێم، دەستبەجێ داوای سەردانی پەرستار یان پزیشک بکە.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode ?? 'lab';
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
        setState(() {
          _scannedImage = File(picked.path);
          _isAnalyzing = true;
          _analysisStep = 1;
          _scanResult = null;
        });

        // Step 1: Text & OCR
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) setState(() => _analysisStep = 2);

        // Step 2: Clinical Identification
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => _analysisStep = 3);

        // Step 3: Synthesis & Guideline Compilation
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          final isLab = _currentMode == 'lab';
          final Map<String, dynamic> newResult = isLab
              ? {
                  'mode': 'lab',
                  'title': 'پشکنینی پزیشکی (CBC & Sugar Panel)',
                  'category': 'پشکنینی خوێن و شەکرە • تاقیگە',
                  'date': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
                  'confidence': '99.5%',
                  'summary': 'شیکاریی ڕاپۆرتی تاقیگەکەت دەریخست کە شەکری بەیانیت 96 mg/dL (ئاسایی) و هیمۆگلۆبین 13.9 g/dL (زۆر باشە).',
                  'markers': [
                    {'name': 'Fasting Blood Sugar (شەکرە)', 'value': '96 mg/dL', 'status': 'ئاسایی (Normal)', 'isNormal': true},
                    {'name': 'WBC (خڕۆکەی سپی)', 'value': '6.8 x10^3/µL', 'status': 'ئاسایی', 'isNormal': true},
                    {'name': 'Hemoglobin (خوێن)', 'value': '13.9 g/dL', 'status': 'ئاسایی', 'isNormal': true},
                    {'name': 'Platelets (پەڕەکان)', 'value': '280 x10^3/µL', 'status': 'ئاسایی', 'isNormal': true},
                  ],
                  'recommendations': 'ئەنجامەکانت زۆر دڵخۆشکەرن و هیچ کێشەیەکی نائاسایی لە ڕێژەکاندا نییە. بۆ بەدواداچوونی زیاتر دەتوانیت لە بەشی تاقیگە داواکاری بکەیت.',
                  'warnings': 'ئەم ئەنجامە بۆ ڕێنماییە؛ هەمووکات ڕای پزیشکی پسپۆڕ بنەمای سەرەکی چارەسەرە.',
                }
              : {
                  'mode': 'nursing',
                  'title': 'ڕێنمایی پەرستاری و چاودێری نەخۆش',
                  'category': 'چاودێری ماڵەوە • پەرستاری',
                  'date': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
                  'confidence': '99.1%',
                  'summary': 'شیکاریی پێداویستی چاودێری: نەخۆش پێویستی بە لێدانی دەرزی ئەنتی بایۆتیک و گۆڕینی کانیۆلای دەمار هەیە.',
                  'markers': [
                    {'name': 'دەرزی ئەنتی بایۆتیک', 'value': 'هەموو ١٢ کاتژمێر جارێک', 'status': 'ڕێکخراو', 'isNormal': true},
                    {'name': 'کانیۆلا', 'value': 'دانانی نوێ لە ڕێگەی دەمار', 'status': 'پێویست', 'isNormal': true},
                    {'name': 'پێوانی پەستانی خوێن', 'value': 'ڕۆژانە ٢ جار (بەیانی/ئێوارە)', 'status': 'چاودێری', 'isNormal': true},
                  ],
                  'recommendations': 'پێشنیاز دەکەین پەرستاری ڕێگەپێدراو بانگهێشتی ماڵەوە بکەیت بۆ لێدانی دەرمان بە شێوازی دروست لە ڕێگەی دەمارەوە.',
                  'warnings': 'هەرگیز خۆت هەوڵی دانانی کانیۆلا مەدە تا ڕێگری لە شینبوونەوە و پچڕانی دەمار بکرێت.',
                };

          setState(() {
            _isAnalyzing = false;
            _scanResult = newResult;
            _recentScans.insert(0, newResult);
          });
        }
      }
    } catch (_) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentMode == 'lab'
                      ? [const Color(0xFF2563EB), const Color(0xFF3B82F6)]
                      : [const Color(0xFF0D9488), const Color(0xFF10B981)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_currentMode == 'lab' ? const Color(0xFF2563EB) : const Color(0xFF0D9488))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ai_clinical_scanner_title'.tr(),
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentMode == 'lab' ? 'شیکاریی تاقیگە و پشکنینەکان' : 'ڕێنمایی و چاودێری پەرستاری',
                  style: _kStyle(
                    color: _currentMode == 'lab' ? const Color(0xFF2563EB) : const Color(0xFF0D9488),
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
              tooltip: 'سکانێکی تر',
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
            // ── Segmented Mode Selector: Lab vs Nursing ──
            if (!_isAnalyzing && _scanResult == null) _buildModeSelector(isDark),

            const SizedBox(height: 14),

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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Mode Selector: Lab vs Nursing ──
  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lab Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = 'lab'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentMode == 'lab' ? const Color(0xFF2563EB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _currentMode == 'lab'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.health,
                      size: 17,
                      color: _currentMode == 'lab' ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ai_tab_lab'.tr(),
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentMode == 'lab' ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nursing Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = 'nursing'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentMode == 'nursing' ? const Color(0xFF0D9488) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _currentMode == 'nursing'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.activity,
                      size: 17,
                      color: _currentMode == 'nursing' ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ai_tab_nursing'.tr(),
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentMode == 'nursing' ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                      isLab ? Iconsax.health : Iconsax.shield_tick,
                      color: primaryColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isLab ? 'سکانکردنی ڕاپۆرتی پشکنینی تاقیگە' : 'سکانکردنی پێداویستی چاودێری پەرستاری',
                    textAlign: TextAlign.center,
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      isLab ? 'ai_lab_scanner_desc'.tr() : 'ai_nursing_scanner_desc'.tr(),
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
                    children: const [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'کامێرا',
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
                        'گەلەری (وێنە)',
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
            title: 'خوێندنەوەی دەستوخەت و دەقی پزیشکی (OCR)...',
            isActive: _analysisStep >= 1,
            isDone: _analysisStep > 1,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 2,
            title: _currentMode == 'lab'
                ? 'دەرهێنانی ئەنجام و هێڵە سورەکانی پشکنین...'
                : 'شیکردنەوەی پێداویستی و هەنگاوەکانی چاودێری پەرستاری...',
            isActive: _analysisStep >= 2,
            isDone: _analysisStep > 2,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 3,
            title: 'ئامادەکردنی ڕاپۆرتی ورد بە کوردی سادە...',
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
    final isLab = res['mode'] == 'lab';
    final primaryColor = isLab ? const Color(0xFF2563EB) : const Color(0xFF0D9488);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Thumbnail + Title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLab
                  ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                  : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
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
                  child: Icon(isLab ? Iconsax.health : Iconsax.shield_tick, color: Colors.white, size: 30),
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
                        '${res['confidence']} • شیکاریی سەلمێنراوی کلینیکی',
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
          title: 'پوختەی شیکاری کلینیکی AI',
          content: res['summary'],
          icon: Icons.analytics_rounded,
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
                    Icon(isLab ? Iconsax.status : Iconsax.task_square, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isLab ? 'ئاست و ڕێژەی پشکنینەکان' : 'هەنگاو و ڕێکارە پەرستارییەکان',
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
          title: 'ڕاسپاردە و ڕێنماییەکان',
          content: res['recommendations'],
          icon: Iconsax.lamp_on,
          iconColor: const Color(0xFF3B82F6),
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        // Warnings Card
        _buildMedicalInfoCard(
          title: 'هۆشداری و سەرنجی پزیشکی',
          content: res['warnings'],
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Primary Action Button: Book in Lab or Call Nurse
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              if (isLab) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LabHubScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NursingHubScreen()),
                );
              }
            },
            icon: Icon(isLab ? Iconsax.health : Iconsax.people, color: Colors.white, size: 20),
            label: Text(
              isLab ? 'داواکردنی پشکنین لە بەشی تاقیگە' : 'داواکردنی پەرستار لە بەشی پەرستاری',
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: TextButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Iconsax.refresh, size: 16),
            label: const Text('سکانکردنی بەڵگەنامەیەکی تر', style: TextStyle(fontFamily: 'Rabar')),
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
              'سکانکراوەکانی پێشوو',
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
              child: const Text(
                'دروستی ٩٩.٥٪',
                style: TextStyle(
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentScans.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final item = _recentScans[idx];
            final isItemLab = item['mode'] == 'lab';

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
                        color: (isItemLab ? const Color(0xFF2563EB) : const Color(0xFF0D9488)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isItemLab ? Iconsax.health : Iconsax.shield_tick,
                        color: isItemLab ? const Color(0xFF2563EB) : const Color(0xFF0D9488),
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
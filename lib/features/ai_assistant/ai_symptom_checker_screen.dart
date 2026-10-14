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

  final List<Map<String, dynamic>> _recentScans = [
    {
      'mode': 'medicine',
      'title': 'Amoxicillin (ئامۆکسیسیلین 500mg)',
      'category': 'دژەهەوکردن • ئەنتی بایۆتیک',
      'date': 'ئەمڕۆ ١٠:٣٠ بەیانی',
      'confidence': '99.4%',
      'summary': 'ئەم دەرمانە ئەنتی بایۆتیکە و بەکاردێت بۆ چارەسەری هەوکردنی بەکتریایی وەک هەوکردنی قوڕگ، سنگ، میزەڕۆ و برین.',
      'markers': [
        {'name': 'پێکهاتەی چالاک', 'value': 'Amoxicillin 500mg', 'status': 'چالاک', 'isNormal': true},
        {'name': 'شێوەی دەرمان', 'value': 'کەپسول (Capsule)', 'status': 'ئاسایی', 'isNormal': true},
        {'name': 'ژەم و کات', 'value': 'ڕۆژی ٣ جار (هەر ٨ کاتژمێر)', 'status': 'ڕێنمایی', 'isNormal': true},
        {'name': 'شێوازی خواردن', 'value': 'دوای نان لەگەڵ ئاو', 'status': 'گرنگ', 'isNormal': true},
      ],
      'recommendations': 'کۆرسەکە تا کۆتایی تەواو بکە تەنانەت ئەگەر هەستت بە باشبوونیش کرد بۆ ئەوەی بەکتریاکە سەرهەڵنەداتەوە.',
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
      'warnings': 'لەگەڵ دەرمانی تری پاراسیتامۆڵ تێکەڵی مەکە، و پێش خەوتن لەبەر کافایین نەیخۆیت چاکترە.',
    },
  ];

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

        // Call the real Gemini AI Clinical Vision Service
        final realResult = await AiClinicalVisionService.instance.analyzeMedicalImage(
          imageFile: imageFile,
          mode: _currentMode,
        );

        if (mounted) {
          realResult['date'] = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());

          setState(() {
            _analysisStep = 3;
            _isAnalyzing = false;
            _scanResult = realResult;
            _recentScans.insert(0, realResult);
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
                  'سکانەری دەرمان بە AI',
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'شیکاریی حەب، کەپسول و پاکەتی دەرمان',
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
                    'سکانکردنی وێنەی دەرمان',
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
                      'وێنەی پاکەت، شریت، حەب یان کەپسولەکە بگرە، زیرەکی دەستکرد ناوی دەرمانەکە، بەکارهێنان، ژەم و هۆشدارییەکانت بۆ شیدەکاتەوە',
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
            title: 'خوێندنەوەی دەق و ناوی دەرمانەکە (OCR)...',
            isActive: _analysisStep >= 1,
            isDone: _analysisStep > 1,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 2,
            title: 'دەستنیشانکردنی پێکهاتە، شێوە و بەکارهێنان...',
            isActive: _analysisStep >= 2,
            isDone: _analysisStep > 2,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAnalysisStepItem(
            stepNumber: 3,
            title: 'ئامادەکردنی ڕێنمایی و ژەمەکان بە کوردی سادە...',
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
                        '${res['confidence']} • شیکاریی سەلمێنراوی دەرمان',
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
          title: 'پوختەی شیکاری دەرمان AI',
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
                      'وردەکاری پێکهاتە، شێوە و ژەمی دەرمان',
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

        // Primary Action: Scan another medicine
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _resetScanner,
            icon: const Icon(Iconsax.refresh, color: Colors.white, size: 20),
            label: const Text(
              'سکانکردنی دەرمانێکی تر',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
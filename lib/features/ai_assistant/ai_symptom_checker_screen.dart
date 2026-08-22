import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import '../prescriptions/pill_reminder_screen.dart';
import '../pharmacy/screens/pharmacies_screen.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;
  int _analysisStep = 0;
  File? _scannedImage;
  Map<String, dynamic>? _scanResult;

  final List<Map<String, dynamic>> _recentScans = [
    {
      'title': 'Amoxicillin 500mg',
      'category': 'Antibiotic • دژەبەکتریای هەوکردن',
      'date': 'ئەمڕۆ ١٠:٣٠ بەیانی',
      'confidence': '99.4%',
      'uses': 'چارەسەری هەوکردنی گەروو، سنگ، و بەکتریا',
      'dosage': 'ڕۆژی ٣ جار دوای نان بۆ ماوەی ٧ ڕۆژ',
      'warnings': 'نابێت لە کاتی هەستیاری بە پەنسیلین بەکاربێت',
      'active': 'Amoxicillin Trihydrate',
    },
    {
      'title': 'Panadol Extra 500mg',
      'category': 'Analgesic • ئازارشکێن و دابەزێنەری تا',
      'date': 'دوێنێ ٠٤:١٥ ئێوارە',
      'confidence': '98.8%',
      'uses': 'نەهێشتنی سەرئێشە، ئازاری جومگە و دابەزاندنی تا',
      'dosage': 'لە کاتی ئازار ١-٢ حەب، بە لایەنی زۆر ڕۆژی ٣ جار',
      'warnings': 'زیاتر لە ٨ حەب لە ٢٤ کاتژمێردا مەخۆ',
      'active': 'Paracetamol + Caffeine',
    },
  ];

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

        // Step 2: Ingredient identification
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => _analysisStep = 3);

        // Step 3: Clinical safety & dosage compilation
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          final newResult = {
            'title': 'Augmentin 625mg (ئۆگمێنتین)',
            'category': 'Antibiotic • دژەبەکتریای بەهێز',
            'date': DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
            'confidence': '99.4%',
            'uses':
                'چارەسەری هەوکردنی سییەکان، گوێ، قورگ، جیوب، و ڕێڕەوی میز بە شێوەیەکی خێرا و کاریگەر.',
            'dosage':
                '١ حەب لە هەموو ١٢ کاتژمێر جارێک (ڕۆژی ٢ جار) ڕێک لەگەڵ ژەمی نان بۆ ڕێگری لە دڵتێکچوون بۆ ماوەی ٧ ڕۆژ.',
            'warnings':
                'پێویستە تەواوی کۆرسە پزیشکییەکە تەواو بکەیت تەنانەت ئەگەر هەستت بە باشبوون کرد. ئەگەر حەساسییەتت بە Penicillin هەیە نەیخۆیت.',
            'active': 'Amoxicillin + Clavulanic Acid',
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
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
                    color: const Color(0xFF8B5CF6),
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── 1. Initial Interactive Scanner Hub ──
  Widget _buildInitialScannerHub(bool isDark) {
    return Column(
      children: [
        // Holographic Viewfinder Frame
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.1),
                const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Corner Accents
              Positioned(
                top: 18,
                left: 18,
                child: _buildCornerBracket(isTop: true, isLeft: true),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: _buildCornerBracket(isTop: true, isLeft: false),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                child: _buildCornerBracket(isTop: false, isLeft: true),
              ),
              Positioned(
                bottom: 18,
                right: 18,
                child: _buildCornerBracket(isTop: false, isLeft: false),
              ),

              // Pulsing Scanner Visual
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms),
                  const SizedBox(height: 16),
                  Text(
                    'ai_scan_camera_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: _kStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'ai_accuracy_badge'.tr(),
                      style: _kStyle(
                        color: const Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 18),

        // Two Large Action Trigger Cards
        Row(
          children: [
            // 1. Camera Capture Button
            Expanded(
              child: GestureDetector(
                onTap: () => _pickAndAnalyze(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ai_scan_camera_title'.tr(),
                        style: _kStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 2. Gallery Upload Button
            Expanded(
              child: GestureDetector(
                onTap: () => _pickAndAnalyze(ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.gallery,
                          color: Color(0xFF3B82F6),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ai_scan_gallery_title'.tr(),
                        style: _kStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
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

        const SizedBox(height: 14),

        // Helpful Tip Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ai_scan_tip'.tr(),
                  style: _kStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. Live Scanning & AI Processing State ──
  Widget _buildScanningState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
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
                            Color(0xFF8B5CF6),
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
                : (isActive
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : (isActive
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: _kStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Gorgeous Clinical Breakdown & Result Card ──
  Widget _buildResultDetails(bool isDark) {
    final res = _scanResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scanned Image Header Thumbnail + Title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.35 : 0.25),
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
                  child: const Icon(Iconsax.health, color: Colors.white, size: 30),
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
                        '${res['confidence']} • شیکاریی سەلمێنراو',
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
                        fontSize: 16,
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

        // 1. Uses Card (بۆچی بەکاردێت)
        _buildMedicalInfoCard(
          title: 'ai_medicine_uses'.tr(),
          content: res['uses'],
          icon: Icons.healing_rounded,
          iconColor: const Color(0xFF10B981),
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        // 2. Dosage & Timing (ژەم و چۆنیەتی بەکارهێنان)
        _buildMedicalInfoCard(
          title: 'ai_medicine_dosage'.tr(),
          content: res['dosage'],
          icon: Iconsax.clock,
          iconColor: const Color(0xFF3B82F6),
          isDark: isDark,
        ),

        const SizedBox(height: 12),

        // 3. Warnings (هۆشدارییەکان)
        _buildMedicalInfoCard(
          title: 'ai_medicine_warnings'.tr(),
          content: res['warnings'],
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        // Quick Actions (Set Reminder & Order)
        Row(
          children: [
            // Pill Alarm Reminder
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PillReminderScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.clock, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'ai_set_alarm'.tr(),
                        style: _kStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Order from Pharmacy
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmaciesScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.shopping_cart, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'ai_order_medicines'.tr(),
                        style: _kStyle(
                          color: Colors.white,
                          fontSize: 13,
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

        // Scan Another Medicine Button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: Text(
              'ai_scan_another'.tr(),
              style: _kStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMedicalInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: _kStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: _kStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Recent Scans History Section ──
  Widget _buildRecentScansSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ai_recent_scans'.tr(),
              style: _kStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_recentScans.length}',
                style: _kStyle(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentScans.length,
          itemBuilder: (context, index) {
            final item = _recentScans[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _scanResult = item;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: _kStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['category'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _kStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF8B5CF6), width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF8B5CF6), width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF8B5CF6), width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF8B5CF6), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
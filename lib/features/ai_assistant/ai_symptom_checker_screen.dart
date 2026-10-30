import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// SharedPreferences key for this patient's scan history. Cleared on logout
  /// by [SessionService] so the next person on the phone can't see it.
  static const String scansStorageKey = 'ai_medicine_scans';
  static const int _maxStoredScans = 20;

  Future<void> _loadScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(scansStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List || !mounted) return;
      setState(() {
        _userScans
          ..clear()
          ..addAll(decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      });
    } catch (e) {
      debugPrint('Failed to load scan history: $e');
    }
  }

  Future<void> _saveScans() async {
    try {
      if (_userScans.length > _maxStoredScans) {
        _userScans.removeRange(_maxStoredScans, _userScans.length);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(scansStorageKey, jsonEncode(_userScans));
    } catch (e) {
      debugPrint('Failed to save scan history: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentMode = 'medicine';
    _loadScans();
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
        if (!mounted) return;
        _showImagePreviewAndNoteDialog(imageFile, source);
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  void _showImagePreviewAndNoteDialog(File initialImage, ImageSource source) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteController = TextEditingController();
    File currentImage = initialImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pull handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ai_image_note_title'.tr(),
                              style: _kStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Image Preview Box
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Image.file(
                              currentImage,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () async {
                                  final XFile? rePicked = await _picker.pickImage(
                                    source: source,
                                    maxWidth: 1800,
                                    maxHeight: 1800,
                                    imageQuality: 88,
                                  );
                                  if (rePicked != null) {
                                    setModalState(() {
                                      currentImage = File(rePicked.path);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ai_change_image'.tr(),
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white,
                                          fontSize: 11.5,
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
                      ),

                      const SizedBox(height: 14),

                      // Text Input Field at bottom of Image
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          ),
                        ),
                        child: TextField(
                          controller: noteController,
                          maxLines: 3,
                          minLines: 1,
                          textInputAction: TextInputAction.done,
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ai_image_note_hint'.tr(),
                            hintStyle: _kStyle(
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: Color(0xFF3B82F6),
                                size: 24,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Disclaimer Banner
                      _buildDisclaimerBanner(isDark: isDark),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'ai_cancel'.tr(),
                                style: _kStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                final note = noteController.text.trim();
                                Navigator.pop(ctx);
                                _startImageAnalysis(
                                  currentImage,
                                  userNote: note.isNotEmpty ? note : null,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ai_analyze_image_btn'.tr(),
                                      style: _kStyle(
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
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startImageAnalysis(File imageFile, {String? userNote}) async {
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

    try {
      final currentLang = mounted ? context.locale.languageCode : 'ckb';
      final realResult = await AiClinicalVisionService.instance.analyzeMedicalImage(
        imageFile: imageFile,
        mode: _currentMode,
        userNote: userNote,
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
        _saveScans();
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

  Future<void> _performMedicineSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _scannedImage = null;
      _isAnalyzing = true;
      _analysisStep = 1;
      _scanResult = null;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _isAnalyzing) setState(() => _analysisStep = 2);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _isAnalyzing) setState(() => _analysisStep = 3);
    });

    try {
      final currentLang = mounted ? context.locale.languageCode : 'ckb';
      final realResult = await AiClinicalVisionService.instance.searchMedicineByName(
        query: cleanQuery,
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
        _saveScans();
      }
    } catch (e) {
      debugPrint('Medicine search error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showSearchMedicineDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ai_search_medicine'.tr(),
                        style: _kStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'ai_search_medicine_desc'.tr(),
                  style: _kStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // TextField for medicine input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Navigator.pop(ctx);
                        _performMedicineSearch(value.trim());
                      }
                    },
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ai_search_medicine_hint'.tr(),
                      hintStyle: _kStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontSize: 12.5,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Medical Disclaimer inside the Search Dialog
                _buildDisclaimerBanner(isDark: isDark),

                const SizedBox(height: 18),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ai_cancel'.tr(),
                          style: _kStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final q = controller.text.trim();
                          if (q.isNotEmpty) {
                            Navigator.pop(ctx);
                            _performMedicineSearch(q);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'ai_search_btn'.tr(),
                                style: _kStyle(
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
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisclaimerBanner({required bool isDark, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
            : const Color(0xFFFEF3C7).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.38),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Color(0xFFD97706),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ai_disclaimer_notice'.tr(),
              style: _kStyle(
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
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
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
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
                Icons.document_scanner_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ai_scanner_title'.tr(),
              style: _kStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                      Icons.document_scanner_rounded,
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

        if (widget.initialMode != 'lab') ...[
          const SizedBox(height: 14),

          // AI Medicine Name Search Action Card
          GestureDetector(
            onTap: _showSearchMedicineDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ai_search_medicine'.tr(),
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ai_search_medicine_desc'.tr(),
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
          ),
        ],

        const SizedBox(height: 16),

        // Medical Disclaimer Notice Banner
        _buildDisclaimerBanner(isDark: isDark),
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
          // Image Preview with Scanning Laser Line OR AI Search Animation
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08),
                    const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 30)
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1000.ms),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ai_searching'.tr(),
                    textAlign: TextAlign.center,
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
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
                  child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 30),
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

        const SizedBox(height: 14),

        // Medical Disclaimer Notice Banner in Result
        _buildDisclaimerBanner(isDark: isDark),

        // Patient User Note Card
        if (res['user_note'] != null && res['user_note'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF3B82F6),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ai_your_note'.tr(),
                        style: _kStyle(
                          color: const Color(0xFF3B82F6),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        res['user_note'].toString(),
                        style: _kStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Summary Card (Title text removed as requested)
        _buildMedicalInfoCard(
          content: res['summary'],
          icon: Icons.document_scanner_rounded,
          iconColor: const Color(0xFF10B981),
          isDark: isDark,
        ),

        // Target Age Card (بۆ تەمەن چەندە)
        if (res['target_age'] != null && res['target_age'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMedicalInfoCard(
            title: 'ai_target_age_title'.tr(),
            content: res['target_age'],
            icon: Icons.people_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            isDark: isDark,
          ),
        ],

        // Allergies & Contraindications Card (هەستیارییەکان)
        if (res['allergies'] != null && res['allergies'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMedicalInfoCard(
            title: 'ai_allergies_title'.tr(),
            content: res['allergies'],
            icon: Icons.health_and_safety_outlined,
            iconColor: const Color(0xFFE11D48),
            isDark: isDark,
          ),
        ],

        const SizedBox(height: 12),

        // Key Biomarkers / Clinical Details Breakdown Card
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
                    Expanded(
                      child: Text(
                        'ai_details_title'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((res['markers'] as List).map((m) {
                  final isAbnormal = m['isNormal'] == false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                (m['name'] ?? '').toString(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (m['status'] != null &&
                                m['status'].toString().trim().isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (isAbnormal
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m['status'].toString(),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAbnormal
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (m['value'] != null &&
                            m['value'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m['value'].toString(),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1D4ED8),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
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

        if (widget.initialMode != 'lab') ...[
          const SizedBox(height: 10),

          // Secondary Action: Search medicine by name with AI
          GestureDetector(
            onTap: _showSearchMedicineDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ai_search_medicine'.tr(),
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMedicalInfoCard({
    String? title,
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
          if (title != null && title.trim().isNotEmpty) ...[
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.55,
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
        Text(
          'ai_recent_scans'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final recentList = _userScans;
            if (recentList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded, size: 32, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      'ai_no_recent_scans'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }
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
                    _currentMode = (item['mode'] ?? 'medicine').toString();
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
                        Icons.document_scanner_rounded,
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
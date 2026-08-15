import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const MedicalHistoryScreen({super.key, required this.onFinished});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool? _hasAllergies = false;
  bool? _hasChronicDiseases = false;
  bool? _takesMedications = false;
  bool? _smokes = false;

  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  static const Color primaryColor = Color(0xFF2563EB);

  Future<void> _completeSetup() async {
    if (_hasAllergies == null ||
        _hasChronicDiseases == null ||
        _takesMedications == null ||
        _smokes == null) {
      _showError();
      return;
    }

    if ((_hasAllergies == true && _allergiesController.text.trim().isEmpty) ||
        (_hasChronicDiseases == true &&
            _chronicController.text.trim().isEmpty) ||
        (_takesMedications == true &&
            _medicationsController.text.trim().isEmpty)) {
      _showError();
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('guest_has_allergies', _hasAllergies!);
    if (_hasAllergies == true) {
      await prefs.setString(
        'guest_allergies_details',
        _allergiesController.text.trim(),
      );
    }

    await prefs.setBool('guest_has_chronic', _hasChronicDiseases!);
    if (_hasChronicDiseases == true) {
      await prefs.setString(
        'guest_chronic_details',
        _chronicController.text.trim(),
      );
    }

    await prefs.setBool('guest_takes_meds', _takesMedications!);
    if (_takesMedications == true) {
      await prefs.setString(
        'guest_meds_details',
        _medicationsController.text.trim(),
      );
    }

    await prefs.setBool('guest_smokes', _smokes!);
    await prefs.setBool('has_completed_setup', true);

    if (mounted) {
      widget.onFinished();
    }
  }

  Future<void> _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);
    if (mounted) {
      widget.onFinished();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تکایە هەموو پرسیارەکان دیاری بکە',
          style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _chronicController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Ambient Glows ──
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.10),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Header Bar with Progress (Step 3 of 3) ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'هەنگاوی ٣ لە ٣',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '١٠٠٪',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: 1.0,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _skipSetup,
                        style: TextButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'تێپەڕاندن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: subtitleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Title
                        Center(
                          child: Text(
                            'مێژووی پزیشکی',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.3,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                        ),

                        const SizedBox(height: 6),

                        Center(
                          child: Text(
                            'ئەم زانیارییانە یارمەتی پزیشکەکان دەدەن باشترین چاودێریت بکەن',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13.5,
                              color: subtitleColor,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                        ),

                        const SizedBox(height: 24),

                        // Question cards
                        _buildQuestionRow(
                          question: 'ئایا هەستیاریت (حەساسییەت) بە هیچ شتێک هەیە؟',
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFFFBEB),
                          value: _hasAllergies,
                          onChanged: (val) =>
                              setState(() => _hasAllergies = val),
                          controller: _allergiesController,
                          hintText: 'ناوی هەستیاری بنووسە (بۆ نموونە: دەرمان یان خۆراک)',
                          delay: 150,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        _buildQuestionRow(
                          question: 'ئایا نەخۆشی درێژخایەنت هەیە؟',
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFEF4444),
                          iconBg: const Color(0xFFFEF2F2),
                          value: _hasChronicDiseases,
                          onChanged: (val) =>
                              setState(() => _hasChronicDiseases = val),
                          controller: _chronicController,
                          hintText: 'ناوی نەخۆشییەکە بنووسە (بۆ نموونە: شەکرە یان زەخت)',
                          delay: 250,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        _buildQuestionRow(
                          question: 'ئایا ڕۆژانە هیچ جۆرە دەرمانێک بەکاردەهێنیت؟',
                          icon: Icons.medication_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          iconBg: const Color(0xFFF5F3FF),
                          value: _takesMedications,
                          onChanged: (val) =>
                              setState(() => _takesMedications = val),
                          controller: _medicationsController,
                          hintText: 'ناوی دەرمانەکان بنووسە',
                          delay: 350,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        _buildQuestionRow(
                          question: 'ئایا جگەرە یان نێرگەلە دەکێشیت؟',
                          icon: Icons.smoke_free_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFECFDF5),
                          value: _smokes,
                          onChanged: (val) => setState(() => _smokes = val),
                          delay: 450,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'تەواوکردنی سێتەپ',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionRow({
    required String question,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool? value,
    required ValueChanged<bool> onChanged,
    TextEditingController? controller,
    String? hintText,
    required int delay,
    required Color cardBg,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value == true
              ? primaryColor.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: value == true ? 1.5 : 1,
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
          // Question row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.15)
                      : iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Yes / No toggle
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildToggle(
                  label: 'بەڵێ',
                  isSelected: value == true,
                  onTap: () => onChanged(true),
                  selectedColor: primaryColor,
                  isDark: isDark,
                ),
                _buildToggle(
                  label: 'نەخێر',
                  isSelected: value == false,
                  onTap: () => onChanged(false),
                  selectedColor: const Color(0xFF64748B),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Detail field when Yes
          if (value == true && controller != null && hintText != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Rabar',
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Rabar',
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 12.5,
                ),
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.1),
          ],
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

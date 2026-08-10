import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const MedicalHistoryScreen({super.key, required this.onFinished});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool? _hasAllergies;
  bool? _hasChronicDiseases;
  bool? _takesMedications;
  bool? _smokes;

  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color secondarySlate = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

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

    if (mounted) {
      widget.onFinished();
    }
  }

  void _skipSetup() {
    if (mounted) {
      widget.onFinished();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'fill_all_fields'.tr(),
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(progress: 1.0),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Title
                    Center(
                      child: Text(
                        'medical_history_title'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkSlate,
                          height: 1.3,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'medical_history_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: secondarySlate,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ),

                    const SizedBox(height: 28),

                    // Question cards
                    _buildQuestionRow(
                      question: 'allergies_question'.tr(),
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFFFBEB),
                      value: _hasAllergies,
                      onChanged: (val) => setState(() => _hasAllergies = val),
                      controller: _allergiesController,
                      hintText: 'allergies_hint'.tr(),
                      delay: 150,
                    ),

                    _buildQuestionRow(
                      question: 'chronic_diseases_question'.tr(),
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEF2F2),
                      value: _hasChronicDiseases,
                      onChanged: (val) =>
                          setState(() => _hasChronicDiseases = val),
                      controller: _chronicController,
                      hintText: 'chronic_diseases_hint'.tr(),
                      delay: 250,
                    ),

                    _buildQuestionRow(
                      question: 'medications_question'.tr(),
                      icon: Icons.medication_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFFF5F3FF),
                      value: _takesMedications,
                      onChanged: (val) =>
                          setState(() => _takesMedications = val),
                      controller: _medicationsController,
                      hintText: 'medications_hint'.tr(),
                      delay: 350,
                    ),

                    _buildQuestionRow(
                      question: 'smoking_question'.tr(),
                      icon: Icons.smoke_free_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFECFDF5),
                      value: _smokes,
                      onChanged: (val) => setState(() => _smokes = val),
                      delay: 450,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'finish_setup'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader({required double progress}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: darkSlate,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _skipSetup,
            style: TextButton.styleFrom(
              foregroundColor: secondarySlate,
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text('skip'.tr()),
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
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value != null
                  ? primaryColor.withValues(alpha: 0.25)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
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
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkSlate,
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildToggle(
                      label: 'yes'.tr(),
                      isSelected: value == true,
                      onTap: () => onChanged(true),
                      selectedColor: primaryColor,
                    ),
                    _buildToggle(
                      label: 'no'.tr(),
                      isSelected: value == false,
                      onTap: () => onChanged(false),
                      selectedColor: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),

              // Detail field when Yes
              if (value == true && controller != null && hintText != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    color: darkSlate,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.1),
              ],
            ],
          ),
        ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.06, end: 0),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
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
                      color: selectedColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : secondarySlate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

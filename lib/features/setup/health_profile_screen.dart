import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProfileScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const HealthProfileScreen({super.key, required this.onFinished});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  String? _selectedGender;
  String? _selectedBloodType;
  int _selectedAge = 22;
  final TextEditingController _ageController = TextEditingController();

  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color lightBlueSoft = Color(0xFFEFF6FF);
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color secondarySlate = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _ageController.text = _selectedAge.toString();
  }

  Future<void> _completeSetup() async {
    if (_selectedGender == null ||
        _selectedBloodType == null ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'fill_all_fields'.tr(),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);

    if (_selectedGender != null) {
      await prefs.setString('guest_gender', _selectedGender!);
    }
    if (_selectedBloodType != null) {
      await prefs.setString('guest_blood_type', _selectedBloodType!);
    }
    if (_ageController.text.isNotEmpty) {
      await prefs.setString('guest_age', _ageController.text);
    }

    if (mounted) {
      widget.onFinished();
    }
  }

  void _skipSetup() {
    widget.onFinished();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar with Progress Indicator & Skip
            _buildTopHeader(progress: 0.66),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Page Title
                    Center(
                      child: Text(
                        'health_profile_title'.tr(),
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
                        'health_profile_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: secondarySlate,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ),

                    const SizedBox(height: 28),

                    // Gender Selection Section
                    Text(
                      'gender'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkSlate,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderCard(
                            'male'.tr(),
                            Icons.male_rounded,
                            'Male',
                            delay: 200,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGenderCard(
                            'female'.tr(),
                            Icons.female_rounded,
                            'Female',
                            delay: 250,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Age Picker (Wheel style like mockup)
                    _buildAgeWheelPicker().animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 28),

                    // Blood Type Chips Section
                    _buildBloodTypeChips().animate().fadeIn(delay: 350.ms),

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
                        'continue_btn'.tr(),
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

  Widget _buildGenderCard(
    String title,
    IconData icon,
    String value, {
    required int delay,
  }) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? lightBlueSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? primaryColor : secondarySlate,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected ? primaryColor : darkSlate,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildAgeWheelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'age'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkSlate,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: lightBlueSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),
              CupertinoPicker(
                itemExtent: 46,
                scrollController: FixedExtentScrollController(
                  initialItem: (_selectedAge - 1).clamp(0, 119),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedAge = index + 1;
                    _ageController.text = _selectedAge.toString();
                  });
                },
                selectionOverlay: const SizedBox(),
                children: List.generate(120, (index) {
                  final age = index + 1;
                  final isSelected = age == _selectedAge;
                  return Center(
                    child: Text(
                      '$age',
                      style: GoogleFonts.poppins(
                        fontSize: isSelected ? 28 : 18,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'blood_type'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkSlate,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _bloodTypes.map((type) {
            final isSelected = _selectedBloodType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedBloodType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : darkSlate,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

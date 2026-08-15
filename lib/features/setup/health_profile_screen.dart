import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProfileScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const HealthProfileScreen({super.key, required this.onFinished});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  String? _selectedGender = 'Male';
  String? _selectedBloodType = 'A+';
  int _selectedAge = 24;
  final TextEditingController _ageController = TextEditingController();

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color lightBlueSoft = Color(0xFFEFF6FF);

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
          content: const Text(
            'تکایە هەموو خانەکان پڕبکەرەوە',
            style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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

  Future<void> _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
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
                // ── Top Header Bar with Progress (Step 2 of 3) ──
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
                                  'هەنگاوی ٢ لە ٣',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '٦٦٪',
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
                                value: 0.66,
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
                            'پرۆفایلی تەندروستی',
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
                            'زانیارییە سەرەتاییەکانت یارمەتیمان دەدات خزمەتگوزارییەکانت بۆ گونجاو بکەین',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13.5,
                              color: subtitleColor,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                        ),

                        const SizedBox(height: 28),

                        // Gender Selection Section
                        Text(
                          'ڕەگەز',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderCard(
                                'نێر',
                                Icons.male_rounded,
                                'Male',
                                delay: 200,
                                cardBg: cardBg,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildGenderCard(
                                'مێ',
                                Icons.female_rounded,
                                'Female',
                                delay: 250,
                                cardBg: cardBg,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // Age Picker
                        _buildAgeWheelPicker(cardBg: cardBg, isDark: isDark, textColor: textColor)
                            .animate()
                            .fadeIn(delay: 300.ms),

                        const SizedBox(height: 26),

                        // Blood Type Chips Section
                        _buildBloodTypeChips(cardBg: cardBg, isDark: isDark, textColor: textColor)
                            .animate()
                            .fadeIn(delay: 350.ms),

                        const SizedBox(height: 24),
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
                              'بەردەوامبوون',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
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

  Widget _buildGenderCard(
    String title,
    IconData icon,
    String value, {
    required int delay,
    required Color cardBg,
    required bool isDark,
  }) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                  : lightBlueSoft)
              : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
              color: isSelected
                  ? primaryColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildAgeWheelPicker({
    required Color cardBg,
    required bool isDark,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تەمەن',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : lightBlueSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              ),
              CupertinoPicker(
                itemExtent: 44,
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
                      '$age ساڵ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: isSelected ? 22 : 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
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

  Widget _buildBloodTypeChips({
    required Color cardBg,
    required bool isDark,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'گروپی خوێن',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: textColor,
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
                  color: isSelected ? primaryColor : cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
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
                      color: isSelected ? Colors.white : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
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

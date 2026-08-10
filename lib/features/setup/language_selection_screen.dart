import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const LanguageSelectionScreen({super.key, required this.onFinished});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLocale = 'en';

  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color lightBlueSoft = Color(0xFFEFF6FF);
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color secondarySlate = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  void _proceedToHealthProfile() {
    context.setLocale(Locale(_selectedLocale));
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgSurface,
        body: SafeArea(
          child: Column(
            children: [
              // Top Header Bar with 33% Progress Indicator
              _buildTopHeader(progress: 0.33),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Language Icon Header
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: lightBlueSoft,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          size: 48,
                          color: primaryColor,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 28),

                      // Title
                      Text(
                            'select_language'.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkSlate,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 40),

                      // Language Cards
                      _buildLangCard(
                        title: 'کوردی',
                        subtitleKey: 'lang_kurdish',
                        localeCode: 'ckb',
                        flag: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SvgPicture.asset(
                            'assets/images/kurdistan_flag.svg',
                            width: 32,
                            height: 22,
                            fit: BoxFit.cover,
                          ),
                        ),
                        delay: 300,
                      ),
                      const SizedBox(height: 16),
                      _buildLangCard(
                        title: 'English',
                        subtitleKey: 'lang_english',
                        localeCode: 'en',
                        flag: const Text(
                          '🇬🇧',
                          style: TextStyle(fontSize: 26),
                        ),
                        delay: 400,
                      ),
                      const SizedBox(height: 16),
                      _buildLangCard(
                        title: 'العربية',
                        subtitleKey: 'lang_arabic',
                        localeCode: 'ar',
                        flag: const Text(
                          '🇸🇦',
                          style: TextStyle(fontSize: 26),
                        ),
                        delay: 500,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Continue Button (Pill Shape)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _proceedToHealthProfile,
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
      ),
    );
  }

  Widget _buildTopHeader({required double progress}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 40),
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
            onPressed: _proceedToHealthProfile,
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

  Widget _buildLangCard({
    required String title,
    required String subtitleKey,
    required String localeCode,
    required Widget flag,
    required int delay,
  }) {
    final isSelected = _selectedLocale == localeCode;
    return GestureDetector(
      onTap: () => setState(() => _selectedLocale = localeCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: flag)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                subtitleKey.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryColor : darkSlate,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0),
    );
  }
}

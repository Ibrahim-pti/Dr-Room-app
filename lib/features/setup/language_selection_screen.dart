import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const LanguageSelectionScreen({super.key, required this.onFinished});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLocale = 'ckb';

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    // Default to current locale or ckb
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLocale = context.locale.languageCode == 'ar'
              ? 'ar'
              : context.locale.languageCode == 'en'
                  ? 'en'
                  : 'ckb';
        });
      }
    });
  }

  void _proceedToHealthProfile() {
    context.setLocale(Locale(_selectedLocale));
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Ambient Background Glows ──
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
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryBlue.withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Progress Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Progress Bar (Step 1 of 3)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'step_1_of_3'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '٣٣٪',
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
                                value: 0.33,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Skip Button
                      TextButton(
                        onPressed: _proceedToHealthProfile,
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
                          'skip'.tr(),
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

                // ── Scrollable Body Content ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // ── Language Header Icon ──
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        ),

                        const SizedBox(height: 20),

                        // ── Title & Subtitle ──
                        Text(
                          'select_language'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 8),

                        Text(
                          'select_language_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 13.5,
                            color: subtitleColor,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 32),

                        // ── Language Cards ──
                        _buildLangCard(
                          title: 'کوردی',
                          subtitle: 'Kurdish (سۆرانی)',
                          localeCode: 'ckb',
                          flag: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SvgPicture.asset(
                              'assets/images/kurdistan_flag.svg',
                              width: 38,
                              height: 26,
                              fit: BoxFit.cover,
                            ),
                          ),
                          delay: 300,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 16),

                        _buildLangCard(
                          title: 'English',
                          subtitle: 'ئینگلیزی',
                          localeCode: 'en',
                          flag: Container(
                            width: 38,
                            height: 26,
                            alignment: Alignment.center,
                            child: const Text(
                              '🇬🇧',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                          delay: 400,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 16),

                        _buildLangCard(
                          title: 'العربية',
                          subtitle: 'عەرەبی',
                          localeCode: 'ar',
                          flag: Container(
                            width: 38,
                            height: 26,
                            alignment: Alignment.center,
                            child: const Text(
                              '🇮🇶',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                          delay: 500,
                          cardBg: cardBg,
                          isDark: isDark,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Continue Button ──
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
                        onPressed: _proceedToHealthProfile,
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
                          children: [
                            Text(
                              'continue_btn'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard({
    required String title,
    required String subtitle,
    required String localeCode,
    required Widget flag,
    required int delay,
    required Color cardBg,
    required bool isDark,
    required Color textColor,
  }) {
    final isSelected = _selectedLocale == localeCode;

    return GestureDetector(
      onTap: () => setState(() => _selectedLocale = localeCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                  : const Color(0xFFEFF6FF))
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
                  ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag Container
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
              ),
              child: flag,
            ),
            const SizedBox(width: 16),

            // Language Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12.5,
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.8)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Custom Selection Radio Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.15, end: 0);
  }
}

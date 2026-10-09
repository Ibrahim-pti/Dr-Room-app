import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'titleKey': 'onboarding_page1_title',
      'subtitleKey': 'onboarding_page1_subtitle',
      'image': 'assets/images/onboarding_doctor.png',
      'primaryColor': const Color(0xFF2563EB),
      'secondaryColor': const Color(0xFF3B82F6),
      'gradient': const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      'chipKey': 'onboarding_page1_chip',
      'chipIcon': Iconsax.user_tag,
    },
    {
      'titleKey': 'onboarding_page2_title',
      'subtitleKey': 'onboarding_page2_subtitle',
      'image': 'assets/images/onboarding_pharmacy.png',
      'primaryColor': const Color(0xFF059669),
      'secondaryColor': const Color(0xFF10B981),
      'gradient': const [Color(0xFF047857), Color(0xFF10B981)],
      'chipKey': 'onboarding_page2_chip',
      'chipIcon': Iconsax.clock,
    },
    {
      'titleKey': 'onboarding_page3_title',
      'subtitleKey': 'onboarding_page3_subtitle',
      'image': 'assets/images/onboarding_lab.png',
      'primaryColor': const Color(0xFF6366F1),
      'secondaryColor': const Color(0xFF8B5CF6),
      'gradient': const [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
      'chipKey': 'onboarding_page3_chip',
      'chipIcon': Iconsax.document_text,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinished();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == _pages.length - 1;
    final currentItem = _pages[_currentPage];
    final activeColor = currentItem['primaryColor'] as Color;
    final activeGradient = currentItem['gradient'] as List<Color>;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Ambient Background Glow ──
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: isDark ? 0.18 : 0.12),
              ),
            ),
          ),

          // ── PageView Carousel ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final item = _pages[index];
              final pageColor = item['primaryColor'] as Color;
              final gradient = item['gradient'] as List<Color>;

              return Column(
                children: [
                  // ── Top Artwork Section ──
                  Container(
                    height: size.height * 0.54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradient[0].withValues(alpha: isDark ? 0.35 : 0.12),
                          gradient[1].withValues(alpha: isDark ? 0.12 : 0.04),
                          isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 76, bottom: 6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radial glow behind artwork
                              Container(
                                width: size.width * 0.72,
                                height: size.height * 0.36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      pageColor.withValues(
                                        alpha: isDark ? 0.28 : 0.18,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              // Big Transparent 3D Artwork
                              Image.asset(
                                item['image'] as String,
                                fit: BoxFit.contain,
                                height: size.height * 0.40,
                                width: size.width * 0.85,
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom Content Card ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),

                          // Highlight Feature Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: pageColor.withValues(
                                alpha: isDark ? 0.22 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: pageColor.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['chipIcon'] as IconData,
                                  size: 14,
                                  color: pageColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (item['chipKey'] as String).tr(),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: pageColor,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 16),

                          // Big Bold Title
                          Text(
                            (item['titleKey'] as String).tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(
                            begin: 0.2,
                            end: 0,
                          ),

                          const SizedBox(height: 10),

                          // Subtitle
                          Text(
                            (item['subtitleKey'] as String).tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(
                            begin: 0.2,
                            end: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Space for the bottom fixed buttons
                  const SizedBox(height: 110),
                ],
              );
            },
          ),

          // ── Fixed Top Bar (Logo + Skip) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Branding
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'app_name'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (!isLastPage)
                    TextButton(
                      onPressed: widget.onFinished,
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Text(
                        'skip'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // ── Fixed Bottom Controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                        .withValues(alpha: 0.0),
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Page Indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: activeColor,
                          dotColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                          spacing: 6,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Action Button Row (Back + Next/Start)
                      Row(
                        children: [
                          // Previous Page Button
                          if (_currentPage > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.04,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _previousPage,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),

                          // Main Action Button (Gradient)
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: activeGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isLastPage ? 'get_started_btn'.tr() : 'next_btn'.tr(),
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
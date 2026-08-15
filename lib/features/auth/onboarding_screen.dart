import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
      'title': 'پزیشکانی پسپۆڕ و باوەڕپێکراو',
      'subtitle': 'نۆرەگرتنی ئاسان و ڕاوێژی خێرا لە باشترین دکتۆرەکانی کوردستان لە هەر کات و شوێنێک بیت.',
      'image': 'assets/images/doctor.png',
      'badgeIcon': Iconsax.verify,
      'badgeText': 'پزیشکانی باوەڕپێکراو',
      'badgeColor': Color(0xFF10B981),
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'دەرمانخانە و گەیاندنی دەستبەجێ',
      'subtitle': 'داواکردنی دەرمان و پێداویستییە تەندروستییەکان لە نزیکترین دەرمانخانە بە خێراترین کات بۆ بەردەم ماڵەکەت.',
      'image': 'assets/images/medicine.png',
      'badgeIcon': Iconsax.truck_fast,
      'badgeText': 'گەیاندنی خێرا',
      'badgeColor': Color(0xFF8B5CF6),
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'تاقیگە و پشکنینی پزیشکی لە ماڵەوە',
      'subtitle': 'ئەنجامدانی پشکنینە پزیشکییەکان لە ماڵەوە بە بەرزترین کوالێتی و وەرگرتنەوەی ئەنجام بە شێوەی دیجیتاڵی.',
      'image': 'assets/images/lab.png',
      'badgeIcon': Iconsax.health,
      'badgeText': 'ڕاپۆرتی سەرهێڵ',
      'badgeColor': Color(0xFF0D9488),
      'color': Color(0xFF0D9488),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background Ambient Glow ──
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage]['color'].withValues(alpha: 0.15),
              ),
            ),
          ).animate(target: _currentPage.toDouble()).fadeIn(duration: 400.ms),

          Positioned(
            bottom: 120,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage]['color'].withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Header / Skip Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Logo / Name
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
                              Icons.local_hospital_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dr. Room',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),

                      // Skip Button
                      if (!isLastPage)
                        GestureDetector(
                          onTap: widget.onFinished,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'تێپەڕاندن',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Carousel Content ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration Container with Card Glow
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: size.width * 0.72,
                                  height: size.width * 0.72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        (item['color'] as Color).withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 220,
                                  height: 220,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (item['color'] as Color).withValues(alpha: 0.18),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    item['image'] as String,
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                // Floating Feature Badge
                                Positioned(
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (item['badgeColor'] as Color).withValues(alpha: 0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item['badgeIcon'] as IconData,
                                          size: 14,
                                          color: item['badgeColor'] as Color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item['badgeText'] as String,
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            color: item['badgeColor'] as Color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                            const SizedBox(height: 36),

                            // Title
                            Text(
                              item['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              item['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                height: 1.6,
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ── Bottom Navigation & Indicator ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Smooth Page Dots Indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: _pages[_currentPage]['color'] as Color,
                          dotColor: const Color(0xFFE2E8F0),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3.5,
                          spacing: 6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Next / Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'دەستپێبکە' : 'دواتر',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

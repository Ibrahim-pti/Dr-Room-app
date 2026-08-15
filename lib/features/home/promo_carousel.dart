import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class PromoCarousel extends StatefulWidget {
  final List<dynamic> banners;
  const PromoCarousel({super.key, this.banners = const []});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  String _getTranslated(dynamic data, String field, String langCode) {
    if (langCode == 'en' && data['${field}_en'] != null) {
      return data['${field}_en'];
    }
    if (langCode == 'ar' && data['${field}_ar'] != null) {
      return data['${field}_ar'];
    }
    return data[field] ?? '';
  }

  final List<Map<String, dynamic>> _fallbackPromos = [
    {
      'title': 'Get 20% Off on Full\nBody Checkup',
      'subtitle': 'Valid until 30th Nov',
      'color1': const Color(0xFF3B82F6),
      'color2': const Color(0xFF2563EB),
    },
    {
      'title': 'Free Virtual\nConsultation',
      'subtitle': 'For first-time users',
      'color1': const Color(0xFF8B5CF6),
      'color2': const Color(0xFF6D28D9),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        int itemsCount = widget.banners.isNotEmpty ? widget.banners.length : _fallbackPromos.length;
        if (nextPage >= itemsCount) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final itemsCount = widget.banners.isNotEmpty ? widget.banners.length : _fallbackPromos.length;
    
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: itemsCount,
            itemBuilder: (context, index) {
              final isApiData = widget.banners.isNotEmpty;
              final promo = isApiData ? widget.banners[index] : _fallbackPromos[index];
              final title = isApiData ? _getTranslated(promo, 'title', langCode) : promo['title'];
              
              final gradients = [
                [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
                [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
              ];
              final colors = gradients[index % gradients.length];
              final rawPath = promo['image_path']?.toString();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative glow circles
                    PositionedDirectional(
                      end: -25,
                      top: -25,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 45,
                      bottom: -35,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SPECIAL OFFER',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            itemsCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

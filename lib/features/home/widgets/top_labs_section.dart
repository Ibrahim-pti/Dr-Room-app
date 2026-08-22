import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/localization_extensions.dart';
import '../../lab/all_labs_screen.dart';
import '../../lab/lab_details_screen.dart';
import '../data/home_mock_data.dart';

class TopLabsSection extends StatelessWidget {
  const TopLabsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final labs = HomeMockData.fallbackLabs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'top_labs'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: AppColors.getTextTitle(context),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllLabsScreen(),
                    ),
                  );
                },
                child: Text(
                  'see_all'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF3B82F6),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 550.ms),

        const SizedBox(height: 12),

        // ── Top Labs Horizontal List ──
        SizedBox(
          height: 204,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: labs.length,
            itemBuilder: (context, index) {
              final lab = labs[index];
              final name = context.localizedField(lab, 'name', fallback: 'cat_lab'.tr());
              final city = context.localizedField(lab, 'city', fallback: context.localizedField(lab, 'address', fallback: 'هەولێر'));
              final time = lab['time'] ?? '٢٥-٣٥ خولەک';
              final rating = (lab['rating'] != null) ? lab['rating'].toString() : '4.9';
              final imagePath = lab['image'] ?? 'assets/images/lab1.jpg';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LabDetailsScreen(lab: lab),
                    ),
                  );
                },
                child: Container(
                  width: 172,
                  margin: const EdgeInsetsDirectional.only(
                    end: 14,
                    bottom: 6,
                    top: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Image Section ──
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                            child: Container(
                              height: 96,
                              width: double.infinity,
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Top Category Badge
                          PositionedDirectional(
                            top: 6,
                            start: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF312E81).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.biotech_rounded,
                                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'cat_lab'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Rating Badge
                          PositionedDirectional(
                            bottom: 6,
                            end: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.5,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Details Section ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.location,
                                  color: Color(0xFF3B82F6),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    city,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.clock,
                                  color: Color(0xFF94A3B8),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Iconsax.shield_tick,
                                        color: Color(0xFF10B981),
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'open_status'.tr(),
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Color(0xFF10B981),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

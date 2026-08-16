import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
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
          height: 198,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: labs.length,
            itemBuilder: (context, index) {
              final lab = labs[index];
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
                  width: 175,
                  margin: const EdgeInsetsDirectional.only(
                    end: 14,
                    bottom: 6,
                    top: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
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
                      // Top Image Section
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(19),
                            ),
                            child: Container(
                              height: 92,
                              width: double.infinity,
                              color: const Color(0xFFF8FAFC),
                              child: Image.asset(
                                lab['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Rating Badge
                          PositionedDirectional(
                            bottom: 6,
                            end: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(10),
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
                                children: const [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 13,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Color(0xFF1E293B),
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

                      // Details Section
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lab['name']!,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.location,
                                  color: Color(0xFF3B82F6),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    lab['city']!,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.clock,
                                  color: Color(0xFF94A3B8),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  lab['time']!,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    fontSize: 10,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Iconsax.shield_tick,
                                        color: Color(0xFF10B981),
                                        size: 10,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'کراوەیە',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Color(0xFF10B981),
                                          fontSize: 9.5,
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
              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideY(begin: 0.08, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

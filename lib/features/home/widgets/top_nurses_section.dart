import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_client.dart';
import '../../nursing/nurse_list_screen.dart';
import '../../nursing/nurse_details_screen.dart';
import '../data/home_mock_data.dart';

import '../../../core/utils/localization_extensions.dart';

class TopNursesSection extends StatelessWidget {
  final List<dynamic> topNurses;

  const TopNursesSection({super.key, required this.topNurses});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final nursesList = topNurses.isNotEmpty
        ? topNurses
        : HomeMockData.fallbackNurses;

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
                'top_nurses'.tr(),
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
                      builder: (context) => const NurseListScreen(),
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
        ).animate().fadeIn(delay: 450.ms),

        const SizedBox(height: 12),

        // ── Compact & Polished Nurse Cards ──
        SizedBox(
          height: 192,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: nursesList.length,
            itemBuilder: (context, index) {
              final nurse = nursesList[index];
              final userObj = nurse['user'] is Map ? nurse['user'] : nurse;
              final name = context.localizedField(
                userObj,
                'name',
                fallback: 'nurse'.tr(),
              );
              final specialty = context.localizedField(
                nurse,
                'specialty',
                fallback: context.localizedField(
                  nurse,
                  'bio',
                  fallback: 'desc_nursing'.tr(),
                ),
              );
              final rating = nurse['rating']?.toString() ?? '4.9';
              final totalReviews = nurse['total_reviews'] ?? 45;
              final reviews = '($totalReviews)';

              final rawPath =
                  nurse['image']?.toString() ?? nurse['image_path']?.toString();
              final isCustomUpload =
                  rawPath != null &&
                  rawPath.isNotEmpty &&
                  !rawPath.contains('default');
              final image = isCustomUpload
                  ? (rawPath.startsWith('http') || rawPath.startsWith('assets/')
                        ? rawPath
                        : ApiClient.getImageUrl(rawPath))
                  : 'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=400&h=300&fit=crop&crop=face,top&q=80';
              final isNetworkImg = image.startsWith('http');

              final nurseMap = Map<String, dynamic>.from(nurse);

              return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NurseDetailsScreen(nurse: nurseMap),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsetsDirectional.only(
                        end: 12,
                        bottom: 5,
                        top: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Image Container ──
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(17),
                                ),
                                child: Container(
                                  height: 90,
                                  width: double.infinity,
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFEFF6FF),
                                  child: isNetworkImg
                                      ? CachedNetworkImage(
                                          imageUrl: image,
                                          fit: BoxFit.cover,
                                          alignment: const Alignment(0, -0.4),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 38,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                        )
                                      : Image.asset(
                                          image,
                                          fit: BoxFit.cover,
                                          alignment: const Alignment(0, -0.4),
                                        ),
                                ),
                              ),
                              // Favorite Icon
                              PositionedDirectional(
                                top: 6,
                                end: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Content ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  specialty,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 11,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating,
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        color: Color(0xFFD97706),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      reviews,
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Action Button
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF3B82F6,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Iconsax.calendar_1,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'request_service'.tr(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
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
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (500 + (index * 60)).ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

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

class TopNursesSection extends StatelessWidget {
  final List<dynamic> topNurses;

  const TopNursesSection({super.key, required this.topNurses});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final nursesList = topNurses.isNotEmpty ? topNurses : HomeMockData.fallbackNurses;

    final fallbackImages = [
      'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=500&auto=format&fit=crop&q=80',
    ];

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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: nursesList.length,
            itemBuilder: (context, index) {
              final nurse = nursesList[index];
              final name = nurse['user'] != null
                  ? nurse['user']['name']
                  : (nurse['name'] ?? 'پەرستار');
              final specialty = nurse['specialty'] ?? 'پەرستاری ماڵەوە و فریاگوزاری';
              final rating = nurse['rating']?.toString() ?? '4.9';
              final totalReviews = nurse['total_reviews'] ?? 45;
              final reviews = '($totalReviews)';

              final fallbackImage = fallbackImages[index % fallbackImages.length];
              final rawPath = nurse['image']?.toString() ?? nurse['image_path']?.toString();
              final isCustomUpload = rawPath != null &&
                  rawPath.isNotEmpty &&
                  !rawPath.contains('assets/images') &&
                  !rawPath.contains('default');
              final image = isCustomUpload
                  ? (rawPath.startsWith('http') ? rawPath : ApiClient.getImageUrl(rawPath))
                  : fallbackImage;
              final isNetworkImg = image.startsWith('http');

              final nurseMap = Map<String, dynamic>.from(nurse);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NurseDetailsScreen(nurse: nurseMap),
                    ),
                  );
                },
                child: Container(
                  width: 148,
                  margin: const EdgeInsetsDirectional.only(
                    end: 12,
                    bottom: 6,
                    top: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: 1.0,
                    ),
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
                      // Top Image Container
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                            child: Container(
                              height: 96,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: isNetworkImg
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0, -0.3),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.person,
                                        size: 38,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    )
                                  : Image.asset(
                                      image,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0, -0.3),
                                    ),
                            ),
                          ),
                          // Favorite Icon
                          PositionedDirectional(
                            top: 6,
                            end: 6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11.5,
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
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontSize: 9.5,
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
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Color(0xFFD97706),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  reviews,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Action Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Iconsax.calendar_1,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'داواکردنی خزمەتگوزاری',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white,
                                      fontSize: 9.5,
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
              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

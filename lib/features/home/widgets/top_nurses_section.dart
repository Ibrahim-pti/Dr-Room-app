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
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=500&auto=format&fit=crop&q=80',
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

        // ── Nurse Cards Horizontal List ──
        SizedBox(
          height: 236,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: nursesList.length,
            itemBuilder: (context, index) {
              final nurse = nursesList[index];
              final name = nurse['user'] != null
                  ? nurse['user']['name']
                  : (nurse['name'] ?? 'پەرستار');
              final specialty = nurse['specialty'] ?? 'پەرستاری گشتی';
              final rating = nurse['rating']?.toString() ?? '4.9';
              final totalReviews = nurse['total_reviews'] ?? 40;
              final reviews = '($totalReviews)';
              final isAvailable = nurse['is_available'] == true;

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
                  width: 165,
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
                      // Top Image Container
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(19),
                            ),
                            child: Container(
                              height: 114,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF0F172A),
                                          const Color(0xFF1E293B),
                                        ]
                                      : [
                                          const Color(0xFFF0FDF4),
                                          const Color(0xFFDCFCE7),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: isNetworkImg
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0, -0.15),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.person,
                                        size: 45,
                                        color: Color(0xFF0D9488),
                                      ),
                                    )
                                  : Image.asset(
                                      image,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0, -0.15),
                                    ),
                            ),
                          ),
                          // Availability / Verified Tag
                          PositionedDirectional(
                            top: 6,
                            start: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable ? const Color(0xFF10B981) : Colors.grey[600],
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAvailable ? const Color(0xFF10B981) : Colors.grey)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAvailable ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isAvailable ? 'ئامادەیە' : 'ئامادە نییە',
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // City Badge
                          if (nurse['city'] != null && nurse['city'].toString().isNotEmpty)
                            PositionedDirectional(
                              top: 6,
                              end: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  nurse['city'].toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 12.5,
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
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rating,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Color(0xFFD97706),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  reviews,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Request Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                    blurRadius: 4,
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
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'داواکردنی خزمەتگوزاری',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white,
                                      fontSize: 10.5,
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

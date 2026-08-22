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
      'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=500&auto=format&fit=crop&q=80',
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

        // ── Modern Sleek Nurse Cards ──
        SizedBox(
          height: 232,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: nursesList.length,
            itemBuilder: (context, index) {
              final nurse = nursesList[index];
              final name = nurse['user'] != null
                  ? nurse['user']['name']
                  : (nurse['name'] ?? 'پەرستار');
              final specialty = nurse['specialty'] ?? 'پەرستاری ماڵەوە و برینپێچی';
              final city = (nurse['city'] != null && nurse['city'].toString().isNotEmpty)
                  ? nurse['city'].toString()
                  : 'هەولێر';
              final rating = nurse['rating']?.toString() ?? '4.9';
              final isAvailable = nurse['is_available'] != false;

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
                  width: 162,
                  margin: const EdgeInsetsDirectional.only(
                    end: 14,
                    bottom: 6,
                    top: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: borderColor,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : const Color(0xFF0F172A).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                              top: Radius.circular(21),
                            ),
                            child: Container(
                              height: 112,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                                      : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: isNetworkImg
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 44,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      image,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    ),
                            ),
                          ),

                          // Rating badge (Top End)
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
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
                                    size: 13,
                                  ),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    rating,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Availability Pill (Top Start)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (isAvailable ? const Color(0xFF059669) : Colors.grey[700]!)
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAvailable ? const Color(0xFF059669) : Colors.black)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3.5),
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
                        ],
                      ),

                      // ── Details Section ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                specialty,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              // Location & Book Button
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
                                      city,
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF059669)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'داواکردن',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

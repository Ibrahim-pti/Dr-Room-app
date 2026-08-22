import 'package:dr_room/core/utils/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_client.dart';
import '../../doctors/all_doctors_screen.dart';


import '../data/home_mock_data.dart';
import '../../doctors/doctor_details_screen.dart';

class TopDoctorsSection extends StatelessWidget {
  final List<dynamic> topDoctors;

  const TopDoctorsSection({super.key, required this.topDoctors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final doctorsList = topDoctors.isNotEmpty
        ? topDoctors
        : HomeMockData.fallbackDoctors;

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
                'top_doctors'.tr(),
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
                      builder: (context) => const AllDoctorsScreen(),
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

        // ── Compact & Polished Doctor Cards ──
        SizedBox(
          height: 236,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: doctorsList.length,
            itemBuilder: (context, index) {
              final doc = doctorsList[index];
              final userObj = doc['user'] is Map ? doc['user'] : doc;
              final name = context.localizedField(
                userObj,
                'name',
                fallback: 'cat_doctor'.tr(),
              );
              final specialty = context.localizedField(
                doc,
                'specialty',
                fallback: context.localizedField(
                  doc,
                  'bio',
                  fallback: 'desc_doctor'.tr(),
                ),
              );
              final rating = doc['rating']?.toString() ?? '4.8';
              final totalReviews = doc['total_reviews'] ?? 45;
              final reviews = '($totalReviews)';

              final fallbackImages = [
                'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=500&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=500&auto=format&fit=crop&q=80',
              ];
              final fallbackImage =
                  fallbackImages[index % fallbackImages.length];

              final rawPath = doc['image_path']?.toString();
              final isCustomUpload =
                  rawPath != null &&
                  rawPath.isNotEmpty &&
                  !rawPath.contains('assets/images/doctor') &&
                  !rawPath.contains('default');
              final image = isCustomUpload
                  ? (rawPath.startsWith('http')
                        ? rawPath
                        : ApiClient.getImageUrl(rawPath))
                  : fallbackImage;
              final isNetworkImg = image.startsWith('http');
              final doctorId = doc['id'];

              return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(
                            doctorId: doctorId,
                            name: name,
                            specialty: specialty,
                            image: image,
                            initialDoctor: Map<String, dynamic>.from(doc),
                          ),
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
                                              const Color(0xFFEFF6FF),
                                              const Color(0xFFDBEAFE),
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
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.person,
                                                size: 45,
                                                color: Color(0xFF3B82F6),
                                              ),
                                        )
                                      : Image.asset(
                                          image,
                                          fit: BoxFit.cover,
                                          alignment: const Alignment(0, -0.15),
                                        ),
                                ),
                              ),
                              // Verified Tag
                              PositionedDirectional(
                                top: 6,
                                start: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'verified'.tr(),
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
                              // Favorite Icon
                              PositionedDirectional(
                                top: 6,
                                end: 6,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.white,
                                    size: 14,
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
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
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
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
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
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Book Now Button
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF3B82F6,
                                        ).withValues(alpha: 0.25),
                                        blurRadius: 4,
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
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'book_appointment'.tr(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white,
                                          fontSize: 11,
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
                  .fadeIn(delay: (500 + (index * 80)).ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
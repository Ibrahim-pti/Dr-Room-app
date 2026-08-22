import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/localization_extensions.dart';
import '../../pharmacy/models/pharmacy_model.dart';
import '../../pharmacy/screens/pharmacies_screen.dart';
import '../../pharmacy/screens/pharmacy_detail_screen.dart';
import '../data/home_mock_data.dart';

class TopPharmaciesSection extends StatelessWidget {
  final List<dynamic> topPharmacies;

  const TopPharmaciesSection({super.key, required this.topPharmacies});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final pharmaciesList = topPharmacies.isNotEmpty ? topPharmacies : HomeMockData.fallbackPharmacies;

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
                'top_pharmacies'.tr(),
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
                      builder: (context) => const PharmaciesScreen(),
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
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 12),

        // ── Pharmacies Horizontal List ──
        SizedBox(
          height: 204,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: pharmaciesList.length,
            itemBuilder: (context, index) {
              final pharm = pharmaciesList[index];
              final userObj = pharm['user'] is Map ? pharm['user'] : pharm;
              final pharmObj = pharm['pharmacy'] is Map ? pharm['pharmacy'] : null;

              final name = context.localizedField(userObj, 'name', fallback: 'cat_pharmacy'.tr());

              // Extract City with comprehensive fallbacks
              String city = '';
              if (pharmObj != null) {
                city = context.localizedField(pharmObj, 'city', fallback: '');
                if (city.isEmpty) city = context.localizedField(pharmObj, 'location', fallback: '');
                if (city.isEmpty) city = context.localizedField(pharmObj, 'address', fallback: '');
              }
              if (city.isEmpty) {
                city = context.localizedField(pharm, 'city', fallback: '');
              }
              if (city.isEmpty) {
                city = context.localizedField(pharm, 'address', fallback: '');
              }
              if (city.isEmpty) {
                city = context.localizedField(pharm, 'location', fallback: '');
              }
              if (city.isEmpty) {
                city = context.localizedField(userObj, 'city', fallback: '');
              }
              if (city.isEmpty) {
                final defaultCities = ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکوک'];
                city = defaultCities[index % defaultCities.length];
              }

              final time = context.localizedField(pharm, 'working_hours', fallback: pharm['time']?.toString() ?? 'open_24h'.tr());
              final rating = (pharm['rating'] != null) ? pharm['rating'].toString() : '4.9';
              final profileImage = pharm['profile_image'];

              final fallbackPharmacyImages = [
                'assets/images/pharmacy1.jpg',
                'assets/images/pharmacy2.jpg',
                'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=60',
                'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=500&auto=format&fit=crop&q=60',
                'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=60',
                'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=500&auto=format&fit=crop&q=60',
              ];
              final pharmImg = (profileImage != null && profileImage.toString().isNotEmpty)
                  ? (profileImage.toString().startsWith('assets/') || profileImage.toString().startsWith('http')
                      ? profileImage.toString()
                      : ApiClient.getImageUrl(profileImage.toString()))
                  : fallbackPharmacyImages[index % fallbackPharmacyImages.length];
              final isNetworkPharm = pharmImg.startsWith('http');

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyDetailScreen(
                        pharmacy: Pharmacy(
                          id: pharm['id'] ?? (index + 1),
                          name: name,
                          rating: double.tryParse(rating) ?? 4.9,
                          deliveryFee: double.tryParse(pharm['delivery_fee']?.toString() ?? '1500.0') ?? 1500.0,
                          profileImage: profileImage?.toString(),
                        ),
                      ),
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
                              child: isNetworkPharm
                                  ? CachedNetworkImage(
                                      imageUrl: pharmImg,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Image.asset(
                                        'assets/images/pharmacy1.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      pharmImg,
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
                                    ? const Color(0xFF064E3B).withValues(alpha: 0.9)
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
                                    Icons.local_pharmacy_rounded,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'cat_pharmacy'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
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
                                    children: const [
                                      Icon(
                                        Iconsax.verify,
                                        color: Color(0xFF10B981),
                                        size: 10,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'باوەڕپێکراو',
                                        style: TextStyle(
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

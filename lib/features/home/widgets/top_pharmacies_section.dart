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
          height: 198,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: pharmaciesList.length,
            itemBuilder: (context, index) {
              final pharm = pharmaciesList[index];
              final userObj = pharm['user'] is Map ? pharm['user'] : pharm;
              final name = context.localizedField(userObj, 'name', fallback: 'cat_pharmacy'.tr());
              final city = context.localizedField(pharm, 'city', fallback: context.localizedField(pharm, 'address', fallback: ''));
              final time = context.localizedField(pharm, 'working_hours', fallback: 'open_24h'.tr());
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
                          id: pharm['id'] ?? 1,
                          name: pharm['name'] ?? 'دەرمانخانە',
                          rating: double.tryParse(pharm['rating']?.toString() ?? '4.8') ?? 4.8,
                          deliveryFee: double.tryParse(pharm['delivery_fee']?.toString() ?? '1500.0') ?? 1500.0,
                          profileImage: pharm['profile_image'],
                        ),
                      ),
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
                                    '4.9',
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
                                    city,
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
                                  time,
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
              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../categories/all_categories_screen.dart';
import '../../doctors/all_doctors_screen.dart';
import '../../emergency/sos_screen.dart';
import '../../lab/all_labs_screen.dart';
import '../../nursing/nurse_list_screen.dart';
import '../../pharmacy/screens/pharmacies_screen.dart';

class ServicesCategoryGrid extends StatelessWidget {
  const ServicesCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
                'categories'.tr(),
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
                      builder: (context) => const AllCategoriesScreen(),
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
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 14),

        // ── Categories Horizontal Scroll ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/lab.png',
                  titleKey: 'cat_lab',
                  id: 'lab',
                  isActive: true,
                  accentColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/doctor_bag.png',
                  titleKey: 'cat_nursing',
                  id: 'nursing',
                  isActive: true,
                  accentColor: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/doctor.png',
                  titleKey: 'cat_doctor',
                  id: 'doctor',
                  isActive: false,
                  accentColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/medicine.png',
                  titleKey: 'cat_pharmacy',
                  id: 'pharmacy',
                  isActive: true,
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  icon: Iconsax.hospital,
                  titleKey: 'cat_ambulance',
                  id: 'ambulance',
                  isActive: false,
                  accentColor: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/xray.png',
                  titleKey: 'cat_xray',
                  id: 'xray',
                  isActive: false,
                  accentColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                child: _buildGridCard(
                  context,
                  imagePath: 'assets/images/apps.png',
                  titleKey: 'cat_more',
                  id: 'more',
                  isActive: true,
                  accentColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    String? imagePath,
    IconData? icon,
    required String titleKey,
    required String id,
    required bool isActive,
    Color accentColor = const Color(0xFF3B82F6),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          _showComingSoonModal(context, titleKey, id, accentColor, imagePath, icon);
        } else {
          _navigateService(context, id);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            accentColor.withValues(alpha: 0.18),
                            const Color(0xFF1E293B),
                          ]
                        : [accentColor.withValues(alpha: 0.12), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.55,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: imagePath != null
                          ? Image.asset(imagePath, fit: BoxFit.contain)
                          : Center(
                              child: Icon(icon, color: accentColor, size: 28),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isActive)
            PositionedDirectional(
              top: -4,
              end: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'coming_soon'.tr(),
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
    );
  }

  void _navigateService(BuildContext context, String id) {
    if (id == 'lab') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AllLabsScreen()));
    } else if (id == 'nursing') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const NurseListScreen()));
    } else if (id == 'doctor') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AllDoctorsScreen()));
    } else if (id == 'pharmacy') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PharmaciesScreen()));
    } else if (id == 'ambulance') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SosScreen()));
    } else if (id == 'more') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AllCategoriesScreen()));
    }
  }

  void _showComingSoonModal(BuildContext context, String titleKey, String id, Color accentColor, String? imagePath, IconData? icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: imagePath != null
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : Icon(icon, color: accentColor, size: 38),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titleKey.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'desc_$id'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13.5,
                  color: AppColors.getTextTitle(context),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'coming_soon_msg'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ok'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
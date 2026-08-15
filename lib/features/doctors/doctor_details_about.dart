import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import 'doctor_details_widgets.dart';

/// About section: bio + stats row (rating, experience, phone).
class DoctorDetailsAbout extends StatelessWidget {
  final bool isDark;
  final String bio;
  final bool bioExpanded;
  final VoidCallback onToggleBio;
  final double rating;
  final int reviews;
  final int experienceYears;
  final String phone;
  final VoidCallback onCallDoctor;
  final VoidCallback onOpenReviews;

  const DoctorDetailsAbout({
    super.key,
    required this.isDark,
    required this.bio,
    required this.bioExpanded,
    required this.onToggleBio,
    required this.rating,
    required this.reviews,
    required this.experienceYears,
    required this.phone,
    required this.onCallDoctor,
    required this.onOpenReviews,
  });

  @override
  Widget build(BuildContext context) {
    final hasBio = bio.isNotEmpty;
    final isLong = bio.length > 160;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorDetailsSectionHeader(
          icon: Iconsax.profile_circle,
          title: 'about_doctor'.tr(),
        ),
        const SizedBox(height: 10),
        DoctorDetailsCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasBio ? bio : 'dd_no_bio'.tr(),
                maxLines: isLong && !bioExpanded ? 3 : null,
                overflow: isLong && !bioExpanded
                    ? TextOverflow.ellipsis
                    : null,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.75,
                  color: hasBio
                      ? AppColors.getTextSubtitle(context)
                      : AppColors.textLight,
                ),
              ),
              if (isLong) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: onToggleBio,
                  child: Text(
                    bioExpanded ? 'dd_read_less'.tr() : 'read_more'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              // Rating / experience / price share this card — they describe the
              // same doctor, so a second card between them was just a seam.
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.getDivider(context)),
              const SizedBox(height: 12),
              _buildStatsRow(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            value: rating > 0 ? rating.toStringAsFixed(1) : '4.9',
            label: '$reviews هەڵسەنگاندن',
            onTap: onOpenReviews,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            icon: Iconsax.medal_star,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            value: experienceYears > 0 ? '$experienceYears+ ساڵ' : '10+ ساڵ',
            label: 'ئەزموونی پزیشکی',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            icon: Iconsax.call,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            value: phone.isNotEmpty ? phone : 'پەیوەندی',
            label: 'پەیوەندی بگرە',
            onTap: phone.isNotEmpty ? onCallDoctor : null,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}

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
    final stats = <Widget>[
      _stat(
        context,
        icon: Icons.star_rounded,
        color: const Color(0xFFF59E0B),
        value: rating > 0 ? rating.toStringAsFixed(1) : '—',
        label: '$reviews ${'dd_reviews'.tr()}',
        onTap: onOpenReviews,
      ),
      _stat(
        context,
        icon: Iconsax.medal_star,
        color: AppColors.primary,
        value: experienceYears > 0 ? '$experienceYears' : '—',
        label: 'dd_years_exp'.tr(),
      ),
      _stat(
        context,
        icon: Iconsax.call,
        color: AppColors.success,
        value: phone.isNotEmpty ? phone : '—',
        valueSize: 12.5,
        label: 'call'.tr(),
        onTap: phone.isNotEmpty ? onCallDoctor : null,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 34,
              color: AppColors.getDivider(context),
            ),
          Expanded(child: stats[i]),
        ],
      ],
    );
  }

  Widget _stat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    double valueSize = 15,
    VoidCallback? onTap,
  }) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.poppins(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextTitle(context),
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: onTap != null
                      ? AppColors.primary
                      : AppColors.getTextSubtitle(context),
                  fontWeight: onTap != null ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppColors.primary,
              ),
          ],
        ),
      ],
    );

    if (onTap == null) return column;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: column,
      ),
    );
  }
}

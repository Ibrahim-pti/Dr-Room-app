import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/models/appointment_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'booking_slot_screen.dart';

/// Doctor profile.
///
/// The backend has no `GET /doctors/{id}` and no reviews endpoint, so the
/// [Doctor] is passed in from the list rather than re-fetched, and the rating
/// is shown as a summary only. Add a reviews section once the endpoint exists.
class DoctorProfileScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor', style: AppTypography.headingSm),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  if (doctor.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('About',
                        style: AppTypography.labelLg
                            .copyWith(color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text(
                      doctor.bio,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.textMedium),
                    ),
                  ],
                  if (doctor.availableDays.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Available days',
                        style: AppTypography.labelLg
                            .copyWith(color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final day in doctor.availableDays)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLightSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              day,
                              style: AppTypography.labelSm
                                  .copyWith(color: AppColors.textDark),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingSlotScreen(doctor: doctor),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book — ${doctor.formattedFee}',
                        style:
                            AppTypography.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          DoctorAvatar(imageUrl: doctor.imageUrl, size: 108),
          const SizedBox(height: 14),
          Text(
            doctor.name,
            style: AppTypography.headingSm.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            doctor.specialty,
            style: AppTypography.bodyMd
                .copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          if (doctor.totalReviews > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.star, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${doctor.rating} • ${doctor.totalReviews} reviews',
                    style: AppTypography.bodySm.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    final tiles = <Widget>[
      if (doctor.totalReviews > 0)
        _StatTile(
          icon: Iconsax.star,
          value: '${doctor.rating}',
          label: 'Rating',
          color: AppColors.warning,
        ),
      if (doctor.experienceYears > 0)
        _StatTile(
          icon: Iconsax.briefcase,
          value: '${doctor.experienceYears}',
          label: 'Years',
          color: AppColors.success,
        ),
      _StatTile(
        icon: Iconsax.moneys,
        value: doctor.formattedFee,
        label: 'Fee',
        color: AppColors.primary,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: AppTypography.labelMd.copyWith(color: color),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tinder_swipe_card.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../appointments/all_schedules_screen.dart';

class UpcomingAppointmentCard extends StatelessWidget {
  const UpcomingAppointmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appointmentProvider = context.watch<AppointmentProvider>();
    final upcoming = appointmentProvider.appointments
        .where((a) => a.isUpcoming && a.status != AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (upcoming.isEmpty) return const SizedBox.shrink();
    final next = upcoming.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.trash, color: Colors.redAccent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'appointment_cancelled'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TinderSwipeCard(
            onSwiped: () async {
              final success = await appointmentProvider.cancelAppointment(next.id);
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'appointment_cancelled'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Failed to cancel appointment on server.',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              return success;
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllSchedulesScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header: Title & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'upcoming_appointments'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: AppColors.getTextTitle(context),
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: next.status.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            next.status.kurdiName,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: next.status.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Doctor Info
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            image: next.doctorImageUrl != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(next.doctorImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: next.doctorImageUrl == null
                              ? const Icon(Iconsax.user, color: Color(0xFF3B82F6))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                next.doctorName.isNotEmpty ? next.doctorName : 'Doctor',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                next.doctorSpecialty.isNotEmpty ? next.doctorSpecialty : 'پزیشکی گشتی',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  color: AppColors.getTextSubtitle(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),

                    // Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Iconsax.calendar_1, color: Color(0xFF64748B), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                next.formattedDate,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Iconsax.clock, color: Color(0xFF64748B), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                next.formattedTime,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }
}

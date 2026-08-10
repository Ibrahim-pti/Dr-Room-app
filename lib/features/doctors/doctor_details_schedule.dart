import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import 'doctor_details_models.dart';
import 'doctor_details_widgets.dart';

/// Day picker + time slot grid.
class DoctorDetailsSchedule extends StatelessWidget {
  final bool isDark;
  final bool slotsLoading;
  final List<BookableDay> days;
  final int dayIndex;
  final int timeIndex;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<int> onTimeSelected;
  final String Function(DateTime date) dayLabel;
  final String Function(DateTime date) monthName;
  final String Function(DateTime time) clock;
  final GlobalKey scheduleKey;

  const DoctorDetailsSchedule({
    super.key,
    required this.isDark,
    required this.slotsLoading,
    required this.days,
    required this.dayIndex,
    required this.timeIndex,
    required this.onDaySelected,
    required this.onTimeSelected,
    required this.dayLabel,
    required this.monthName,
    required this.clock,
    required this.scheduleKey,
  });

  List<Slot> get _slots => days.isEmpty || dayIndex >= days.length
      ? const []
      : days[dayIndex].slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: scheduleKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorDetailsSectionHeader(
          icon: Iconsax.calendar_1,
          title: 'dd_schedule'.tr(),
        ),
        const SizedBox(height: 12),
        if (slotsLoading)
          const SizedBox(
            height: 84,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else if (days.isEmpty)
          DoctorDetailsEmptyBox(message: 'dd_no_days'.tr())
        else ...[
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = dayIndex == index;

                return GestureDetector(
                  onTap: () => onDaySelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 68,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getBorder(context),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayLabel(day.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.getTextSubtitle(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd').format(day.date),
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.getTextTitle(context),
                          ),
                        ),
                        Text(
                          monthName(day.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          if (_slots.isEmpty)
            DoctorDetailsEmptyBox(message: 'dd_no_times'.tr())
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_slots.length, (index) {
                final slot = _slots[index];
                final isSelected = timeIndex == index;
                final isTaken = slot.taken;

                return GestureDetector(
                  onTap: isTaken
                      ? null
                      : () => onTimeSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.getSurfaceSecondary(context)
                          : isSelected
                          ? AppColors.primary
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected && !isTaken
                            ? AppColors.primary
                            : AppColors.getBorder(context),
                      ),
                    ),
                    child: Text(
                      clock(slot.dateTime),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected && !isTaken
                            ? FontWeight.bold
                            : FontWeight.w500,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textLight,
                        color: isTaken
                            ? AppColors.textLight
                            : isSelected
                            ? Colors.white
                            : AppColors.getTextTitle(context),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ],
    );
  }
}

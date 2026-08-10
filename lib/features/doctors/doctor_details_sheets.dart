import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import '../../main.dart';

/// Booking summary bottom sheet shown before confirming an appointment.
void showBookingSummarySheet({
  required BuildContext context,
  required String doctorName,
  required Map<String, dynamic>? service,
  required DateTime slot,
  required double price,
  required double saving,
  required bool isBooking,
  required String Function(Map service) serviceName,
  required String Function(double price) money,
  required String Function(DateTime date) fullDate,
  required String Function(DateTime time) clock,
  required double Function(dynamic v) asDouble,
  required Future<void> Function(StateSetter refreshSheet) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getDivider(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'dd_summary'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextTitle(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _summaryRow(context, Iconsax.user, 'dd_doctor'.tr(), doctorName),
                  if (service != null)
                    _summaryRow(
                      context,
                      Iconsax.health,
                      'dd_service'.tr(),
                      serviceName(service),
                    ),
                  _summaryRow(
                    context,
                    Iconsax.calendar_1,
                    'dd_date'.tr(),
                    fullDate(slot),
                  ),
                  _summaryRow(context, Iconsax.clock, 'dd_time'.tr(), clock(slot)),
                  const SizedBox(height: 6),
                  Divider(color: AppColors.getDivider(context)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'total_price'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSubtitle(context),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (saving > 0) ...[
                            Text(
                              money(asDouble(service?['old_price'])),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            money(price),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (saving > 0) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        'dd_you_save'.tr(args: [money(saving)]),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isBooking
                          ? null
                          : () => onConfirm(setSheetState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isBooking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'dd_confirm'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _summaryRow(BuildContext context, IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextTitle(context),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Login prompt dialog shown when unauthenticated user tries to book.
void showDoctorLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'dd_login_title'.tr(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: AppColors.getTextTitle(context),
        ),
      ),
      content: Text(
        'dd_login_desc'.tr(),
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          height: 1.7,
          color: AppColors.getTextSubtitle(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'dd_later'.tr(),
            style: GoogleFonts.poppins(
              color: AppColors.getTextSubtitle(context),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const AppFlow(startAtLogin: true),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'dd_login'.tr(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

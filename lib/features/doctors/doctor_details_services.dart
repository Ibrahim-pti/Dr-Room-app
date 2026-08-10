import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import 'doctor_details_widgets.dart';

/// Services list with discount badges and radio selection.
class DoctorDetailsServices extends StatelessWidget {
  final bool isDark;
  final List<dynamic> services;
  final int? selectedServiceId;
  final ValueChanged<int?> onServiceSelected;
  final String Function(Map service) serviceName;
  final String Function(double price) money;

  const DoctorDetailsServices({
    super.key,
    required this.isDark,
    required this.services,
    required this.selectedServiceId,
    required this.onServiceSelected,
    required this.serviceName,
    required this.money,
  });

  static int? asInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  static double asDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorDetailsSectionHeader(
          icon: Iconsax.health,
          title: 'dd_services'.tr(),
          subtitle: services.isEmpty ? null : 'dd_choose_service'.tr(),
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          DoctorDetailsEmptyBox(message: 'dd_no_services'.tr())
        else
          ...List.generate(services.length, (index) {
            final service = services[index] as Map;
            final id = asInt(service['id']);
            final isSelected = id != null && id == selectedServiceId;

            final hasDiscount = service['has_discount'] == true;
            final percent = asInt(service['discount_percent']);
            final oldPrice = asDouble(service['old_price']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DoctorDetailsSelectableTile(
                isDark: isDark,
                isSelected: isSelected,
                onTap: () => onServiceSelected(id),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.getSurfaceSecondary(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Iconsax.activity,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getTextSubtitle(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  serviceName(service),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextTitle(context),
                                  ),
                                ),
                              ),
                              if (hasDiscount && percent != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    '−$percent٪',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                money(asDouble(service['price'])),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (hasDiscount && oldPrice > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  money(oldPrice),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: AppColors.textLight,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    DoctorDetailsRadio(isSelected: isSelected),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

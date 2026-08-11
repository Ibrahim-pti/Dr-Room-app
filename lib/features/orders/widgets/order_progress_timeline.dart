import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/providers/order_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Shows where an order has got to, as steps rather than a single word.
///
/// A patient waiting on a nurse wants to know how far along the request is,
/// not just its current label — "pending" alone does not say whether anything
/// has happened yet. Cancelled orders get their own two-step display, since
/// they never travel the normal path.
class OrderProgressTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderProgressTimeline({super.key, required this.status});

  /// The happy path, in order.
  static const List<OrderStatus> _path = [
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.completed,
  ];

  static const Map<OrderStatus, String> _labels = {
    OrderStatus.pending: 'status_placed',
    OrderStatus.processing: 'status_processing',
    OrderStatus.completed: 'status_completed',
    OrderStatus.cancelled: 'status_cancelled',
  };

  static const Map<OrderStatus, IconData> _icons = {
    OrderStatus.pending: Iconsax.receipt_item,
    OrderStatus.processing: Iconsax.truck_fast,
    OrderStatus.completed: Iconsax.tick_circle,
    OrderStatus.cancelled: Iconsax.close_circle,
  };

  @override
  Widget build(BuildContext context) {
    final steps = status == OrderStatus.cancelled
        ? [OrderStatus.pending, OrderStatus.cancelled]
        : _path;

    // Everything up to and including the current status is done; a cancelled
    // order is shown as fully travelled, because it has stopped moving.
    final reachedIndex = status == OrderStatus.cancelled
        ? steps.length - 1
        : _path.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'order_progress'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < steps.length; i++)
          _buildStep(
            context,
            step: steps[i],
            isReached: i <= reachedIndex,
            isCurrent: i == reachedIndex,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required OrderStatus step,
    required bool isReached,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isReached ? step.color : AppColors.getBorder(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isReached
                      ? step.color.withValues(alpha: 0.12)
                      : AppColors.getSurfaceSecondary(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 2 : 1),
                ),
                child: Icon(_icons[step], color: color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isReached
                        ? step.color.withValues(alpha: 0.4)
                        : AppColors.getBorder(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 20),
              child: Text(
                _labels[step]!.tr(),
                style: GoogleFonts.poppins(
                  color: isReached
                      ? AppColors.getTextTitle(context)
                      : AppColors.getTextSubtitle(context),
                  fontSize: 15,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

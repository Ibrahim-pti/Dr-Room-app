import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/providers/order_provider.dart';

import 'package:easy_localization/easy_localization.dart';

class OrderProgressTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderProgressTimeline({super.key, required this.status});

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static const List<OrderStatus> _path = [
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.completed,
  ];

  String _getStepLabel(OrderStatus s, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (s) {
      case OrderStatus.pending:
        if (lang == 'kmr') return 'داخوازی هاتە تۆمارکرن';
        if (lang == 'ar') return 'تم تسجيل الطلب';
        if (lang == 'en') return 'Order Placed';
        return 'داواکاری تۆمارکرا';
      case OrderStatus.processing:
        if (lang == 'kmr') return 'د قۆناغا بجهئینانێ دایە';
        if (lang == 'ar') return 'قيد التنفيذ والمتابعة';
        if (lang == 'en') return 'In Progress';
        return 'لە جێبەجێکردندایە';
      case OrderStatus.completed:
        if (lang == 'kmr') return 'تەواوکرایە';
        if (lang == 'ar') return 'مكتمل';
        if (lang == 'en') return 'Completed';
        return 'تەواوکرا';
      case OrderStatus.cancelled:
        if (lang == 'kmr') return 'هاتیە هەلوەشاندن';
        if (lang == 'ar') return 'ملغي';
        if (lang == 'en') return 'Cancelled';
        return 'هەڵوەشێنراوە';
    }
  }

  String _getStepSubtitle(OrderStatus s, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (s) {
      case OrderStatus.pending:
        if (lang == 'kmr') return 'داخوازییا تە گەهشت و چاڤەڕێی پشتڕاستکرنێیە';
        if (lang == 'ar') return 'تم استلام طلبك وبانتظار التأكيد';
        if (lang == 'en') return 'Order received and awaiting confirmation';
        return 'داواکارییەکەت گەیشت و چاوەڕوانی پشتڕاستکردنەوەیە';
      case OrderStatus.processing:
        if (lang == 'kmr') return 'تیمێ مە د پەیوەندی و بجهئینانا داخوازیێ دانە';
        if (lang == 'ar') return 'فريقنا الطبي يتابع وينفذ الطلب حالياً';
        if (lang == 'en') return 'Our medical team is executing and following up';
        return 'تیمەکەمان لە پەیوەندی و جێبەجێکردنی داواکارییەکەدان';
      case OrderStatus.completed:
        if (lang == 'kmr') return 'پشکنین و ئەنجام ب سەرکەفتیانە هاتنە ئەنجامدان';
        if (lang == 'ar') return 'تم الانتهاء من كافة الخدمات بنجاح';
        if (lang == 'en') return 'All examinations and services completed successfully';
        return 'پشکنین و ئەنجامەکان بە تەواوی ئەنجام دران';
      case OrderStatus.cancelled:
        if (lang == 'kmr') return 'داخوازی ب سەرکەفتیانە هاتیە هەلوەشاندن';
        if (lang == 'ar') return 'تم إلغاء الطلب بنجاح';
        if (lang == 'en') return 'Order has been cancelled successfully';
        return 'داواکارییەکە بە سەرکەوتوویی هەڵوەشێنراوەتەوە';
    }
  }

  static const Map<OrderStatus, IconData> _icons = {
    OrderStatus.pending: Iconsax.receipt_item,
    OrderStatus.processing: Iconsax.truck_fast,
    OrderStatus.completed: Iconsax.tick_circle,
    OrderStatus.cancelled: Iconsax.close_circle,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final steps = status == OrderStatus.cancelled
        ? [OrderStatus.pending, OrderStatus.cancelled]
        : _path;

    final reachedIndex = status == OrderStatus.cancelled
        ? steps.length - 1
        : _path.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.activity, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'order_progress'.tr(),
                style: _kStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < steps.length; i++)
            _buildStep(
              context,
              step: steps[i],
              isReached: i <= reachedIndex,
              isCurrent: i == reachedIndex,
              isLast: i == steps.length - 1,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required OrderStatus step,
    required bool isReached,
    required bool isCurrent,
    required bool isLast,
    required bool isDark,
  }) {
    final stepColor = isReached
        ? (step == OrderStatus.completed ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
        : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isReached
                      ? stepColor.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stepColor,
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: stepColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(_icons[step], color: stepColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isReached
                        ? stepColor.withValues(alpha: 0.4)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStepLabel(step, context),
                    style: _kStyle(
                      color: isReached
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : const Color(0xFF94A3B8),
                      fontSize: 14.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStepSubtitle(step, context),
                    style: _kStyle(
                      color: isReached
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/providers/order_provider.dart';

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

  static const Map<OrderStatus, String> _labels = {
    OrderStatus.pending: 'داواکاری تۆمارکرا',
    OrderStatus.processing: 'لە جێبەجێکردندایە',
    OrderStatus.completed: 'تەواوکرا',
    OrderStatus.cancelled: 'هەڵوەشێنراوە',
  };

  static const Map<OrderStatus, String> _subtitles = {
    OrderStatus.pending: 'داواکارییەکەت گەیشت و چاوەڕوانی پشتڕاستکردنەوەیە',
    OrderStatus.processing: 'تیمەکەمان لە پەیوەندی و جێبەجێکردنی داواکارییەکەدان',
    OrderStatus.completed: 'پشکنین و ئەنجامەکان بە تەواوی ئەنجام دران',
    OrderStatus.cancelled: 'داواکارییەکە بە سەرکەوتوویی هەڵوەشێنراوەتەوە',
  };

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
                'پێشکەوتنی داواکاری',
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
                    _labels[step]!,
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
                    _subtitles[step]!,
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
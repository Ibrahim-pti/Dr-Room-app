import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../home/main_shell.dart';
import '../orders/order_details_screen.dart';
import '../../core/providers/order_provider.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Success Animated Icon ──
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ).animate().scale(
                                  delay: 200.ms,
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 24),

                        // ── Success Title ──
                        Text(
                          'داواکارییەکەت بە سەرکەوتوویی نێردرا!',
                          textAlign: TextAlign.center,
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 10),

                        // ── Order Code Chip ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.receipt_1, color: Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'کۆدی داواکاری: #$orderId',
                                style: _kStyle(
                                  color: const Color(0xFF2563EB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).scale(),

                        const SizedBox(height: 20),

                        // ── Status Info Card ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Iconsax.clock, color: Color(0xFF10B981), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'لە چاوەڕوانی پشتڕاستکردنەوەدایە',
                                      style: _kStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'داواکارییەکەت گەیشت و لەلایەن تاقیگەوە کاری لەسەر دەکرێت. بەم زووانە تیمەکەمان بۆ ڕێکخستنی کات و سەردان پەیوەندیت پێوە دەکات.',
                                style: _kStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12.5,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom Action Buttons ──
              Column(
                children: [
                  // Track Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final orderProvider = context.read<OrderProvider>();
                        final orderList = orderProvider.orders.where((o) => o.id == orderId).toList();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainShell(),
                          ),
                          (route) => false,
                        );

                        if (orderList.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(order: orderList.first),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.radar_2, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'شوێنپێهەڵگرتنی داواکاری',
                            style: _kStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 10),

                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainShell(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'گەڕانەوە بۆ پەڕەی سەرەکی',
                        style: _kStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

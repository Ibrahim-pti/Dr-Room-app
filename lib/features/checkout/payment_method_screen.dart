import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/checkout_provider.dart';
import 'checkout_summary_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

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
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'شێوازی پارەدان',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkoutProvider, child) {
          final selectedMethod = checkoutProvider.selectedPaymentMethod;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.card_tick,
                              color: Color(0xFF3B82F6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'شێوازە باوەڕپێکراوەکانی پارەدان',
                              style: _kStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.1),
                      const SizedBox(height: 10),

                      Text(
                        'شێوازی پارەدان دیاری بکە',
                        style: _kStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 50.ms),
                      const SizedBox(height: 4),
                      Text(
                        'تکایە یەکێک لەم شێوازانە هەڵبژێرە بۆ تەواوکردنی داواکارییەکەت',
                        style: _kStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),

                      // ── Option 1: Cash on Delivery ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'کاش لەکاتی وەرگرتندا',
                        subtitle: 'پارەدان بە کاش لە کاتی ئەنجامدانی پشکنین',
                        badgeText: 'پارەدانی دەستی',
                        badgeColor: const Color(0xFF10B981),
                        icon: Iconsax.wallet_2,
                        iconBgGradient: const [
                          Color(0xFF10B981),
                          Color(0xFF059669),
                        ],
                        isSelected:
                            selectedMethod == 'Cash on Delivery' ||
                            selectedMethod == 'کاش لەکاتی وەرگرتندا',
                        onTap: () => checkoutProvider.selectPaymentMethod(
                          'Cash on Delivery',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 2: FIB ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'فایب بانک (FIB)',
                        subtitle:
                            'پارەدانی ڕاستەوخۆ بە هەژماری First Iraqi Bank',
                        badgeText: 'خێرا و ئۆنلاین',
                        badgeColor: const Color(0xFF2563EB),
                        icon: Iconsax.bank,
                        iconBgGradient: const [
                          Color(0xFF3B82F6),
                          Color(0xFF1D4ED8),
                        ],
                        isSelected:
                            selectedMethod == 'FIB (First Iraqi Bank)' ||
                            selectedMethod == 'FIB',
                        onTap: () => checkoutProvider.selectPaymentMethod(
                          'FIB (First Iraqi Bank)',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 3: FastPay ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'فاستپەی (FastPay)',
                        subtitle: 'پارەدانی پارێزراو لە ڕێگەی جزدانی فاستپەی',
                        badgeText: 'ئەلیكترۆنی',
                        badgeColor: const Color(0xFFEC4899),
                        icon: Iconsax.scan_barcode,
                        iconBgGradient: const [
                          Color(0xFFEC4899),
                          Color(0xFFDB2777),
                        ],
                        isSelected: selectedMethod == 'FastPay',
                        onTap: () =>
                            checkoutProvider.selectPaymentMethod('FastPay'),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 4: ZainCash ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'زەین کاش (ZainCash)',
                        subtitle:
                            'پارەدان لە ڕێگەی ژمارە مۆبایل و ئەپی ZainCash',
                        badgeText: 'ئەلیكترۆنی',
                        badgeColor: const Color(0xFF8B5CF6),
                        icon: Iconsax.mobile,
                        iconBgGradient: const [
                          Color(0xFF8B5CF6),
                          Color(0xFF7C3AED),
                        ],
                        isSelected: selectedMethod == 'ZainCash',
                        onTap: () =>
                            checkoutProvider.selectPaymentMethod('ZainCash'),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 5: Credit Card (Stripe) ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'ماستەرکارت و ڤیزا (Mastercard / Visa)',
                        subtitle: 'پارەدانی نێودەوڵەتی بە کارتی بانکی',
                        badgeText: 'کارت',
                        badgeColor: const Color(0xFFF59E0B),
                        icon: Iconsax.card,
                        iconBgGradient: const [
                          Color(0xFFF59E0B),
                          Color(0xFFD97706),
                        ],
                        isSelected: selectedMethod == 'Credit Card (Stripe)',
                        onTap: () => checkoutProvider.selectPaymentMethod(
                          'Credit Card (Stripe)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Next / Continue Button ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutSummaryScreen(),
                          ),
                        );
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
                          Text(
                            'بەردەوامبوون',
                            style: _kStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required List<Color> iconBgGradient,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with Gradient
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: iconBgGradient,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: iconBgGradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: _kStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: _kStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: _kStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Radio Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFCBD5E1),
                  width: isSelected ? 2 : 1.5,
                ),
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04);
  }
}

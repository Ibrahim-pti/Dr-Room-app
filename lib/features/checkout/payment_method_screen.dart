import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
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
          'payment_method'.tr(),
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
                              'trusted_payment_methods'.tr(),
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
                        'select_payment_method'.tr(),
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
                        'select_payment_method_desc'.tr(),
                        style: _kStyle(
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                          fontSize: 13,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),

                      // ── Option 1: Cash ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'payment_cash'.tr(),
                        imageAsset: 'assets/images/cash_logo.png',
                        fallbackIcon: Iconsax.wallet_2,
                        isSelected:
                            selectedMethod == 'Cash on Delivery' ||
                            selectedMethod == 'کاش لەکاتی وەرگرتندا' ||
                            selectedMethod == 'کاش' ||
                            selectedMethod.toLowerCase().contains('cash'),
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
                        title: 'payment_fib'.tr(),
                        imageAsset: 'assets/images/fib_logo.png',
                        fallbackIcon: Iconsax.bank,
                        isSelected:
                            selectedMethod == 'FIB (First Iraqi Bank)' ||
                            selectedMethod == 'FIB',
                        onTap: () => checkoutProvider.selectPaymentMethod(
                          'FIB',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 3: FastPay ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'payment_fastpay'.tr(),
                        imageAsset: 'assets/images/fastpay_icon.png',
                        fallbackIcon: Iconsax.scan_barcode,
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
                        title: 'payment_zaincash'.tr(),
                        imageAsset: 'assets/images/zaincash_icon.png',
                        fallbackIcon: Iconsax.mobile,
                        isSelected: selectedMethod == 'ZainCash',
                        onTap: () =>
                            checkoutProvider.selectPaymentMethod('ZainCash'),
                      ),
                      const SizedBox(height: 12),

                      // ── Option 5: Qi Card ──
                      _buildPaymentOption(
                        context: context,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        title: 'payment_qicard'.tr(),
                        imageAsset: 'assets/images/qicard_logo.png',
                        fallbackIcon: Iconsax.card,
                        isSelected:
                            selectedMethod == 'Qi Card' ||
                            selectedMethod == 'Qi Card (کی کارد)' ||
                            selectedMethod == 'Credit Card (Stripe)',
                        onTap: () => checkoutProvider.selectPaymentMethod(
                          'Qi Card',
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Center(
                        child: Text(
                          'continue_btn'.tr(),
                          textAlign: TextAlign.center,
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
    required String imageAsset,
    required IconData fallbackIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF))
              : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : borderColor,
            width: isSelected ? 1.8 : 1,
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
            // Official Icon / Logo Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  imageAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    child: Icon(
                      fallbackIcon,
                      color: const Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Short Main Title
            Expanded(
              child: Text(
                title,
                style: _kStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
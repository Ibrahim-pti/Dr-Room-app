import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/checkout_provider.dart';
import 'checkout_summary_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkoutProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 24),
                      
                      _buildPaymentOption(
                        context: context,
                        title: 'Cash on Delivery',
                        icon: Iconsax.wallet_2,
                        isSelected: checkoutProvider.selectedPaymentMethod == 'Cash on Delivery',
                        onTap: () => checkoutProvider.selectPaymentMethod('Cash on Delivery'),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(
                        context: context,
                        title: 'Credit Card (Stripe)',
                        icon: Iconsax.card,
                        isSelected: checkoutProvider.selectedPaymentMethod == 'Credit Card (Stripe)',
                        onTap: () => checkoutProvider.selectPaymentMethod('Credit Card (Stripe)'),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(
                        context: context,
                        title: 'ZainCash',
                        icon: Iconsax.mobile,
                        isSelected: checkoutProvider.selectedPaymentMethod == 'ZainCash',
                        onTap: () => checkoutProvider.selectPaymentMethod('ZainCash'),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(
                        context: context,
                        title: 'FIB (First Iraqi Bank)',
                        icon: Iconsax.bank,
                        isSelected: checkoutProvider.selectedPaymentMethod == 'FIB (First Iraqi Bank)',
                        onTap: () => checkoutProvider.selectPaymentMethod('FIB (First Iraqi Bank)'),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(
                        context: context,
                        title: 'FastPay',
                        icon: Iconsax.scan_barcode,
                        isSelected: checkoutProvider.selectedPaymentMethod == 'FastPay',
                        onTap: () => checkoutProvider.selectPaymentMethod('FastPay'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Next Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  border: Border.all(color: AppColors.getBorder(context)),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(32),
                    topEnd: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
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
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getSurface(context),
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
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : AppColors.getSurfaceSecondary(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF3B82F6) : AppColors.getTextSubtitle(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: AppColors.getSurface(context))
                  : null,
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }
}

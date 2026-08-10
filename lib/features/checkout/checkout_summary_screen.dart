import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/providers/cart_provider.dart';
import 'dart:ui';

class CheckoutSummaryScreen extends StatefulWidget {
  const CheckoutSummaryScreen({super.key});

  @override
  State<CheckoutSummaryScreen> createState() => _CheckoutSummaryScreenState();
}

class _CheckoutSummaryScreenState extends State<CheckoutSummaryScreen> {
  int _selectedPaymentMethod = 0; // 0 for Cash, 1 for Card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Sleek off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Summary & Payment',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient shapes
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.08),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).move(
                duration: 6.seconds, curve: Curves.easeInOutSine, begin: const Offset(0, -20), end: const Offset(0, 20)),
          ),
          
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.receipt_2, color: Color(0xFF3B82F6), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Order Summary',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 20),

                      // ── Summary Card ──
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final itemsString = cartProvider.items.map((e) => e.name).join(', ');
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF94A3B8).withOpacity(0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Stack(
                                children: [
                                  // Top glow effect
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 4,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        _buildSummaryRow(Iconsax.health, 'Selected Service', cartProvider.serviceType ?? 'Unknown', false)
                                            .animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
                                        if (itemsString.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          _buildSummaryRow(Iconsax.box, 'Items Included', itemsString, false)
                                              .animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                                        ],
                                        if (cartProvider.patientDetails?['location'] != null) ...[
                                          const SizedBox(height: 16),
                                          _buildSummaryRow(Iconsax.location, 'Service Location', cartProvider.patientDetails!['location'], false)
                                              .animate().fadeIn(delay: 175.ms).slideX(begin: 0.05),
                                        ],
                                        const SizedBox(height: 16),
                                        _buildSummaryRow(Iconsax.wallet_3, 'Subtotal', '\$${cartProvider.subtotal.toStringAsFixed(2)}', false)
                                            .animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                                        if (cartProvider.extraFee > 0) ...[
                                          const SizedBox(height: 16),
                                          _buildSummaryRow(Iconsax.coin_1, 'Extra Fees', '\$${cartProvider.extraFee.toStringAsFixed(2)}', false)
                                              .animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                                        ],
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20),
                                          child: _DashedDivider(),
                                        ),
                                        _buildSummaryRow(Iconsax.ticket_discount, 'Total', '\$${cartProvider.total.toStringAsFixed(2)}', true)
                                            .animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

                      const SizedBox(height: 40),

                      // ── Payment Methods ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.card, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Payment Method',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 20),
                      
                      Consumer<CheckoutProvider>(
                        builder: (context, checkoutProvider, child) {
                          return _buildPaymentMethod(
                            index: 0,
                            title: checkoutProvider.selectedPaymentMethod,
                            subtitle: 'Will be used for this transaction',
                            icon: checkoutProvider.selectedPaymentMethod == 'Cash on Delivery' ? Iconsax.money_3 : Iconsax.card,
                            color: checkoutProvider.selectedPaymentMethod == 'Cash on Delivery' ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            delay: 400,
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // ── Bottom Container ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    )
                  ],
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(32),
                    topEnd: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 60, // Taller, premium button
                    child: Consumer<CheckoutProvider>(
                      builder: (context, checkoutProvider, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: checkoutProvider.isProcessing ? null : () async {
                              final cartProvider = context.read<CartProvider>();
                              if (cartProvider.items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Your cart is empty.')),
                                );
                                return;
                              }

                              // Process Payment
                              final orderId = await checkoutProvider.processPayment(cartProvider);
                              
                              if (orderId != null && context.mounted) {
                                final serviceName = cartProvider.serviceType ?? 'Order';
                                final itemsStr = cartProvider.items.map((e) => e.name).join(', ');

                                // Add to OrderProvider locally
                                await context.read<OrderProvider>().addOrder(OrderModel(
                                  id: orderId,
                                  title: '$serviceName: $itemsStr', 
                                  status: 'Pending',
                                  statusColor: const Color(0xFFF59E0B),
                                  icon: Iconsax.health,
                                  iconColor: const Color(0xFF3B82F6),
                                  price: cartProvider.total,
                                  date: DateTime.now(),
                                ));
                                
                                if (context.mounted) {
                                  // Clear cart on success
                                  cartProvider.clearCart();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderSuccessScreen(orderId: orderId),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: checkoutProvider.isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Consumer<CartProvider>(
                                    builder: (context, cart, child) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Confirm Order',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '\$${cart.total.toStringAsFixed(2)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Iconsax.arrow_right_3, color: Colors.white, size: 20),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, bool isTotal) {
    return Row(
      crossAxisAlignment: isTotal ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isTotal) ...[
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
          child: isTotal
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2563EB),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    final isSelected = _selectedPaymentMethod == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: const Color(0xFF94A3B8).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCBD5E1),
                  width: isSelected ? 8 : 2, // Thicker border when selected
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}

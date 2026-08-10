import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/main_shell.dart';

import '../orders/order_details_screen.dart';
import '../../core/providers/order_provider.dart';
import 'package:provider/provider.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6), // Solid blue background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Success Icon ──
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF3B82F6),
                            size: 50,
                          ),
                        ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // ── Text ──
                    Text(
                      'Request Sent\nSuccessfully!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.getSurface(context),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Your order has been received and is being processed. Our team will contact you shortly.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColors.getSurface(context).withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Buttons ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Find the newly added order in the provider
                        final orderProvider = context.read<OrderProvider>();
                        final order = orderProvider.orders.firstWhere((o) => o.id == orderId);
                        
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainShell(),
                          ),
                          (route) => false,
                        );
                        
                        // Push details on top
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getSurface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Track My Order',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainShell(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        color: AppColors.getSurface(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

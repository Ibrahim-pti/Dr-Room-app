import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/providers/order_provider.dart';
import '../../core/widgets/shimmer_loading_list.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'In Transit', 'Pending', 'Completed'];

  // Removed dummy orders

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hidden back button for main shell
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          
          // ── Filter Tabs ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(
                _filters.length,
                (index) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilterIndex == index
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilterIndex == index
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: _selectedFilterIndex == index
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.poppins(
                          color: _selectedFilterIndex == index
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: _selectedFilterIndex == index ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Orders List ──
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const ShimmerLoadingList();
                }

                final orders = orderProvider.orders;

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders yet.',
                      style: GoogleFonts.poppins(
                        color: AppColors.getTextSubtitle(context),
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                
                // Simple filtering logic
                if (_selectedFilterIndex != 0) {
                  if (_filters[_selectedFilterIndex] != order.status) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(order: order),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(24),
                              ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: order.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            order.icon,
                            color: order.iconColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.title,
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: order.statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: GoogleFonts.poppins(
                                        color: order.statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${order.date.day}/${order.date.month}/${order.date.year}',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${order.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF94A3B8),
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                );
              },
            );
          },
        ),
      ),
          
          // Extra space at bottom to ensure it clears the floating bottom nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

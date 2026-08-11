import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/order_provider.dart';
import '../../core/widgets/shimmer_loading_list.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  /// `null` is the "all" filter; the rest map 1:1 onto the API's statuses, so
  /// a chip can never select a status the server does not use.
  static const List<OrderStatus?> _filters = [
    null,
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // The shell keeps this screen alive in an IndexedStack, so initState runs
    // once; refresh() covers every later visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  /// Called by the shell each time the Orders tab is opened, so a status that
  /// changed while the patient was elsewhere shows up without a manual pull.
  void refresh() {
    if (mounted) context.read<OrderProvider>().fetchOrders();
  }

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
          'my_orders'.tr(),
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

          _buildFilterChips(),

          const SizedBox(height: 24),

          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                // Only the very first load takes over the screen; later
                // refreshes leave the current list on screen so the page does
                // not flash back to skeletons on every tab visit.
                if (orderProvider.isLoading && !orderProvider.hasLoadedOnce) {
                  return const ShimmerLoadingList();
                }

                if (orderProvider.error != null && orderProvider.orders.isEmpty) {
                  return _buildErrorState(orderProvider);
                }

                final orders = _selectedStatus == null
                    ? orderProvider.orders
                    : orderProvider.orders
                        .where((order) => order.status == _selectedStatus)
                        .toList();

                if (orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: orderProvider.fetchOrders,
                    child: _buildEmptyState(
                      isFiltered: _selectedStatus != null &&
                          orderProvider.orders.isNotEmpty,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: orderProvider.fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(orders[index], index),
                  ),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final status = _filters[index];
          final isSelected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : AppColors.getBorder(context),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B82F6)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  status == null ? 'filter_all'.tr() : status.label,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.white
                        : AppColors.getTextSubtitle(context),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, int index) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
          // The details screen can cancel an order, so pick up any change.
          if (mounted) refresh();
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.getBorder(context)),
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
                child: Icon(order.icon, color: order.iconColor, size: 26),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: order.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.statusLabel,
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
                      color: AppColors.getSurfaceSecondary(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textLight,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  /// Scrollable so the pull-to-refresh gesture still works on an empty list.
  Widget _buildEmptyState({required bool isFiltered}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Iconsax.box,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered ? 'no_orders_in_filter'.tr() : 'no_orders'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isFiltered) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'no_orders_hint'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(OrderProvider orderProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              orderProvider.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: orderProvider.isLoading
                  ? null
                  : () => orderProvider.fetchOrders(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'retry'.tr(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

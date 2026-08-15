import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/order_provider.dart';
import '../../core/widgets/shimmer_loading_list.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool embedded;

  const OrdersScreen({super.key, this.embedded = false});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  static const List<OrderStatus?> _filters = [
    null,
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  static const Map<OrderStatus?, String> _filterLabels = {
    null: 'هەمووی',
    OrderStatus.pending: 'چاوەڕوان',
    OrderStatus.processing: 'لە جێبەجێکردندایە',
    OrderStatus.completed: 'تەواوکراو',
    OrderStatus.cancelled: 'هەڵوەشێنراوە',
  };

  OrderStatus? _selectedStatus;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  void refresh() {
    if (mounted) context.read<OrderProvider>().fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = _buildContent(isDark);

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'داواکارییەکانم',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _buildFilterChips(isDark),
        const SizedBox(height: 14),
        Expanded(
          child: Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              if (orderProvider.isLoading && !orderProvider.hasLoadedOnce) {
                return const ShimmerLoadingList();
              }

              if (orderProvider.error != null && orderProvider.orders.isEmpty) {
                return _buildErrorState(orderProvider, isDark);
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
                    isFiltered: _selectedStatus != null && orderProvider.orders.isNotEmpty,
                    isDark: isDark,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: orderProvider.fetchOrders,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _buildOrderCard(orders[index], index, isDark),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final status = _filters[index];
          final isSelected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = status),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : borderColor,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  _filterLabels[status]!,
                  style: _kStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, int index, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
          if (mounted) refresh();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service Gradient Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      order.iconColor,
                      order.iconColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: order.iconColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(order.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),

              // Title and Date/Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: order.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _filterLabels[order.status] ?? 'چاوەڕوان',
                            style: _kStyle(
                              color: order.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${order.date.day}/${order.date.month}/${order.date.year}',
                          style: _kStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Price and Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,###').format(order.price)} د.ع',
                    style: _kStyle(
                      color: const Color(0xFF2563EB),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (40 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState({required bool isFiltered, required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Iconsax.receipt_2_1,
                  size: 38,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltered ? 'هیچ داواکارییەک نەدۆزرایەوە' : 'هیچ داواکارییەکت نییە',
              style: _kStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'لە ژێر ئەم بەشەدا هیچ داواکارییەک بەردەست نییە.'
                  : 'دەتوانیت لە ڕێگەی بەشەکانی ئەپەکەوە داواکاری نوێ تۆمار بکەیت.',
              textAlign: TextAlign.center,
              style: _kStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(OrderProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'کێشەیەک ڕوویدا لە بارکردنی داواکارییەکان',
              style: _kStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: provider.fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('دووبارە هەوڵبدەرەوە', style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

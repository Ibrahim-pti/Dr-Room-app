import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../doctors/chat_screen.dart';
import '../doctors/video_call_screen.dart';
import '../lab/lab_order_method_screen.dart';
import '../nursing/nursing_services_screen.dart';
import '../pharmacy/screens/pharmacies_screen.dart';
import 'widgets/order_progress_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  Timer? _pollingTimer;

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
    _currentOrder = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchFreshOrder();
      }
    });
    _startPolling();
  }

  Future<void> _fetchFreshOrder() async {
    try {
      if (!mounted) return;
      await context.read<OrderProvider>().fetchOrders();
      if (mounted) {
        final updatedOrder = context.read<OrderProvider>().orders.firstWhere(
          (o) => o.id == _currentOrder.id,
          orElse: () => _currentOrder,
        );
        setState(() {
          _currentOrder = updatedOrder;
        });
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      await context.read<OrderProvider>().fetchOrders();

      if (mounted) {
        final updatedOrder = context.read<OrderProvider>().orders.firstWhere(
          (o) => o.id == _currentOrder.id,
          orElse: () => _currentOrder,
        );

        if (updatedOrder.status != _currentOrder.status ||
            updatedOrder.assignedNurseId != _currentOrder.assignedNurseId) {
          setState(() {
            _currentOrder = updatedOrder;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'چاوەڕوانی پشتڕاستکردنەوەیە';
      case OrderStatus.processing:
        return 'لە قۆناغی جێبەجێکردندایە';
      case OrderStatus.completed:
        return 'تەواوکراوە';
      case OrderStatus.cancelled:
        return 'هەڵوەشێنراوەتەوە';
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'داواکارییەکەت گەیشت و لەلایەن تاقیگەوە چاوەڕوانی پشتڕاستکردنەوەیە.';
      case OrderStatus.processing:
        return 'داواکارییەکەت لە قۆناغی ئەنجامدان و بەدواداچووندایە.';
      case OrderStatus.completed:
        return 'هەموو پشکنینەکان بە سەرکەوتوویی تەواو کران.';
      case OrderStatus.cancelled:
        return 'ئەم داواکارییە هەڵوەشێنراوەتەوە.';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.processing:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final statusColor = _getStatusColor(_currentOrder.status);

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
          'وردەکاریی داواکاری',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFreshOrder,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Summary Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentOrder.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentOrder.title,
                            style: _kStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'کۆدی داواکاری: #${_currentOrder.id}',
                              style: _kStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // ── Status Banner Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.info_circle,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(_currentOrder.status),
                            style: _kStyle(
                              color: statusColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusDescription(_currentOrder.status),
                            style: _kStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentOrder.status.isActive)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // ── Progress Timeline ──
              OrderProgressTimeline(
                status: _currentOrder.status,
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05, end: 0),

              // ── Assigned Professional Card (if Nurse) ──
              if (_currentOrder.assignedNurseId != null &&
                  _currentOrder.assignedNurseName != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFEFF6FF),
                            backgroundImage:
                                _currentOrder.assignedNurseAvatar != null
                                ? NetworkImage(
                                    _currentOrder.assignedNurseAvatar!,
                                  )
                                : const AssetImage('assets/images/doc1.png')
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentOrder.assignedNurseName!,
                                  style: _kStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تیمی تەندروستی پەرستاری',
                                  style: _kStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      doctorName:
                                          _currentOrder.assignedNurseName!,
                                      doctorImage: 'assets/images/doc1.png',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Iconsax.message, size: 16),
                              label: Text(
                                'گفتوگۆ',
                                style: _kStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoCallScreen(
                                      doctorName:
                                          _currentOrder.assignedNurseName!,
                                      doctorImage: 'assets/images/doc1.png',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Iconsax.call,
                                size: 16,
                                color: Color(0xFF3B82F6),
                              ),
                              label: Text(
                                'پەیوەندی',
                                style: _kStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── Assigned Pharmacy Card (if Pharmacy) ──
              if (_currentOrder.assignedPharmacyName != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.hospital,
                          color: Color(0xFF10B981),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentOrder.assignedPharmacyName!,
                              style: _kStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'دەرمانخانەی جێبەجێکار',
                              style: _kStyle(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Order Information Card ──
              Container(
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
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.receipt,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'زانیاریی داواکاری',
                          style: _kStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      'بەرواری تۆمارکردن',
                      '${_currentOrder.date.day}/${_currentOrder.date.month}/${_currentOrder.date.year}',
                      isDark: isDark,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      context,
                      'کاتی داواکاری',
                      '${_currentOrder.date.hour}:${_currentOrder.date.minute.toString().padLeft(2, '0')}',
                      isDark: isDark,
                    ),
                    if (_currentOrder.paymentMethod != null) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildDetailRow(
                        context,
                        'شێوازی پارەدان',
                        _formatPaymentMethod(_currentOrder.paymentMethod),
                        isDark: isDark,
                      ),
                    ],
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      context,
                      'کۆی گشتی نرخ',
                      '${NumberFormat('#,###').format(_currentOrder.price)} د.ع',
                      isTotal: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPaymentMethod(String? raw) {
    if (raw == null || raw.isEmpty) return 'کاش';
    final lower = raw.toLowerCase();
    if (lower.contains('delivery') || lower.contains('cash') || lower.contains('کاش')) {
      return 'کاش لەکاتی وەرگرتن';
    } else if (lower.contains('fastpay')) {
      return 'FastPay';
    } else if (lower.contains('fib')) {
      return 'FIB بانکی یەکەمی عێراق';
    } else if (lower.contains('zain')) {
      return 'Zain Cash';
    }
    return raw;
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _kStyle(
            color: const Color(0xFF64748B),
            fontSize: isTotal ? 14.5 : 13.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: _kStyle(
            color: isTotal
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

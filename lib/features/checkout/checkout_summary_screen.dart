import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'order_success_screen.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/providers/cart_provider.dart';

class CheckoutSummaryScreen extends StatefulWidget {
  const CheckoutSummaryScreen({super.key});

  @override
  State<CheckoutSummaryScreen> createState() => _CheckoutSummaryScreenState();
}

class _CheckoutSummaryScreenState extends State<CheckoutSummaryScreen> {
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

  String _getServiceTitle(String? type) {
    switch (type) {
      case 'lab':
        return 'پشکنینی تاقیگە';
      case 'pharmacy':
        return 'دەرمانخانە';
      case 'nursing':
        return 'خزمەتگوزاری پەرستاری';
      default:
        return 'خزمەتگوزاری پزیشکی';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'پوختەی داواکاری و پارەدان',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.receipt_2, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'وردەکاریی داواکارییەکەت',
                        style: _kStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 16),

                  // ── Summary Card ──
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      final itemsString = cartProvider.items.map((e) => e.name).join('، ');
                      final patient = cartProvider.patientDetails;
                      final String? location = patient?['location'];
                      final String? patientName = patient?['name'];

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              // Top gradient bar
                              Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildSummaryRow(
                                      Iconsax.health,
                                      'جۆری خزمەتگوزاری',
                                      _getServiceTitle(cartProvider.serviceType),
                                      false,
                                    ),
                                    if (patientName != null && patientName.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.user,
                                        'ناوی داواکار',
                                        patientName,
                                        false,
                                      ),
                                    ],
                                    if (itemsString.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.box,
                                        'پشکنینەکان (${cartProvider.items.length})',
                                        itemsString,
                                        false,
                                      ),
                                    ],
                                    if (location != null && location.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.location,
                                        'ناونیشان',
                                        location,
                                        false,
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    _buildSummaryRow(
                                      Iconsax.wallet_3,
                                      'نرخی پشکنینەکان',
                                      '${NumberFormat('#,###').format(cartProvider.subtotal)} د.ع',
                                      false,
                                    ),
                                    if (cartProvider.extraFee > 0) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.coin_1,
                                        'کرێی گەیاندن/وەرگرتن',
                                        '${NumberFormat('#,###').format(cartProvider.extraFee)} د.ع',
                                        false,
                                      ),
                                    ],
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: _DashedDivider(),
                                    ),
                                    _buildSummaryRow(
                                      Iconsax.ticket_discount,
                                      'کۆی گشتی',
                                      '${NumberFormat('#,###').format(cartProvider.total)} د.ع',
                                      true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.04),

                  const SizedBox(height: 24),

                  // ── Selected Payment Method Preview ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.card, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'شێوازی پارەدانی هەڵبژێردراو',
                        style: _kStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),

                  Consumer<CheckoutProvider>(
                    builder: (context, checkoutProvider, child) {
                      final method = checkoutProvider.selectedPaymentMethod;
                      final bool isCash = method == 'Cash on Delivery' || method == 'کاش لەکاتی وەرگرتن' || method == 'کاش لەکاتی وەرگرتندا';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCash ? Iconsax.wallet_2 : Iconsax.card,
                                color: isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCash ? 'کاش لەکاتی وەرگرتن' : method,
                                    style: _kStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCash
                                        ? 'پارەدان بە دەست لە کاتی سەردان یان وەرگرتنی نموونە'
                                        : 'تەواوکردنی پارەدان لە ڕێگەی ئۆنلاین',
                                    style: _kStyle(
                                      color: const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Confirm Button ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                height: 54,
                child: Consumer<CheckoutProvider>(
                  builder: (context, checkoutProvider, child) {
                    return ElevatedButton(
                      onPressed: checkoutProvider.isProcessing
                          ? null
                          : () async {
                              final cartProvider = context.read<CartProvider>();
                              if (cartProvider.items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('هیچ پشکنینێک لە سەبەتەکەدا نییە.', style: _kStyle(color: Colors.white)),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                                return;
                              }

                              // Process Payment
                              final orderId = await checkoutProvider.processPayment(cartProvider);

                              if (orderId != null && context.mounted) {
                                final serviceName = cartProvider.serviceType ?? 'lab';
                                final itemsStr = cartProvider.items.map((e) => e.name).join('، ');

                                await context.read<OrderProvider>().addOrder(OrderModel(
                                  id: orderId,
                                  serviceType: serviceName,
                                  customTitle: itemsStr.isEmpty ? null : itemsStr,
                                  status: OrderStatus.pending,
                                  price: cartProvider.total,
                                  date: DateTime.now(),
                                ));

                                if (context.mounted) {
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
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: checkoutProvider.isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Consumer<CartProvider>(
                              builder: (context, cart, child) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'تەواوکردنی داواکاری',
                                          style: _kStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${NumberFormat('#,###').format(cart.total)} د.ع',
                                        style: _kStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ),
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
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: _kStyle(
              color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontSize: isTotal ? 16 : 13.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: isTotal
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: _kStyle(
                      color: const Color(0xFF2563EB),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _kStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
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
        const dashHeight = 1.2;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
              ),
            );
          }),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'order_success_screen.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/rasedi_payment_service.dart';
import 'rasedi_checkout_screen.dart';

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
        return 'lab_service'.tr();
      case 'pharmacy':
        return 'pharmacy'.tr();
      case 'nursing':
        return 'nursing_services'.tr();
      default:
        return 'general_service'.tr();
    }
  }

  String _formatDisplayAddress(String? rawAddress) {
    if (rawAddress == null || rawAddress.trim().isEmpty) {
      return 'address'.tr();
    }
    if (rawAddress == 'سەردانی تاقیگە' || rawAddress == 'visit_lab'.tr()) {
      return 'visit_lab'.tr();
    }

    final Map<String, String> translationMap = {
      // Kurdistan & Iraq
      'erbil': 'هەولێر',
      'hawler': 'هەولێر',
      'arbil': 'هەولێر',
      'sulaymaniyah': 'سلێمانی',
      'slemani': 'سلێمانی',
      'duhok': 'دهۆک',
      'dohuk': 'دهۆک',
      'kirkuk': 'کەرکووک',
      'baghdad': 'بەغدا',
      'basra': 'بەسرە',
      'halabja': 'هەڵەبجە',
      'zakho': 'زاخۆ',
      'soran': 'سۆران',
      'koya': 'کۆیە',
      'rania': 'ڕانیە',
      'kalar': 'کەلار',
      'chamchamal': 'چەمچەماڵ',
      'shaqlawa': 'شەقڵاوە',
      'ankawa': 'عەنکاوە',
      'bakhtiyari': 'بەختیاری',
      'waziran': 'وەزیران',
      'shorsh': 'شۆڕش',
      'ashti': 'ئاشتی',
      'havalan': 'هەڤاڵان',
      'kurdistan': 'کوردستان',
      'iraq': 'عێراق',
      // Simulator / International
      'san francisco': 'سان فرانسیسکۆ',
      'california': 'کالیفۆرنیا',
      'ca': 'کالیفۆرنیا',
      'united states': 'ئەمریکا',
      'usa': 'ئەمریکا',
      'union square': 'یۆنیۆن سکوێر',
      'yerba buena': 'یێربا بوێنا',
      'yerba': 'یێربا',
      'buena': 'بوێنا',
      'cupertino': 'کووپەرتینۆ',
      // Terms
      'street': 'شەقام',
      'st': 'شەقام',
      'road': 'ڕێگا',
      'rd': 'ڕێگا',
      'avenue': 'شەقام',
      'ave': 'شەقام',
      'boulevard': 'شەقام',
      'district': 'گەڕەک',
      'neighborhood': 'گەڕەک',
      'quarter': 'گەڕەک',
      'center': 'سەنتەر',
      'square': 'مەیدان',
    };

    String clean = rawAddress;
    for (final entry in translationMap.entries) {
      clean = clean.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }

    List<String> parts = clean
        .split(RegExp(r'[,،]'))
        .map((p) => p.replaceAll(RegExp(r'^\d+[-\d]*\s*'), '').replaceAll(RegExp(r'\s*\d+[-\d]*$'), '').trim())
        .where((p) => p.isNotEmpty && !p.toLowerCase().contains('unnamed') && !p.contains('+'))
        .toSet()
        .toList();

    if (parts.length > 2) {
      parts.removeWhere((p) => p == 'ئەمریکا' || p == 'کالیفۆرنیا' || p == 'CA' || p == 'USA');
    }

    if (parts.isEmpty) {
      return rawAddress;
    }

    return parts.take(2).join('، ');
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
          'order_summary_title'.tr(),
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
                        'order_details_title'.tr(),
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
                      CartItem? staffItem;
                      for (final item in cartProvider.items) {
                        if (item.extraData?['type'] == 'staff' || item.id.startsWith('staff_')) {
                          staffItem = item;
                          break;
                        }
                      }
                      final nonStaffItems = cartProvider.items.where(
                        (e) => e.extraData?['type'] != 'staff' && !e.id.startsWith('staff_')
                      ).toList();
                      final patient = cartProvider.patientDetails;
                      final String? location = patient?['location'];
                      final String? patientName = patient?['name'];
                      final String? staffName = staffItem?.extraData?['staff_name'] ?? patient?['staff_name'];
                      final String? staffTitle = staffItem?.extraData?['staff_title'] ?? patient?['staff_title'];

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
                                      'service_type'.tr(),
                                      _getServiceTitle(cartProvider.serviceType),
                                      false,
                                    ),
                                    if (patientName != null && patientName.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.user,
                                        'applicant_name'.tr(),
                                        patientName,
                                        false,
                                      ),
                                    ],
                                    if (staffName != null && staffName.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.profile_circle,
                                        'selected_specialist'.tr(),
                                        staffTitle != null && staffTitle.isNotEmpty
                                            ? '$staffName ($staffTitle)'
                                            : staffName,
                                        false,
                                      ),
                                    ],
                                    if (nonStaffItems.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildItemsSection(nonStaffItems, isDark, borderColor),
                                    ],
                                    if (location != null && location.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.location,
                                        'address'.tr(),
                                        _formatDisplayAddress(location),
                                        false,
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    _buildSummaryRow(
                                      Iconsax.wallet_3,
                                      'tests_price'.tr(),
                                      '${NumberFormat('#,###').format(cartProvider.subtotal)} د.ع',
                                      false,
                                    ),
                                    if (cartProvider.extraFee > 0) ...[
                                      const SizedBox(height: 14),
                                      _buildSummaryRow(
                                        Iconsax.car,
                                        'home_visit_fee'.tr(),
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
                                      'total'.tr(),
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
                        'selected_payment_method_label'.tr(),
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
                      final bool isCash = method == 'Cash on Delivery' ||
                          method == 'کاش لەکاتی وەرگرتن' ||
                          method == 'کاش لەکاتی وەرگرتندا' ||
                          method == 'کاش' ||
                          method.toLowerCase().contains('cash');

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
                                    isCash ? 'payment_cash'.tr() : method,
                                    style: _kStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCash
                                        ? 'cash_delivery_desc'.tr()
                                        : 'online_payment_desc'.tr(),
                                    style: _kStyle(
                                      color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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

                              // Check if selected payment method uses Rasedi Gateway
                              final selectedMethod = checkoutProvider.selectedPaymentMethod;
                              final gateway = RasediPaymentService.mapMethodToGateway(selectedMethod);
                              String? transactionRef;

                              if (gateway != null) {
                                final result = await RasediCheckoutScreen.startPayment(
                                  context,
                                  amount: cartProvider.total,
                                  title: 'DrRoom - ${cartProvider.serviceType ?? 'Medical'}',
                                  description: cartProvider.items.map((e) => e.name).join('، '),
                                  gateway: gateway,
                                  customerPhone: cartProvider.patientDetails?['phone']?.toString(),
                                );

                                if (result == null || !result.isSuccess) {
                                  if (context.mounted && result?.isCancelled != true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result?.errorMessage ?? 'پرۆسەی پارەدان تەواو نەکرا',
                                          style: _kStyle(color: Colors.white),
                                        ),
                                        backgroundColor: const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                transactionRef = result.referenceCode;
                              }

                              // Process Order & Record Transaction
                              final orderId = await checkoutProvider.processPayment(
                                cartProvider,
                                transactionReference: transactionRef,
                              );

                              if (orderId != null && context.mounted) {
                                final serviceName = cartProvider.serviceType ?? 'lab';
                                final itemsStr = cartProvider.items.map((e) => e.name).join('، ');

                                await context.read<OrderProvider>().addOrder(OrderModel(
                                  id: orderId,
                                  serviceType: serviceName,
                                  customTitle: itemsStr.isEmpty ? null : itemsStr,
                                  status: transactionRef != null ? OrderStatus.processing : OrderStatus.pending,
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
                                          'complete_order'.tr(),
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
          Icon(icon, size: 17, color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(
    List<CartItem> items,
    bool isDark,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.box,
              size: 17,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Text(
              'tests_count'.tr(),
              style: _kStyle(
                color: const Color(0xFF64748B),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == items.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: _kStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (item.price > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${NumberFormat('#,###').format(item.price)} د.ع',
                        style: _kStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
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
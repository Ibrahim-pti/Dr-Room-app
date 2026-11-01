import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../core/utils/api_client.dart';
import '../../../core/providers/cart_provider.dart' as core_cart;
import '../providers/cart_provider.dart' as pharmacy_cart;
import '../../checkout/checkout_details_screen.dart';
import 'pharmacy_checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
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
      height: height ?? 1.35,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  void _confirmClearCart(core_cart.CartProvider coreCart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'cart_clear_title'.tr(),
          style: _kStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'cart_clear_confirm'.tr(),
          style: _kStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr(),
              style: _kStyle(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              coreCart.clearCart();
              ref.read(pharmacy_cart.cartProvider.notifier).clearCart();
            },
            child: Text(
              'cart_clear_yes'.tr(),
              style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(
    core_cart.CartProvider coreCart,
    pharmacy_cart.CartState pharmacyCartState,
  ) {
    final bool hasCore = coreCart.items.isNotEmpty;
    final bool hasPharmacy = pharmacyCartState.items.isNotEmpty;

    if (!hasCore && !hasPharmacy) return;

    if (hasCore && !hasPharmacy) {
      coreCart.setServiceType(coreCart.effectiveServiceType, extraFee: coreCart.extraFee);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CheckoutDetailsScreen()),
      );
    } else if (!hasCore && hasPharmacy) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PharmacyCheckoutScreen()),
      );
    } else {
      // Both Core and Pharmacy items exist in the cart
      _showMultiCheckoutSheet(coreCart, pharmacyCartState);
    }
  }

  void _showMultiCheckoutSheet(
    core_cart.CartProvider coreCart,
    pharmacy_cart.CartState pharmacyCartState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'cart_choose_order_title'.tr(),
                style: _kStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'cart_choose_order_desc'.tr(),
                style: _kStyle(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              // Option 1: Lab & Nursing
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(ctx);
                  coreCart.setServiceType(coreCart.effectiveServiceType, extraFee: coreCart.extraFee);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutDetailsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.science_outlined, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'cart_order_lab_nursing'.tr(),
                              style: _kStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${coreCart.items.length} ${'cart_services_count'.tr()} • ${NumberFormat('#,###').format(coreCart.total.toInt())} ${'currency_iqd'.tr()}',
                              style: _kStyle(
                                fontSize: 12.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Pharmacy
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PharmacyCheckoutScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF7C3AED), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'cart_order_pharmacy'.tr(),
                              style: _kStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pharmacyCartState.totalItems} ${'cart_medications_count'.tr()} • ${NumberFormat('#,###').format(pharmacyCartState.total.toInt())} ${'currency_iqd'.tr()}',
                              style: _kStyle(
                                fontSize: 12.5,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 15, color: Color(0xFF7C3AED)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final pharmacyCartState = ref.watch(pharmacy_cart.cartProvider);
    final coreCart = provider_pkg.Provider.of<core_cart.CartProvider>(context);

    final bool hasPharmacy = pharmacyCartState.items.isNotEmpty;
    final bool hasCore = coreCart.items.isNotEmpty;
    final bool isEmpty = !hasPharmacy && !hasCore;

    final double subtotal = (hasPharmacy ? pharmacyCartState.subtotal : 0.0) +
        (hasCore ? coreCart.subtotal : 0.0);
    final double extraFee = (hasPharmacy ? (pharmacyCartState.pharmacy?.deliveryFee ?? 0.0) : 0.0) +
        (hasCore ? coreCart.extraFee : 0.0);
    final double grandTotal = subtotal + extraFee;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'cart_title'.tr(),
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
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
        actions: [
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.trash,
                    color: Color(0xFFEF4444),
                    size: 17,
                  ),
                  tooltip: 'cart_clear_title'.tr(),
                  onPressed: () => _confirmClearCart(coreCart),
                ),
              ),
            ),
        ],
      ),
      body: isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Iconsax.shopping_cart, size: 40, color: Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Exactly as requested: "سەبەتەکەت بەتالە بەس ئەوە بمینێ"
                    Text(
                      'cart_empty_title'.tr(),
                      style: _kStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    children: [
                      // 1. Core items (Lab & Nursing)
                      if (hasCore) ...[
                        ...coreCart.items.map((item) {
                          final isLab = item.extraData?['type'] == 'test' ||
                              item.extraData?['type'] == 'package' ||
                              item.extraData?['lab_id'] != null ||
                              item.extraData?['lab_name'] != null ||
                              coreCart.effectiveServiceType == 'lab';
                          final isNursing = item.extraData?['type'] == 'nursing_service' ||
                              item.extraData?['nurse_id'] != null ||
                              item.id.startsWith('nurse_') ||
                              coreCart.effectiveServiceType == 'nursing';

                          final Color badgeColor = isLab
                              ? const Color(0xFF2563EB)
                              : (isNursing ? const Color(0xFF0D9488) : const Color(0xFF7C3AED));
                          final String badgeText = isLab
                              ? 'cat_lab'.tr()
                              : (isNursing ? 'nursing_title'.tr() : 'general_service'.tr());
                          final IconData badgeIcon = isLab
                              ? Icons.science_outlined
                              : (isNursing ? Icons.medical_services_outlined : Iconsax.health);

                          String? subtitle;
                          if (item.extraData != null) {
                            if (item.extraData?['lab_name'] != null) {
                              subtitle = item.extraData!['lab_name'].toString();
                            } else if (item.extraData?['nurse_name'] != null) {
                              subtitle = item.extraData!['nurse_name'].toString();
                            } else if (item.extraData?['type'] == 'package') {
                              subtitle = 'cart_lab_package'.tr();
                            } else if (item.extraData?['category'] != null) {
                              subtitle = item.extraData!['category'].toString();
                            }
                          }
                          if (subtitle == null || subtitle.isEmpty) {
                            subtitle = isLab ? 'lab_service'.tr() : (isNursing ? 'nursing_services'.tr() : null);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Leading Icon
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(badgeIcon, color: badgeColor, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Service Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(badgeIcon, size: 11, color: badgeColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              badgeText,
                                              style: _kStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        item.name,
                                        style: _kStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (subtitle != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          subtitle,
                                          style: _kStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        '${NumberFormat('#,###').format(item.totalPrice.toInt())} ${'currency_iqd'.tr()}',
                                        style: _kStyle(
                                          fontSize: 13.5,
                                          color: badgeColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity and Action Controls
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              item.quantity > 1 ? Icons.remove : Iconsax.trash,
                                              size: 15,
                                              color: item.quantity > 1 ? null : const Color(0xFFEF4444),
                                            ),
                                            onPressed: () {
                                              coreCart.decrementItem(item.id);
                                            },
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: _kStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 15),
                                            onPressed: () => coreCart.updateQuantity(item.id, item.quantity + 1),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => coreCart.removeItem(item.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Text(
                                          'remove'.tr(),
                                          style: _kStyle(
                                            fontSize: 11,
                                            color: const Color(0xFFEF4444),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // 2. Pharmacy items
                      if (hasPharmacy) ...[
                        ...pharmacyCartState.items.map((item) {
                          const badgeColor = Color(0xFF6366F1);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    child: item.medication.imageUrl != null && item.medication.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.medication.imageUrl!.startsWith('http')
                                                ? item.medication.imageUrl!
                                                : '${ApiClient.storageUrl}/${item.medication.imageUrl}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                              Icons.medication_liquid_rounded,
                                              color: badgeColor,
                                              size: 28,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.medication_liquid_rounded,
                                            color: badgeColor,
                                            size: 28,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.medication_liquid_rounded, size: 11, color: badgeColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'pharmacy_title'.tr(),
                                              style: _kStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        item.medication.name,
                                        style: _kStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.unit,
                                        style: _kStyle(fontSize: 12, color: const Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${NumberFormat('#,###').format(item.totalPrice.toInt())} ${'currency_iqd'.tr()}',
                                        style: _kStyle(
                                          fontSize: 13.5,
                                          color: badgeColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              item.quantity > 1 ? Icons.remove : Iconsax.trash,
                                              size: 15,
                                              color: item.quantity > 1 ? null : const Color(0xFFEF4444),
                                            ),
                                            onPressed: () {
                                              ref.read(pharmacy_cart.cartProvider.notifier).updateQuantity(
                                                    item.medication.id,
                                                    item.quantity - 1,
                                                    unit: item.unit,
                                                  );
                                            },
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: _kStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 15),
                                            onPressed: () => ref.read(pharmacy_cart.cartProvider.notifier).updateQuantity(
                                                  item.medication.id,
                                                  item.quantity + 1,
                                                  unit: item.unit,
                                                ),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => ref.read(pharmacy_cart.cartProvider.notifier).removeItem(
                                            item.medication.id,
                                            unit: item.unit,
                                          ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Text(
                                          'remove'.tr(),
                                          style: _kStyle(
                                            fontSize: 11,
                                            color: const Color(0xFFEF4444),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                // Bottom Checkout Bar
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(top: BorderSide(color: borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'items_subtotal'.tr(),
                              style: _kStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(subtotal.toInt())} ${'currency_iqd'.tr()}',
                              style: _kStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (extraFee > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'delivery_fee'.tr(),
                                style: _kStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(extraFee.toInt())} ${'currency_iqd'.tr()}',
                                style: _kStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: borderColor),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'total'.tr(),
                              style: _kStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(grandTotal.toInt())} ${'currency_iqd'.tr()}',
                              style: _kStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _proceedToCheckout(coreCart, pharmacyCartState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'complete_purchase'.tr(),
                              textAlign: TextAlign.center,
                              style: _kStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

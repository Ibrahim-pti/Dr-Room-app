import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/utils/api_client.dart';
import '../../core/providers/order_provider.dart';
import '../doctors/chat_screen.dart';
import '../doctors/video_call_screen.dart';
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

  String _getStatusTitle(OrderStatus status, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (status) {
      case OrderStatus.pending:
        if (lang == 'kmr') return _currentOrder.statusLabelKmr ?? 'چاڤەڕێی پشتڕاستکرنێیە';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'قيد الانتظار والتأكيد';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'Pending Confirmation';
        return _currentOrder.statusLabelCkb ?? 'چاوەڕوانی پشتڕاستکردنەوەیە';
      case OrderStatus.processing:
        if (lang == 'kmr') return _currentOrder.statusLabelKmr ?? 'د قۆناغا بجهئینانێ دایە';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'قيد التنفيذ والمتابعة';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'In Progress';
        return _currentOrder.statusLabelCkb ?? 'لە قۆناغی جێبەجێکردندایە';
      case OrderStatus.completed:
        if (lang == 'kmr') return _currentOrder.statusLabelKmr ?? 'تەواوکرایە';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'مكتمل بنجاح';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'Completed Successfully';
        return _currentOrder.statusLabelCkb ?? 'تەواوکراوە';
      case OrderStatus.cancelled:
        if (lang == 'kmr') return _currentOrder.statusLabelKmr ?? 'هاتیە هەلوەشاندن';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'ملغي';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'Cancelled';
        return _currentOrder.statusLabelCkb ?? 'هەڵوەشێنراوەتەوە';
    }
  }

  String _getStatusDescription(OrderStatus status, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (status) {
      case OrderStatus.pending:
        if (lang == 'kmr') return 'داخوازییا تە گەهشت و چاڤەڕێی پشتڕاستکرنێیە.';
        if (lang == 'ar') return 'تم استلام طلبك وهو بانتظار التأكيد.';
        if (lang == 'en') return 'Your order has been received and is awaiting confirmation.';
        return 'داواکارییەکەت گەیشت و لەلایەن تاقیگەوە چاوەڕوانی پشتڕاستکردنەوەیە.';
      case OrderStatus.processing:
        if (lang == 'kmr') return 'داخوازییا تە د قۆناغا ئەنجامدان و دووڤچوونێ دایە.';
        if (lang == 'ar') return 'طلبك قيد التنفيذ والمتابعة من قبل الفريق الطبي.';
        if (lang == 'en') return 'Your order is currently being processed and prepared.';
        return 'داواکارییەکەت لە قۆناغی ئەنجامدان و بەدواداچووندایە.';
      case OrderStatus.completed:
        if (lang == 'kmr') return 'هەمی پشکنین و خزمەتگوزاری ب سەرکەفتیانە هاتنە تمامکرن.';
        if (lang == 'ar') return 'تم إكمال جميع الفحوصات والخدمات بنجاح.';
        if (lang == 'en') return 'All services and examinations have been successfully completed.';
        return 'هەموو پشکنینەکان بە سەرکەوتوویی تەواو کران.';
      case OrderStatus.cancelled:
        if (lang == 'kmr') return 'ئەڤ داخوازییە هاتیە هەلوەشاندن.';
        if (lang == 'ar') return 'تم إلغاء هذا الطلب.';
        if (lang == 'en') return 'This order has been cancelled.';
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
          'order_details'.tr(),
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
                            _currentOrder.localizedTitle(context),
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
                              '${'order_id'.tr()}: #${_currentOrder.id}',
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
                            _getStatusTitle(_currentOrder.status, context),
                            style: _kStyle(
                              color: statusColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusDescription(_currentOrder.status, context),
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
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: (_currentOrder.assignedNurseAvatar != null &&
                                      _currentOrder.assignedNurseAvatar!.trim().isNotEmpty)
                                  ? Image.network(
                                      ApiClient.getImageUrl(_currentOrder.assignedNurseAvatar),
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 52,
                                      errorBuilder: (c, e, s) => const Center(
                                        child: Icon(Iconsax.user, color: Color(0xFF3B82F6), size: 26),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Iconsax.user, color: Color(0xFF3B82F6), size: 26),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentOrder.localizedNurseName(context) ?? _currentOrder.assignedNurseName!,
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
                                  _currentOrder.localizedNurseSpecialty(context) ?? 'nursing_team'.tr(),
                                  style: _kStyle(
                                    color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                                final nurseDisplayName = _currentOrder.localizedNurseName(context) ?? _currentOrder.assignedNurseName!;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      doctorName: nurseDisplayName,
                                      doctorImage: _currentOrder.assignedNurseAvatar ?? 'assets/images/doctor1.png',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Iconsax.message, size: 16),
                              label: Text(
                                'chat'.tr(),
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
                                final nurseDisplayName = _currentOrder.localizedNurseName(context) ?? _currentOrder.assignedNurseName!;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoCallScreen(
                                      doctorName: nurseDisplayName,
                                      doctorImage: _currentOrder.assignedNurseAvatar ?? 'assets/images/doctor1.png',
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
                                'call'.tr(),
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
                              _currentOrder.localizedPharmacyName(context) ?? _currentOrder.assignedPharmacyName!,
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
                              'executing_pharmacy'.tr(),
                              style: _kStyle(
                                color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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

              // ── Prescription Photo Card (if order is from prescription) ──
              if (_currentOrder.prescriptionImage != null &&
                  _currentOrder.prescriptionImage!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
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
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.document_upload,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'prescription_photo'.tr(),
                            style: _kStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GestureDetector(
                          onTap: () {
                            final provider = ApiClient.getImageProvider(_currentOrder.prescriptionImage);
                            if (provider == null) return;
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(16),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image(image: provider, fit: BoxFit.contain),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image(
                                image: ApiClient.getImageProvider(_currentOrder.prescriptionImage)!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 100,
                                  alignment: Alignment.center,
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  child: Text(
                                    'could_not_load_image'.tr(),
                                    style: _kStyle(color: const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Icon(Iconsax.eye, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05, end: 0),
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
                          'order_information'.tr(),
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
                      'order_date'.tr(),
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
                      'order_time'.tr(),
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
                        'payment_method'.tr(),
                        _formatPaymentMethod(_currentOrder.paymentMethod, context),
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
                      'total_price'.tr(),
                      '${NumberFormat('#,###').format(_currentOrder.price)} ${'currency_iqd'.tr()}',
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

  String _formatPaymentMethod(String? raw, BuildContext context) {
    if (raw == null || raw.isEmpty) return 'cash_on_delivery'.tr();
    final lower = raw.toLowerCase();
    if (lower.contains('delivery') || lower.contains('cash') || lower.contains('کاش')) {
      return 'cash_on_delivery'.tr();
    } else if (lower.contains('fastpay')) {
      return 'FastPay';
    } else if (lower.contains('fib')) {
      return 'FIB بانکی یەکەمی عێراق';
    } else if (lower.contains('zain')) {
      return 'Zain Cash';
    } else if (lower.contains('qi') || lower.contains('card') || lower.contains('stripe')) {
      return 'کی کارد / کارتی بانکی';
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
            color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
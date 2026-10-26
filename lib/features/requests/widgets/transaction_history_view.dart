import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../orders/order_details_screen.dart';
import '../../doctors/doctor_details_screen.dart';

class TransactionHistoryView extends StatefulWidget {
  final bool embedded;
  final String? fixedCategory;

  const TransactionHistoryView({
    super.key,
    this.embedded = false,
    this.fixedCategory,
  });

  @override
  State<TransactionHistoryView> createState() => TransactionHistoryViewState();
}

class TransactionHistoryViewState extends State<TransactionHistoryView> {
  String _selectedCategory = 'all';

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
    if (widget.fixedCategory != null) {
      _selectedCategory = widget.fixedCategory!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderProvider>().fetchOrders();
        context.read<AppointmentProvider>().fetchAppointments();
      }
    });
  }

  @override
  void didUpdateWidget(TransactionHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedCategory != oldWidget.fixedCategory &&
        widget.fixedCategory != null) {
      setState(() {
        _selectedCategory = widget.fixedCategory!;
      });
    }
  }

  void refresh() {
    if (mounted) {
      context.read<OrderProvider>().fetchOrders();
      context.read<AppointmentProvider>().fetchAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<OrderProvider, AppointmentProvider>(
      builder: (context, orderProvider, appointmentProvider, _) {
        final isLoading =
            (orderProvider.isLoading && !orderProvider.hasLoadedOnce) ||
            (appointmentProvider.isLoading &&
                appointmentProvider.appointments.isEmpty);

        if (isLoading) {
          return const ShimmerLoadingList();
        }

        // 1. Filter completed/cancelled orders (inactive orders belong to history)
        final completedOrders = orderProvider.orders
            .where((o) => !o.status.isActive)
            .toList();

        // 2. Filter completed/cancelled appointments
        final completedAppointments = appointmentProvider.appointments.where((
          a,
        ) {
          return a.status == AppointmentStatus.completed ||
              a.status == AppointmentStatus.cancelled ||
              a.appointmentDate.isBefore(DateTime.now());
        }).toList();

        // Build unified list of history items
        final List<_HistoryItem> allItems = [
          ...completedOrders.map((o) => _HistoryItem.order(o)),
          ...completedAppointments.map((a) => _HistoryItem.appointment(a)),
        ]..sort((a, b) => b.date.compareTo(a.date));

        // Filter based on selected category
        final filteredItems = allItems.where((item) {
          if (_selectedCategory == 'all') return true;
          if (_selectedCategory == 'nursing') {
            return item.order != null && item.order!.isNursing;
          }
          if (_selectedCategory == 'lab') {
            return item.order != null && item.order!.isLab;
          }
          if (_selectedCategory == 'pharmacy') {
            return item.order != null && item.order!.isPharmacy;
          }
          if (_selectedCategory == 'appointments') {
            return item.appointment != null;
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fixedCategory == null) ...[
              const SizedBox(height: 6),
              _buildCategoryChips(
                isDark,
                completedOrders: completedOrders,
                completedAppointments: completedAppointments,
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState(
                      isDark: isDark,
                      isFiltered: _selectedCategory != 'all' &&
                          widget.fixedCategory == null &&
                          allItems.isNotEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: () async => refresh(),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          if (item.order != null) {
                            return _buildOrderCard(item.order!, index, isDark);
                          } else if (item.appointment != null) {
                            return _buildAppointmentCard(
                              item.appointment!,
                              index,
                              isDark,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(
    bool isDark, {
    required List<OrderModel> completedOrders,
    required List<Appointment> completedAppointments,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final totalCount = completedOrders.length + completedAppointments.length;
    final nursingCount = completedOrders.where((o) => o.isNursing).length;
    final labCount = completedOrders.where((o) => o.isLab).length;
    final pharmacyCount = completedOrders.where((o) => o.isPharmacy).length;
    final apptCount = completedAppointments.length;

    final categories = [
      _HistoryCategoryOption(
        id: 'all',
        label: 'category_all'.tr(),
        icon: Iconsax.element_4,
        color: const Color(0xFF3B82F6),
        count: totalCount,
      ),
      _HistoryCategoryOption(
        id: 'nursing',
        label: 'category_nursing'.tr(),
        icon: Iconsax.health,
        color: const Color(0xFF10B981),
        count: nursingCount,
      ),
      _HistoryCategoryOption(
        id: 'lab',
        label: 'category_lab'.tr(),
        icon: Iconsax.d_cube_scan,
        color: const Color(0xFF8B5CF6),
        count: labCount,
      ),
      if (pharmacyCount > 0)
        _HistoryCategoryOption(
          id: 'pharmacy',
          label: 'category_pharmacy'.tr(),
          icon: Iconsax.shop,
          color: const Color(0xFF0D9488),
          count: pharmacyCount,
        ),
      if (apptCount > 0)
        _HistoryCategoryOption(
          id: 'appointments',
          label: 'category_appointments'.tr(),
          icon: Iconsax.calendar_1,
          color: const Color(0xFFF59E0B),
          count: apptCount,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.id;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () {
                if (_selectedCategory != cat.id) {
                  setState(() => _selectedCategory = cat.id);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? cat.color : borderColor,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.3),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 15,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: _kStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569)),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),
                    if (cat.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : cat.color.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cat.count}',
                          style: _kStyle(
                            color: isSelected ? Colors.white : cat.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, int index, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

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
                      order.localizedTitle(context),
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy/MM/dd • hh:mm a').format(order.date),
                          style: _kStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (order.assignedNurseName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${'nurse'.tr()}: ${order.assignedNurseName}',
                        style: _kStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Status and Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(
                    label: order.statusLabel,
                    color: order.statusColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.price > 0
                        ? Currency.format(order.price)
                        : 'free_fee'.tr(),
                    style: _kStyle(
                      color: const Color(0xFF3B82F6),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAppointmentCard(
    Appointment appointment,
    int index,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final image = appointment.doctorImagePath != null
        ? ApiClient.getImageUrl(appointment.doctorImagePath!)
        : 'assets/images/doctor1.png';

    final isKurdish =
        context.locale.languageCode == 'ckb' ||
        context.locale.languageCode == 'ku';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailsScreen(
                doctorId: appointment.doctorId,
                name: appointment.doctorName,
                specialty: appointment.doctorSpecialty,
                image: image,
              ),
            ),
          );
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
              // Doctor Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 50,
                  height: 50,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  child: appointment.doctorImagePath != null
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Iconsax.user,
                                color: Color(0xFF3B82F6),
                                size: 26,
                              ),
                        )
                      : Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Iconsax.user,
                                color: Color(0xFF3B82F6),
                                size: 26,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appointment.doctorSpecialty,
                      style: _kStyle(
                        color: const Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.formattedDateTime,
                          style: _kStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Status and Fee
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(
                    label: isKurdish
                        ? appointment.status.kurdiName
                        : appointment.status.displayName,
                    color: appointment.status.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.formattedFee,
                    style: _kStyle(
                      color: const Color(0xFF3B82F6),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: _kStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark, required bool isFiltered}) {
    String emptyTitle;
    String emptyDesc;

    if (isFiltered) {
      emptyTitle = 'no_orders_in_filter'.tr();
      emptyDesc = 'no_orders_in_filter'.tr();
    } else if (widget.fixedCategory == 'lab') {
      emptyTitle = 'no_lab_history'.tr();
      emptyDesc = 'no_lab_history_desc'.tr();
    } else if (widget.fixedCategory == 'nursing') {
      emptyTitle = 'no_nursing_orders'.tr();
      emptyDesc = 'no_transactions_desc'.tr();
    } else {
      emptyTitle = 'no_appointments'.tr();
      emptyDesc = 'no_transactions_desc'.tr();
    }

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () async => refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          widget.fixedCategory == 'lab'
                              ? Iconsax.archive_book
                              : Iconsax.receipt_2_1,
                          size: 38,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      emptyTitle,
                      textAlign: TextAlign.center,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyDesc,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  final DateTime date;
  final OrderModel? order;
  final Appointment? appointment;

  _HistoryItem.order(OrderModel o)
    : date = o.date,
      order = o,
      appointment = null;

  _HistoryItem.appointment(Appointment a)
    : date = a.appointmentDate,
      order = null,
      appointment = a;
}

class _HistoryCategoryOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _HistoryCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });
}

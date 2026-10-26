import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/admin_order_provider.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/currency.dart';
import '../../core/theme/app_colors.dart';

class AdminOrdersScreen extends StatefulWidget {
  final bool isRoot;
  const AdminOrdersScreen({super.key, this.isRoot = false});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, String> _getSenderInfo(dynamic order) {
    var patientDetails = order['patient_details'];
    if (patientDetails is String) {
      try {
        patientDetails = jsonDecode(patientDetails);
      } catch (_) {}
    }
    if (patientDetails is! Map) {
      patientDetails = {};
    }
    final patient = order['patient'] is Map ? order['patient'] : null;

    final name = (patientDetails['name']?.toString().trim().isNotEmpty == true)
        ? patientDetails['name'].toString().trim()
        : (patient?['name']?.toString().trim().isNotEmpty == true
            ? patient!['name'].toString().trim()
            : 'نەخۆش');

    final phone = (patientDetails['phone']?.toString().trim().isNotEmpty == true)
        ? patientDetails['phone'].toString().trim()
        : (patient?['phone']?.toString().trim().isNotEmpty == true
            ? patient!['phone'].toString().trim()
            : 'بێ ژمارە');

    final age = patientDetails['age']?.toString() ?? '';
    final gender = patientDetails['patient_gender']?.toString() ?? '';
    final notes = patientDetails['notes']?.toString() ?? patientDetails['note']?.toString() ?? '';

    return {
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
      'notes': notes,
    };
  }

  Map<String, dynamic> _getReceiverInfo(dynamic order) {
    final serviceType = (order['service_type'] ?? '').toString().toLowerCase();

    if (serviceType.contains('pharmacy') || serviceType.contains('دەرمان')) {
      final pharmacy = order['assigned_pharmacy'] is Map ? order['assigned_pharmacy'] : null;
      String name = pharmacy?['name']?.toString() ?? '';
      String phone = pharmacy?['phone']?.toString() ?? '';
      if (name.isEmpty) {
        var items = order['items'];
        if (items is String) {
          try {
            items = jsonDecode(items);
          } catch (_) {}
        }
        if (items is List && items.isNotEmpty && items.first is Map) {
          var extra = items.first['extra_data'];
          if (extra is String) {
            try {
              extra = jsonDecode(extra);
            } catch (_) {}
          }
          if (extra is Map && extra['pharmacy_name'] != null) {
            name = extra['pharmacy_name'].toString();
          }
        }
      }
      return {
        'type': 'دەرمانخانە',
        'name': name.isNotEmpty ? name : 'دەرمانخانە',
        'phone': phone,
        'icon': Iconsax.health,
        'color': const Color(0xFF0D9488),
      };
    } else if (serviceType.contains('lab') || serviceType.contains('تاقیگە')) {
      final lab = order['assigned_lab'] is Map ? order['assigned_lab'] : null;
      String name = lab?['name']?.toString() ?? '';
      String phone = lab?['phone']?.toString() ?? '';
      if (name.isEmpty) {
        var items = order['items'];
        if (items is String) {
          try {
            items = jsonDecode(items);
          } catch (_) {}
        }
        if (items is List && items.isNotEmpty && items.first is Map) {
          var extra = items.first['extra_data'];
          if (extra is String) {
            try {
              extra = jsonDecode(extra);
            } catch (_) {}
          }
          if (extra is Map && extra['lab_name'] != null) {
            name = extra['lab_name'].toString();
          }
        }
      }
      return {
        'type': 'تاقیگە',
        'name': name.isNotEmpty ? name : 'تاقیگەی پزیشکی',
        'phone': phone,
        'icon': Iconsax.clipboard_text,
        'color': const Color(0xFF8B5CF6),
      };
    } else {
      final nurse = order['assigned_nurse'] is Map ? order['assigned_nurse'] : null;
      String name = nurse?['name']?.toString() ?? '';
      String phone = nurse?['phone']?.toString() ?? '';
      return {
        'type': 'پەرستاری',
        'name': name.isNotEmpty ? name : 'پەرستاری ماڵەوە',
        'phone': phone,
        'icon': Iconsax.user_tag,
        'color': const Color(0xFF3B82F6),
      };
    }
  }

  Map<String, dynamic> _getStatusBadge(String? status) {
    final s = status?.toLowerCase().trim() ?? '';
    if (s == 'pending' || s == 'new' || s == 'نوێ' || s.contains('چاوەڕوان')) {
      return {
        'text': 'نوێ (چاوەڕوانکراو)',
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'icon': Iconsax.clock,
      };
    } else if (s == 'processing' || s == 'in_progress' || s == 'accepted' || s.contains('جێبەجێ')) {
      return {
        'text': 'لە جێبەجێکردن',
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
        'icon': Iconsax.refresh_2,
      };
    } else if (s == 'approved' || s.contains('پەسەند')) {
      return {
        'text': 'مۆڵەت پێدراو (پەسەندکراو)',
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFECFDF5),
        'icon': Iconsax.tick_circle,
      };
    } else if (s == 'completed' || s == 'delivered' || s == 'done' || s.contains('تەواو')) {
      return {
        'text': 'تەواوبوو',
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFECFDF5),
        'icon': Iconsax.tick_circle,
      };
    } else if (s == 'cancelled' || s == 'rejected' || s.contains('هەڵوەش') || s.contains('ڕەت')) {
      return {
        'text': 'هەڵوەشاوەتەوە',
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEE2E2),
        'icon': Iconsax.close_circle,
      };
    } else {
      return {
        'text': status?.isNotEmpty == true ? status! : 'نادیار',
        'color': const Color(0xFF64748B),
        'bgColor': const Color(0xFFF1F5F9),
        'icon': Iconsax.info_circle,
      };
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$y/$m/$d • $h:$min';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'داواکارییەکان',
        subtitle: 'بینینی هەموو ئۆردەرەکانی نێردراو بۆ خزمەتگوزارەکان',
        icon: Iconsax.document,
        iconColor: const Color(0xFF3B82F6),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        showBackButton: !widget.isRoot,
      ),
      body: Consumer<AdminOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 48, color: Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: const TextStyle(fontFamily: 'Rabar', color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchOrders,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                    child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(color: Colors.white, fontFamily: 'Rabar')),
                  ),
                ],
              ),
            );
          }

          final pendingOrders = provider.orders.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            return st == 'pending' || st == 'new' || st.isEmpty;
          }).toList();

          final processingOrders = provider.orders.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            return st == 'processing' || st == 'accepted' || st == 'in_progress' || st == 'approved';
          }).toList();

          final completedOrders = provider.orders.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            return st == 'completed' || st == 'delivered' || st == 'cancelled' || st == 'done';
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.getTextSubtitle(context),
                    labelStyle: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Text(
                          'نوێ (${pendingOrders.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'لە جێبەجێکردن (${processingOrders.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'تەواوبوو (${completedOrders.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(pendingOrders, provider),
                    _buildOrderList(processingOrders, provider),
                    _buildOrderList(completedOrders, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, AdminOrderProvider provider) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.document_favorite,
                size: 40,
                color: AppColors.getTextSubtitle(context).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هیچ داواکارییەک نییە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                color: AppColors.getTextSubtitle(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchOrders,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 60 * index))
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final sender = _getSenderInfo(order);
    final receiver = _getReceiverInfo(order);
    final statusInfo = _getStatusBadge(order['status']?.toString());
    final totalPrice = order['total_price'] ?? 0;
    final dateStr = _formatDate(order['created_at']?.toString());

    var items = order['items'];
    if (items is String) {
      try {
        items = jsonDecode(items);
      } catch (_) {}
    }
    final itemCount = (items is List) ? items.length : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOrderDetailsModal(order),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${order['id']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: AppColors.getTextSubtitle(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusInfo['icon'] as IconData, size: 13, color: statusInfo['color'] as Color),
                          const SizedBox(width: 5),
                          Text(
                            statusInfo['text'] as String,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusInfo['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── WHO SENT TO WHOM (کێ بۆ کێی ناردووە) ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context).withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    children: [
                      // Sender (نەخۆش)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Iconsax.user, size: 14, color: Color(0xFF3B82F6)),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'نێرەر (نەخۆش)',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sender['name'] ?? 'نەخۆش',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextTitle(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              sender['phone'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppColors.getTextSubtitle(context),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),

                      // Arrow connector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),

                      // Receiver (وەرگر / خزمەتگوزار)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (receiver['color'] as Color).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(receiver['icon'] as IconData, size: 14, color: receiver['color'] as Color),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'بۆ: ${receiver['type']}',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11,
                                    color: receiver['color'] as Color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              receiver['name'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextTitle(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              receiver['phone']?.toString().isNotEmpty == true
                                  ? receiver['phone'].toString()
                                  : receiver['type'].toString(),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11.5,
                                color: AppColors.getTextSubtitle(context),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom summary & View Details button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.box_1, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                '$itemCount بڕگە',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Currency.format(num.tryParse('$totalPrice') ?? 0),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _showOrderDetailsModal(order),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'وردەکارییەکان',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF3B82F6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsModal(dynamic order) {
    try {
      final sender = _getSenderInfo(order);
      final receiver = _getReceiverInfo(order);
      final statusInfo = _getStatusBadge(order['status']?.toString());
      final num totalPrice = num.tryParse('${order['total_price']}') ?? 0;
      final num extraFee = num.tryParse('${order['extra_fee']}') ?? 0;
      final num subtotal = num.tryParse('${order['subtotal']}') ?? (totalPrice - extraFee);
      final paymentMethod = (order['payment_method'] ?? 'کاش لەکاتی وەرگرتن').toString();
      final dateStr = _formatDate(order['created_at']?.toString());

      var locationDetails = order['location_details'];
      if (locationDetails is String) {
        try {
          locationDetails = jsonDecode(locationDetails);
        } catch (_) {}
      }
      if (locationDetails is! Map) {
        locationDetails = {};
      }

      var patientDetails = order['patient_details'];
      if (patientDetails is String) {
        try {
          patientDetails = jsonDecode(patientDetails);
        } catch (_) {}
      }
      if (patientDetails is! Map) {
        patientDetails = {};
      }

      final address = (locationDetails['address'] ??
              locationDetails['address_text'] ??
              patientDetails['location'] ??
              patientDetails['address'] ??
              order['address'] ??
              'ناونیشان دیاری نەکراوە')
          .toString();

      final double? lat = locationDetails['lat'] != null
          ? double.tryParse(locationDetails['lat'].toString())
          : (locationDetails['latitude'] != null ? double.tryParse(locationDetails['latitude'].toString()) : null);
      final double? lng = locationDetails['lng'] != null
          ? double.tryParse(locationDetails['lng'].toString())
          : (locationDetails['longitude'] != null ? double.tryParse(locationDetails['longitude'].toString()) : null);

      var items = order['items'];
      if (items is String) {
        try {
          items = jsonDecode(items);
        } catch (_) {}
      }
      if (items is! List) {
        items = [];
      }

      String? prescriptionImage = patientDetails['prescription_image']?.toString() ??
          patientDetails['prescription_url']?.toString() ??
          order['prescription_image']?.toString() ??
          order['prescription_url']?.toString();

      if (prescriptionImage == null || prescriptionImage.isEmpty) {
        for (final it in items) {
          if (it is Map && it['extra_data'] is Map) {
            final extra = it['extra_data'] as Map;
            final p = extra['prescription_url'] ?? extra['prescription_image'] ?? extra['prescription_path'];
            if (p != null && p.toString().isNotEmpty) {
              prescriptionImage = p.toString();
              break;
            }
          }
        }
      }

      final orderId = order['id'];
      final rawStatus = (order['status'] ?? '').toString().toLowerCase();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Header indicator
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.receipt_2, color: Color(0xFF3B82F6), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'وردەکاری داواکاری #$orderId',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextTitle(context),
                                ),
                              ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    color: AppColors.getTextSubtitle(context),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Status row
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (statusInfo['bgColor'] as Color?) ?? const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (statusInfo['icon'] as IconData?) ?? Iconsax.info_circle,
                              color: (statusInfo['color'] as Color?) ?? const Color(0xFF3B82F6),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'دۆخی داواکاری: ${statusInfo['text'] ?? ''}',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: (statusInfo['color'] as Color?) ?? const Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 1. Sender Box (Patient)
                      _buildSectionHeader('زانیاری نێرەر (نەخۆش)', Iconsax.user),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('ناوی تەواو', sender['name'] ?? 'نەخۆش'),
                            const Divider(height: 16),
                            _buildContactRow('ژمارەی مۆبایل', sender['phone'] ?? 'دیاری نەکراوە'),
                            if (sender['age']?.isNotEmpty == true) ...[
                              const Divider(height: 16),
                              _buildInfoRow('تەمەن', '${sender['age']} ساڵ'),
                            ],
                            if (sender['gender']?.isNotEmpty == true) ...[
                              const Divider(height: 16),
                              _buildInfoRow('ڕەگەز', sender['gender'] == 'male' ? 'نێر' : 'مێ'),
                            ],
                            if (sender['notes']?.isNotEmpty == true) ...[
                              const Divider(height: 16),
                              _buildInfoRow('تێبینی نەخۆش', sender['notes']!),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Receiver Box (Provider)
                      _buildSectionHeader('زانیاری وەرگر (${receiver['type'] ?? ''})', (receiver['icon'] as IconData?) ?? Iconsax.hospital),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('جۆری خزمەتگوزاری', receiver['type']?.toString() ?? ''),
                            const Divider(height: 16),
                            _buildInfoRow('ناوی دابینکەر', receiver['name']?.toString() ?? ''),
                            if (receiver['phone']?.toString().isNotEmpty == true) ...[
                              const Divider(height: 16),
                              _buildContactRow('ژمارەی پەیوەندی', receiver['phone'].toString()),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Items List
                      _buildSectionHeader('بڕگەکان / خزمەتگوزارییە داواکراوەکان', Iconsax.box),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: const Text('هیچ بڕگەیەک تۆمار نەکراوە', style: TextStyle(fontFamily: 'Rabar')),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final itm = items[idx];
                              final itmMap = itm is Map ? itm : <String, dynamic>{};
                              final itmName = itmMap['item_name'] ?? itmMap['name'] ?? 'بڕگە';
                              final itmPrice = num.tryParse('${itmMap['price']}') ?? 0;
                              final itmQty = num.tryParse('${itmMap['quantity']}') ?? 1;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itmName.toString(),
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.getTextTitle(context),
                                            ),
                                          ),
                                          if (itmQty > 1)
                                            Text(
                                              'ژمارە: $itmQty',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                color: AppColors.getTextSubtitle(context),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      Currency.format(itmPrice),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      if (prescriptionImage != null && prescriptionImage.toString().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('وێنەی ڕەچەتەی پزیشکی', Iconsax.document_upload),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  prescriptionImage.toString().startsWith('http')
                                      ? prescriptionImage.toString()
                                      : '${ApiClient.baseUrl}/${prescriptionImage.toString().replaceAll(RegExp(r'^/+'), '')}',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: const Text('نەتوانرا وێنەی ڕەچەتە پیشان بدرێت', style: TextStyle(fontFamily: 'Rabar')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // 4. Location & Address
                      _buildSectionHeader('ناونیشان و شوێن', Iconsax.location),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Iconsax.location, size: 20, color: Color(0xFF3B82F6)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextTitle(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (lat != null && lng != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Iconsax.map_1, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'شوێنی دیاریکراو لەسەر نەخشە',
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _launchUrlSafe('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
                                      icon: const Icon(Icons.open_in_new, size: 14),
                                      label: const Text(
                                        'نەخشە',
                                        style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Payment Summary
                      _buildSectionHeader('کورتەی پارەدان', Iconsax.wallet_3),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('شێوازی پارەدان', paymentMethod),
                            if (subtotal > 0 && subtotal != totalPrice) ...[
                              const Divider(height: 16),
                              _buildInfoRow('نرخی سەرەتایی', Currency.format(subtotal)),
                            ],
                            if (extraFee > 0) ...[
                              const Divider(height: 16),
                              _buildInfoRow('کرێی گەیاندن / خزمەتگوزاری', Currency.format(extraFee)),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'کۆی گشتی',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  Currency.format(totalPrice),
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 6. Action Controls for Admin
                      if (orderId is int) ...[
                        Row(
                          children: [
                            if (rawStatus == 'pending') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final ok = await context.read<AdminOrderProvider>().updateStatus(orderId, 'processing');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok ? 'داواکاری پەسەندکرا و گوازرایەوە بۆ جێبەجێکردن' : 'نەتوانرا دۆخ نوێ بکرێتەوە',
                                            style: const TextStyle(fontFamily: 'Rabar'),
                                          ),
                                          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                  label: const Text('پەسەندکردن', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (rawStatus == 'processing' || rawStatus == 'accepted' || rawStatus == 'in_progress') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final ok = await context.read<AdminOrderProvider>().updateStatus(orderId, 'completed');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok ? 'داواکاری بە سەرکەوتوویی تەواو کرا' : 'نەتوانرا دۆخ نوێ بکرێتەوە',
                                            style: const TextStyle(fontFamily: 'Rabar'),
                                          ),
                                          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.done_all_rounded, size: 18),
                                  label: const Text('تەواوکردن', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (rawStatus != 'cancelled' && rawStatus != 'completed')
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final ok = await context.read<AdminOrderProvider>().updateStatus(orderId, 'cancelled');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok ? 'داواکاری هەڵوەشێندرایەوە' : 'نەتوانرا دۆخ نوێ بکرێتەوە',
                                            style: const TextStyle(fontFamily: 'Rabar'),
                                          ),
                                          backgroundColor: ok ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: const Text('ڕەتکردنەوە', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('Error showing order details modal: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('کێشەیەک ڕوویدا لە پیشاندانی وردەکارییەکان: $e', style: const TextStyle(fontFamily: 'Rabar')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextTitle(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 13,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextTitle(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(String label, String phone) {
    final hasPhone = phone.isNotEmpty && phone != 'دیاری نەکراوە' && phone != 'بێ ژمارە';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 13,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
        Row(
          children: [
            Text(
              phone,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextTitle(context),
              ),
            ),
            if (hasPhone) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _launchUrlSafe('tel:$phone'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _launchUrlSafe(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
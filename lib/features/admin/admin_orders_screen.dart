import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/admin_order_provider.dart';
import 'admin_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

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
      final provider = context.read<AdminOrderProvider>();
      provider.fetchOrders();
      provider.fetchNurses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AdminAppBar(
        title: 'داواکارییەکان',
        subtitle: 'بەڕێوەبردنی ئۆردەرەکانی نەخۆش',
        icon: Iconsax.document,
        iconColor: const Color(0xFF3B82F6),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        showBackButton: true,
      ),
      body: Consumer<AdminOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return Center(child: Text(provider.error!));
          }

          final pendingOrders = provider.orders
              .where((o) => o['status'] == 'pending')
              .toList();
          final processingOrders = provider.orders
              .where((o) => o['status'] == 'processing')
              .toList();
          final completedOrders = provider.orders
              .where(
                (o) => o['status'] == 'completed' || o['status'] == 'cancelled',
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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
                          textAlign: TextAlign.center,
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
                    _buildOrderList(pendingOrders, provider, isPending: true),
                    _buildOrderList(
                      processingOrders,
                      provider,
                      isPending: false,
                    ),
                    _buildOrderList(
                      completedOrders,
                      provider,
                      isPending: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
    List<dynamic> orders,
    AdminOrderProvider provider, {
    required bool isPending,
  }) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'هیچ داواکارییەک نییە',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 16,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, provider, isPending)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildOrderCard(
    dynamic order,
    AdminOrderProvider provider,
    bool isPending,
  ) {
    final serviceType = order['service_type'] ?? 'Unknown';

    var patientDetails = order['patient_details'];
    if (patientDetails is String) {
      try {
        patientDetails = jsonDecode(patientDetails);
      } catch (_) {}
    }
    if (patientDetails is! Map) {
      patientDetails = {};
    }
    final patientName = patientDetails['name'] ?? 'نەخۆش';

    var locationDetails = order['location_details'];
    if (locationDetails is String) {
      try {
        locationDetails = jsonDecode(locationDetails);
      } catch (_) {}
    }
    if (locationDetails is! Map) {
      locationDetails = {};
    }
    final address = locationDetails['address'] ?? 'ناونیشان نەزانراوە';

    final totalPrice = order['total_price'] ?? 0;

    var items = order['items'];
    if (items is String) {
      try {
        items = jsonDecode(items);
      } catch (_) {}
    }
    if (items is! List) {
      items = [];
    }

    final double? lat = locationDetails['lat'] != null ? double.tryParse(locationDetails['lat'].toString()) : null;
    final double? lng = locationDetails['lng'] != null ? double.tryParse(locationDetails['lng'].toString()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.user,
                      color: Color(0xFF3B82F6),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$$totalPrice',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          serviceType,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Iconsax.location,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                if (lat != null && lng != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: IgnorePointer(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('patient_location'),
                              position: LatLng(lat, lng),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Iconsax.map_1, size: 18, color: Color(0xFF3B82F6)),
                        SizedBox(width: 6),
                        Text(
                          'کردنەوە لە گۆگڵ ماپ',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (items.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'خزمەتگوزارییەکان',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map<Widget>((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.verify,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item['item_name'] ?? item['name'] ?? ''}',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Action Button
          if (isPending || order['status'] == 'processing') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isPending) {
                      _showAssignDialog(context, order, provider);
                    } else {
                      provider.updateStatus(order['id'], 'completed');
                    }
                  },
                  icon: Icon(
                    isPending ? Iconsax.user_add : Iconsax.tick_circle,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: Text(
                    isPending ? 'دیاریکردنی پەرستار' : 'تەواوکردن',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignDialog(
    BuildContext context,
    dynamic order,
    AdminOrderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'دیاریکردنی پەرستار',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: provider.nurses.isEmpty
                ? const Text(
                    'هیچ پەرستارێک نەدۆزرایەوە',
                    style: TextStyle(fontFamily: 'Rabar'),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.nurses.length,
                      itemBuilder: (context, index) {
                        final nurse = provider.nurses[index];
                        return ListTile(
                          title: Text(
                            nurse['name'] ?? '',
                            style: const TextStyle(fontFamily: 'Rabar'),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await provider.assignNurse(
                              order['id'],
                              nurse['id'],
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'پەرستار بەسەرکەوتوویی دیاریکرا',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'داخستن',
                  style: TextStyle(fontFamily: 'Rabar', color: Colors.grey),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}

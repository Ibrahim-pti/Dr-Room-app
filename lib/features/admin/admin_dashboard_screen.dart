import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'admin_notifications_screen.dart';
import 'admin_app_bar.dart';
import 'admin_labs_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_xrays_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_orders_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (_stats == null) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await ApiClient.get('/admin/dashboard');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AdminAppBar(
        title: 'Dr Room',
        titleWidget: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: 'Dr ',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  letterSpacing: -1.2,
                ),
              ),
              TextSpan(
                text: 'Room',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
        imagePath: 'assets/images/app_icon.png',
        iconColor: Colors.white,
        iconBackgroundColor: Colors.transparent,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: AdminNotificationsScreen(),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.notification,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                _buildLoadingShimmer()
              else ...[
                // ── Stats Grid ──
                _buildStatsGrid(),
                const SizedBox(height: 28),
                // ── Services Grid ──
                _buildServicesGrid(),
                const SizedBox(height: 28),

                // ── Recent Appointments ──
                _buildRecentAppointments(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {
        'title': 'تاقیگەکان',
        'subtitle': 'بینین و قبوڵکردنی تاقیگەکان',
        'icon': Iconsax.microscope,
        'color': const Color(0xFF8B5CF6),
        'screen': const AdminLabsScreen(),
      },
      {
        'title': 'دەرمانخانەکان',
        'subtitle': 'بەڕێوەبردنی دەرمانخانەکانی ئەپ',
        'icon': Iconsax.reserve,
        'color': const Color(0xFFF59E0B),
        'screen': const AdminPharmaciesScreen(),
      },
      {
        'title': 'تیشک و سۆنەر',
        'subtitle': 'سەنتەرەکانی تیشک و سۆنەر',
        'icon': Iconsax.scan,
        'color': const Color(0xFF10B981),
        'screen': const AdminXRaysScreen(),
      },
      {
        'title': 'داواکارییەکان',
        'subtitle': 'بینین و ناردنی ئۆردەرەکان',
        'icon': Iconsax.document,
        'color': const Color(0xFF3B82F6),
        'screen': const AdminOrdersScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خزمەتگوزارییەکان',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ...services.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;
          final color = service['color'] as Color;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: service['screen'] as Widget,
                  ),
                ),
              );
            },
            child:
                Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              service['icon'] as IconData,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service['subtitle'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFFCBD5E1),
                            size: 16,
                          ),
                        ],
                      ),
                    )
                    .animate(delay: Duration(milliseconds: index * 100))
                    .fadeIn()
                    .slideX(begin: 0.05, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Highlight Card (Banners)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Directionality(
                  textDirection: TextDirection.rtl,
                  child: AdminBannersScreen(),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ڕیکلامەکان',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'بەڕێوەبردنی بانەرەکانی ئەپ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Iconsax.picture_frame,
                    color: Color(0xFF3B82F6),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 20),
        // Secondary Horizontal List
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              _buildSmallStatCard(
                label: 'کۆی بەکارهێنەران',
                value: '${_stats?['total_users'] ?? 0}',
                icon: Iconsax.people,
                color: const Color(0xFF3B82F6),
                delay: 100,
              ),
              const SizedBox(width: 12),
              _buildSmallStatCard(
                label: 'پزیشکی چاوەڕێکراو',
                value: '${_stats?['pending_doctors'] ?? 0}',
                icon: Iconsax.user_search,
                color: const Color(0xFFF59E0B),
                delay: 150,
              ),
              const SizedBox(width: 12),
              _buildSmallStatCard(
                label: 'پەرستارەکان',
                value: '${_stats?['total_nurses'] ?? 0}',
                icon: Iconsax.profile_2user,
                color: const Color(0xFFEC4899),
                delay: 200,
              ),
              const SizedBox(width: 12),
              _buildSmallStatCard(
                label: 'چاوپێکەوتن',
                value: '${_stats?['total_appointments'] ?? 0}',
                icon: Iconsax.calendar_1,
                color: const Color(0xFF10B981),
                delay: 250,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF1E293B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildRecentAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دوایین چاوپێکەوتنەکان',
          style: TextStyle(
            fontFamily: 'Rabar',
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 400.ms).fadeIn(),
        const SizedBox(height: 14),

        if (_stats?['recent_appointments'] != null &&
            (_stats!['recent_appointments'] as List).isNotEmpty)
          ...((_stats!['recent_appointments'] as List).asMap().entries.map(
            (entry) => _buildAppointmentRow(entry.value, entry.key),
          ))
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.calendar_remove,
                  color: const Color(0xFFCBD5E1),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'هیچ چاوپێکەوتنێک نییە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),
      ],
    );
  }

  Widget _buildAppointmentRow(dynamic appt, int index) {
    final userName = appt['user']?['name'] ?? 'بەکارهێنەر';
    final doctorName =
        (appt['doctor'] != null && appt['doctor']['user'] != null)
        ? appt['doctor']['user']['name']
        : 'پزیشک';
    final status = appt['status'] ?? 'pending';
    final statusColor = status == 'completed'
        ? const Color(0xFF10B981)
        : status == 'cancelled'
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.calendar_1,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: const Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'د. $doctorName',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'completed'
                      ? 'تەواو'
                      : status == 'cancelled'
                      ? 'هەڵوەشێنراو'
                      : 'چاوەڕێ',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 400 + (index * 80)))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(
        4,
        (i) =>
            Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}

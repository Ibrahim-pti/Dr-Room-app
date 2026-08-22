import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'admin_notifications_screen.dart';
import 'admin_app_bar.dart';
import 'admin_doctors_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_users_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_labs_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_orders_screen.dart';
import '../home/main_shell.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'Dr Room',
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
                children: const [
                  TextSpan(
                    text: 'Dr ',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  TextSpan(
                    text: 'Room',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ئەدمین',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
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
                  builder: (context) => const MainShell(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Iconsax.mobile,
                    color: Color(0xFF475569),
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ئەپی نەخۆش',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.notification,
                color: Color(0xFF0F172A),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                _buildLoadingShimmer()
              else ...[
                // ── 1. Hero Overview Banner ──
                _buildHeroBanner(),
                const SizedBox(height: 20),

                // ── 2. Quick Key Stats (2x2 Grid) ──
                _buildStatsCards(),
                const SizedBox(height: 24),

                // ── 3. Core Management (6 Main Sections) ──
                _buildCoreServicesGrid(),
                const SizedBox(height: 20),

                // ── 4. Quick Tools (Banners & Push) ──
                _buildQuickTools(),
                const SizedBox(height: 24),

                // ── 5. Recent Appointments ──
                _buildRecentAppointments(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Hero Overview Banner ──
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'سیستەم چالاکە',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'بەخێربێیت، ئەدمین!',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'کۆنتڕۆڵ و چاودێری تەواوی خزمەتگوزارییەکان',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Icon(
              Iconsax.shield_tick,
              color: Color(0xFF60A5FA),
              size: 32,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }

  // ── 2. Quick Key Stats (2x2 Grid) ──
  Widget _buildStatsCards() {
    final totalUsers = '${_stats?['total_users'] ?? 0}';
    final pendingDoctors = _stats?['pending_doctors'] ?? 0;
    final totalOrders = '${_stats?['total_orders'] ?? _stats?['pending_orders'] ?? 0}';
    final totalStaff = '${(_stats?['total_nurses'] ?? 0) + (_stats?['total_labs'] ?? 0) + (_stats?['total_pharmacies'] ?? 0)}';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        // Total Users
        _buildStatTile(
          title: 'بەکارهێنەران',
          value: totalUsers,
          icon: Iconsax.people,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
          onTap: () => _openScreen(const AdminUsersScreen()),
        ),

        // Pending Doctors
        _buildStatTile(
          title: 'پزیشکانی نوێ',
          value: '$pendingDoctors',
          icon: Iconsax.user_add,
          color: pendingDoctors > 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          bg: pendingDoctors > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
          badge: pendingDoctors > 0 ? 'پەسەندکردن' : null,
          onTap: () => _openScreen(const AdminDoctorsScreen()),
        ),

        // Orders
        _buildStatTile(
          title: 'داواکارییەکان',
          value: totalOrders,
          icon: Iconsax.document_text,
          color: const Color(0xFF0D9488),
          bg: const Color(0xFFF0FDF4),
          onTap: () => _openScreen(const AdminOrdersScreen()),
        ),

        // Total Staff & Centers
        _buildStatTile(
          title: 'ستاف و سەنتەرەکان',
          value: totalStaff,
          icon: Iconsax.hospital,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
          onTap: () => _openScreen(const AdminAppointmentsScreen()),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
    String? badge,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1));
  }

  // ── 3. Core Management Grid ──
  Widget _buildCoreServicesGrid() {
    final coreServices = [
      {
        'title': 'پزیشکەکان',
        'desc': 'پەسەندکردن و بەڕێوەبردن',
        'icon': Iconsax.health,
        'color': const Color(0xFF2563EB),
        'screen': const AdminDoctorsScreen(),
      },
      {
        'title': 'دەرمانخانەکان',
        'desc': 'دەرمان و کۆگاکان',
        'icon': Iconsax.reserve,
        'color': const Color(0xFF0D9488),
        'screen': const AdminPharmaciesScreen(),
      },
      {
        'title': 'تاقیگەکان',
        'desc': 'تاقیگە و پشکنینەکان',
        'icon': Iconsax.microscope,
        'color': const Color(0xFF8B5CF6),
        'screen': const AdminLabsScreen(),
      },
      {
        'title': 'پەرستارەکان',
        'desc': 'خزمەتگوزاری ماڵەوە',
        'icon': Iconsax.profile_2user,
        'color': const Color(0xFFEC4899),
        'screen': const AdminNursesScreen(),
      },
      {
        'title': 'داواکارییەکان',
        'desc': 'ئۆردەری نەخۆشەکان',
        'icon': Iconsax.box,
        'color': const Color(0xFFF59E0B),
        'screen': const AdminOrdersScreen(),
      },
      {
        'title': 'بەکارهێنەران',
        'desc': 'نەخۆش و هەژمارەکان',
        'icon': Iconsax.people,
        'color': const Color(0xFF0284C7),
        'screen': const AdminUsersScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بەڕێوەبردنی ستاف و بەشەکان',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coreServices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final service = coreServices[index];
            final color = service['color'] as Color;

            return GestureDetector(
              onTap: () => _openScreen(service['screen'] as Widget),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            service['icon'] as IconData,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 13,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          service['desc'] as String,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: index * 30)).fadeIn();
          },
        ),
      ],
    );
  }

  // ── 4. Quick Tools (Banners & Push Notification) ──
  Widget _buildQuickTools() {
    return Row(
      children: [
        // Banners
        Expanded(
          child: GestureDetector(
            onTap: () => _openScreen(const AdminBannersScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.picture_frame,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'بانەرەکان',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ڕیکلامی ناو ئەپ',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Broadcast Notification
        Expanded(
          child: GestureDetector(
            onTap: () => _openScreen(const AdminNotificationsScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.notification_bing,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ئاگاداری گشتی',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ناردنی نۆتیفیکەیشن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Recent Appointments ──
  Widget _buildRecentAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'دوایین چاوپێکەوتنەکان',
              style: TextStyle(
                fontFamily: 'Rabar',
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () => _openScreen(const AdminAppointmentsScreen()),
              child: const Text(
                'هەمووی ببینە',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_stats?['recent_appointments'] != null &&
            (_stats!['recent_appointments'] as List).isNotEmpty)
          ...((_stats!['recent_appointments'] as List).take(4).map(
            (appt) => _buildAppointmentRow(appt),
          ))
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(
                  Iconsax.calendar_1,
                  color: Color(0xFFCBD5E1),
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'هیچ چاوپێکەوتنێک تۆمار نەکراوە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentRow(dynamic appt) {
    final userName = appt['patient']?['name'] ?? appt['user']?['name'] ?? 'بەکارهێنەر';
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.calendar_1,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'د. $doctorName',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: screen,
        ),
      ),
    );
  }
}

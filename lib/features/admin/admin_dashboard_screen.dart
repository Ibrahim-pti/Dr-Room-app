import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import '../home/main_shell.dart';
import 'admin_app_bar.dart';
import 'admin_appointments_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_labs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_users_screen.dart';
import 'admin_xrays_screen.dart';

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

  int get _totalPendingItems {
    if (_stats == null) return 0;
    final int pendingDoctors = (_stats?['pending_doctors'] ?? 0) as int;
    final int pendingNurses = (_stats?['pending_nurses'] ?? 0) as int;
    final int pendingLabs = (_stats?['pending_labs'] ?? 0) as int;
    final int pendingPharmacies = (_stats?['pending_pharmacies'] ?? 0) as int;
    final int pendingOrders = (_stats?['pending_orders'] ?? 0) as int;
    return pendingDoctors + pendingNurses + pendingLabs + pendingPharmacies + pendingOrders;
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
            onTap: () => _openScreen(const AdminNotificationsScreen()),
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                _buildLoadingShimmer()
              else ...[
                // 1. Sleek Hero Overview
                _buildHeroBanner(),
                const SizedBox(height: 16),

                // 2. Pending Approval Alert (if any)
                if (_totalPendingItems > 0) ...[
                  _buildPendingNoticeCard(),
                  const SizedBox(height: 16),
                ],

                // 3. Key Metrics (2x2 Grid)
                _buildStatsCards(),
                const SizedBox(height: 24),

                // 4. Main Health Hub & Services (8 Services)
                _buildCoreServicesGrid(),
                const SizedBox(height: 24),

                // 5. Quick Admin Tools (Banners, Push, Finance, Reviews)
                _buildQuickTools(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Hero Overview Banner ──
  Widget _buildHeroBanner() {
    final int totalDoctors = (_stats?['total_doctors'] ?? 0) as int;
    final int totalNurses = (_stats?['total_nurses'] ?? 0) as int;
    final int totalLabs = (_stats?['total_labs'] ?? 0) as int;
    final int totalPharmacies = (_stats?['total_pharmacies'] ?? 0) as int;
    final int totalMedicalStaff = totalDoctors + totalNurses + totalLabs + totalPharmacies;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'سیستەم چالاکە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'کۆنترۆڵ پەنێڵ',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'بەخێربێیت بۆ بەڕێوەبەرایەتی دکتۆر ڕووم',
            style: TextStyle(
              fontFamily: 'Rabar',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'کۆی گشتی $totalMedicalStaff پزیشک و ناوەندی پزیشکی بەستراونەتەوە بە ئەپەکە.',
            style: const TextStyle(
              fontFamily: 'Rabar',
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.06, end: 0);
  }

  // ── 2. Pending Notice Alert ──
  Widget _buildPendingNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.warning_2,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'داواکاری نوێ بۆ پەسەندکردن',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalPendingItems داواکاری پێویستیان بە پێداچوونەوە و پەسەندکردنە',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF92400E),
            size: 14,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  // ── 3. Key Stats (2x2 Grid) ──
  Widget _buildStatsCards() {
    final totalUsers = '${_stats?['total_users'] ?? 0}';
    final totalDoctors = '${_stats?['total_doctors'] ?? 0}';
    final totalOrders = '${_stats?['total_orders'] ?? 0}';
    final totalAppointments = '${_stats?['total_appointments'] ?? 0}';

    final int pendingDocs = (_stats?['pending_doctors'] ?? 0) as int;
    final int pendingOrds = (_stats?['pending_orders'] ?? 0) as int;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatTile(
          title: 'بەکارهێنەران',
          value: totalUsers,
          subtitle: 'نەخۆشە تۆمارکراوەکان',
          icon: Iconsax.people,
          color: const Color(0xFF0284C7),
          bg: const Color(0xFFF0F9FF),
          onTap: () => _openScreen(const AdminUsersScreen()),
        ),
        _buildStatTile(
          title: 'پزیشکەکان',
          value: totalDoctors,
          subtitle: 'تەواوی پزیشکەکان',
          icon: Iconsax.health,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
          badge: pendingDocs > 0 ? '$pendingDocs چاوەڕوان' : null,
          onTap: () => _openScreen(const AdminDoctorsScreen()),
        ),
        _buildStatTile(
          title: 'داواکارییەکان',
          value: totalOrders,
          subtitle: 'ئۆردەری خزمەتگوزاری',
          icon: Iconsax.box,
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFFBEB),
          badge: pendingOrds > 0 ? '$pendingOrds نوێ' : null,
          onTap: () => _openScreen(const AdminOrdersScreen()),
        ),
        _buildStatTile(
          title: 'چاوپێکەوتنەکان',
          value: totalAppointments,
          subtitle: 'نۆرە تۆمارکراوەکان',
          icon: Iconsax.calendar_1,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
          onTap: () => _openScreen(const AdminAppointmentsScreen()),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. Main Health Hub & Services Grid ──
  Widget _buildCoreServicesGrid() {
    final int pendingDocs = (_stats?['pending_doctors'] ?? 0) as int;
    final int pendingNurses = (_stats?['pending_nurses'] ?? 0) as int;
    final int pendingLabs = (_stats?['pending_labs'] ?? 0) as int;
    final int pendingPharmacies = (_stats?['pending_pharmacies'] ?? 0) as int;
    final int pendingOrders = (_stats?['pending_orders'] ?? 0) as int;

    final List<Map<String, dynamic>> services = [
      {
        'title': 'پزیشکەکان',
        'desc': 'پەسەندکردن و بەڕێوەبردن',
        'icon': Iconsax.health,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'badge': pendingDocs > 0 ? '$pendingDocs چاوەڕوان' : null,
        'screen': const AdminDoctorsScreen(),
      },
      {
        'title': 'پەرستارەکان',
        'desc': 'خزمەتگوزاری ماڵەوە',
        'icon': Iconsax.profile_2user,
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'badge': pendingNurses > 0 ? '$pendingNurses نوێ' : null,
        'screen': const AdminNursesScreen(),
      },
      {
        'title': 'سەنتەری تیشک',
        'desc': 'تیشک، سۆنەر و MRI',
        'icon': Iconsax.scan,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'screen': const AdminXRaysScreen(),
      },
      {
        'title': 'تاقیگەکان',
        'desc': 'تاقیگە و پشکنینەکان',
        'icon': Iconsax.microscope,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'badge': pendingLabs > 0 ? '$pendingLabs نوێ' : null,
        'screen': const AdminLabsScreen(),
      },
      {
        'title': 'دەرمانخانەکان',
        'desc': 'دەرمان و کۆگاکان',
        'icon': Iconsax.reserve,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
        'badge': pendingPharmacies > 0 ? '$pendingPharmacies نوێ' : null,
        'screen': const AdminPharmaciesScreen(),
      },
      {
        'title': 'داواکارییەکان',
        'desc': 'ئۆردەری نەخۆشەکان',
        'icon': Iconsax.box,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'badge': pendingOrders > 0 ? '$pendingOrders نوێ' : null,
        'screen': const AdminOrdersScreen(),
      },
      {
        'title': 'فریاگوزاری',
        'desc': 'ڕێنمایی و وتارە پزیشکییەکان',
        'icon': Iconsax.firstline,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
        'screen': const AdminArticlesScreen(),
      },
      {
        'title': 'بەکارهێنەران',
        'desc': 'نەخۆش و هەژمارەکان',
        'icon': Iconsax.people,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'screen': const AdminUsersScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بەشە سەرەکییەکان و ناوەندە پزیشکییەکان',
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
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = services[index];
            final color = item['color'] as Color;
            final bg = item['bg'] as Color;
            final badge = item['badge'] as String?;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => _openScreen(item['screen'] as Widget),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
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
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'] as IconData, color: color, size: 20),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['desc'] as String,
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
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  // ── 5. Quick Tools & Management Bar ──
  Widget _buildQuickTools() {
    final List<Map<String, dynamic>> tools = [
      {
        'title': 'بانەرەکان',
        'subtitle': 'ڕیکلام و پۆستەر',
        'icon': Iconsax.slider_horizontal,
        'color': const Color(0xFF6366F1),
        'screen': const AdminBannersScreen(),
      },
      {
        'title': 'ئاگاداری گشتی',
        'subtitle': 'Push Notification',
        'icon': Iconsax.notification_bing,
        'color': const Color(0xFFD97706),
        'screen': const AdminNotificationsScreen(),
      },
      {
        'title': 'داهات و مامەڵە',
        'subtitle': 'تۆماری دارایی',
        'icon': Iconsax.wallet_3,
        'color': const Color(0xFF059669),
        'screen': const AdminTransactionsScreen(),
      },
      {
        'title': 'هەڵسەنگاندن',
        'subtitle': 'کۆمێنتی نەخۆش',
        'icon': Iconsax.star,
        'color': const Color(0xFFE11D48),
        'screen': const AdminReviewsScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ئامرازە خێراکان',
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
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            final color = tool['color'] as Color;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _openScreen(tool['screen'] as Widget),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tool['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tool['title'] as String,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tool['subtitle'] as String,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Skeleton Shimmer Loading ──
  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: List.generate(
            4,
            (index) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: List.generate(
            8,
            (index) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1200.ms,
          color: Colors.grey.withValues(alpha: 0.08),
        );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import '../home/main_shell.dart';
import 'admin_app_bar.dart';
import 'admin_articles_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_labs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_pharmacies_screen.dart';
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

  int get _totalPending {
    if (_stats == null) return 0;
    final int nurses = (_stats?['pending_nurses'] ?? 0) as int;
    final int labs = (_stats?['pending_labs'] ?? 0) as int;
    final int pharms = (_stats?['pending_pharmacies'] ?? 0) as int;
    final int orders = (_stats?['pending_orders'] ?? 0) as int;
    return nurses + labs + pharms + orders;
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
                  fontSize: 20,
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ئەدمین',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 10.5,
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
          IconButton(
            tooltip: 'ئەپی نەخۆش',
            icon: const Icon(Iconsax.mobile, color: Color(0xFF475569), size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainShell()),
              );
            },
          ),
          IconButton(
            tooltip: 'ئاگادارییەکان',
            icon: const Icon(Iconsax.notification, color: Color(0xFF0F172A), size: 20),
            onPressed: () => _openScreen(const AdminNotificationsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                _buildLoadingShimmer()
              else ...[
                // 1. Pending Banner (Slim, only when needed)
                if (_totalPending > 0) ...[
                  _buildSlimPendingAlert(),
                  const SizedBox(height: 12),
                ],

                // 2. Compact 4-Metric Stats Row (Active services: Users, Nurses, Labs, Orders)
                _buildCompactStatsRow(),
                const SizedBox(height: 16),

                // 3. Compact Main Services Grid
                _buildCompactServicesGrid(),
                const SizedBox(height: 14),

                // 4. Quick Direct Action Chips
                _buildQuickActionChips(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Slim Pending Alert ──
  Widget _buildSlimPendingAlert() {
    return GestureDetector(
      onTap: () {
        if ((_stats?['pending_orders'] ?? 0) > 0) {
          _openScreen(const AdminOrdersScreen());
        } else if ((_stats?['pending_nurses'] ?? 0) > 0) {
          _openScreen(const AdminNursesScreen());
        } else if ((_stats?['pending_labs'] ?? 0) > 0) {
          _openScreen(const AdminLabsScreen());
        } else {
          _openScreen(const AdminPharmaciesScreen());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.info_circle, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_totalPending داواکاری چاوەڕوانی پەسەندکردنە',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const Text(
              'پیشاندان',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 11),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  // ── 2. Compact 4-Metric Stats Row (Active Staff & Network) ──
  Widget _buildCompactStatsRow() {
    final totalUsers = '${_stats?['total_users'] ?? 0}';
    final totalNurses = '${_stats?['total_nurses'] ?? 0}';
    final totalLabs = '${_stats?['total_labs'] ?? 0}';
    final totalOrders = '${_stats?['total_orders'] ?? 0}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMiniStatItem(
            title: 'نەخۆش',
            value: totalUsers,
            icon: Iconsax.people,
            color: const Color(0xFF0284C7),
            onTap: () => _openScreen(const AdminUsersScreen()),
          ),
          _buildStatDivider(),
          _buildMiniStatItem(
            title: 'پەرستار',
            value: totalNurses,
            icon: Iconsax.profile_2user,
            color: const Color(0xFFEC4899),
            onTap: () => _openScreen(const AdminNursesScreen()),
          ),
          _buildStatDivider(),
          _buildMiniStatItem(
            title: 'تاقیگە',
            value: totalLabs,
            icon: Iconsax.microscope,
            color: const Color(0xFF8B5CF6),
            onTap: () => _openScreen(const AdminLabsScreen()),
          ),
          _buildStatDivider(),
          _buildMiniStatItem(
            title: 'داواکاری',
            value: totalOrders,
            icon: Iconsax.box,
            color: const Color(0xFFF59E0B),
            onTap: () => _openScreen(const AdminOrdersScreen()),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28,
      width: 1,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildMiniStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Compact Main Services Grid (8 Services) ──
  Widget _buildCompactServicesGrid() {
    final int pendingNurses = (_stats?['pending_nurses'] ?? 0) as int;
    final int pendingLabs = (_stats?['pending_labs'] ?? 0) as int;
    final int pendingPharmacies = (_stats?['pending_pharmacies'] ?? 0) as int;
    final int pendingOrders = (_stats?['pending_orders'] ?? 0) as int;

    final List<Map<String, dynamic>> services = [
      {
        'title': 'پزیشکەکان',
        'icon': Iconsax.health,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'badge': 'بەمزوانە',
        'badgeColor': const Color(0xFF2563EB),
        'isComingSoon': true,
        'screen': const AdminDoctorsScreen(),
      },
      {
        'title': 'پەرستارەکان',
        'icon': Iconsax.profile_2user,
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'badge': pendingNurses > 0 ? '$pendingNurses' : null,
        'screen': const AdminNursesScreen(),
      },
      {
        'title': 'سەنتەری تیشک',
        'icon': Iconsax.scan,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'badge': 'بەمزوانە',
        'badgeColor': const Color(0xFF6366F1),
        'isComingSoon': true,
        'screen': const AdminXRaysScreen(),
      },
      {
        'title': 'تاقیگەکان',
        'icon': Iconsax.microscope,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'badge': pendingLabs > 0 ? '$pendingLabs' : null,
        'screen': const AdminLabsScreen(),
      },
      {
        'title': 'دەرمانخانەکان',
        'icon': Iconsax.reserve,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
        'badge': pendingPharmacies > 0 ? '$pendingPharmacies' : null,
        'screen': const AdminPharmaciesScreen(),
      },
      {
        'title': 'داواکارییەکان',
        'icon': Iconsax.box,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'badge': pendingOrders > 0 ? '$pendingOrders' : null,
        'screen': const AdminOrdersScreen(),
      },
      {
        'title': 'فریاگوزاری',
        'icon': Iconsax.firstline,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
        'badge': null,
        'screen': const AdminArticlesScreen(),
      },
      {
        'title': 'بەکارهێنەران',
        'icon': Iconsax.people,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'badge': null,
        'screen': const AdminUsersScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final item = services[index];
        final color = item['color'] as Color;
        final bg = item['bg'] as Color;
        final badge = item['badge'] as String?;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              if (item['isComingSoon'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'خزمەتگوزاری ${item['title']} بەمزوانە بەردەست دەبێت',
                      style: const TextStyle(fontFamily: 'Rabar'),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              _openScreen(item['screen'] as Widget);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item['isComingSoon'] == true
                            ? (item['badgeColor'] as Color? ?? const Color(0xFF6366F1)).withValues(alpha: 0.12)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: item['isComingSoon'] == true ? 9.5 : 10,
                          fontWeight: FontWeight.bold,
                          color: item['isComingSoon'] == true
                              ? (item['badgeColor'] as Color? ?? const Color(0xFF6366F1))
                              : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.04, end: 0);
  }

  // ── 4. Quick Direct Action Chips ──
  Widget _buildQuickActionChips() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'بانەرەکان',
        'icon': Iconsax.slider_horizontal,
        'color': const Color(0xFF6366F1),
        'screen': const AdminBannersScreen(),
      },
      {
        'title': 'ئاگاداری گشتی',
        'icon': Iconsax.notification_bing,
        'color': const Color(0xFFD97706),
        'screen': const AdminNotificationsScreen(),
      },
      {
        'title': 'دارایی و داهات',
        'icon': Iconsax.wallet_3,
        'color': const Color(0xFF059669),
        'screen': const AdminTransactionsScreen(),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((act) {
          final color = act['color'] as Color;
          return InkWell(
            onTap: () => _openScreen(act['screen'] as Widget),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(act['icon'] as IconData, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    act['title'] as String,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.04, end: 0);
  }

  // ── Skeleton Shimmer Loading ──
  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        Container(
          height: 65,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: List.generate(
            8,
            (index) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../home/main_shell.dart';
import 'admin_app_bar.dart';
import 'admin_analytics_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_labs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_patients_screen.dart';
import 'admin_pharmacies_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_transactions_screen.dart';
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
    final int nurses = int.tryParse('${_stats?['pending_nurses'] ?? 0}') ?? 0;
    final int labs = int.tryParse('${_stats?['pending_labs'] ?? 0}') ?? 0;
    final int pharms = int.tryParse('${_stats?['pending_pharmacies'] ?? 0}') ?? 0;
    final int drivers = int.tryParse('${_stats?['pending_drivers'] ?? 0}') ?? 0;
    final int orders = int.tryParse('${_stats?['pending_orders'] ?? 0}') ?? 0;
    final int openTickets = int.tryParse('${_stats?['open_tickets'] ?? 0}') ?? 0;
    return nurses + labs + pharms + drivers + orders + openTickets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
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
                children: [
                  TextSpan(
                    text: 'Dr ',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const TextSpan(
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
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
        showBackButton: false,
        actions: [
          IconButton(
            tooltip: 'ئەپی نەخۆش',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: const Icon(Iconsax.mobile, color: Color(0xFF3B82F6), size: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainShell()),
              );
            },
          ),
          IconButton(
            tooltip: 'سکاڵا و پشتیوانی',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: const Icon(Iconsax.message_question, color: Color(0xFF0F172A), size: 18),
                ),
                if ((_stats?['open_tickets'] ?? 0) > 0 || (_stats?['unread_ticket_messages'] ?? 0) > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${(_stats?['open_tickets'] ?? 0) > 0 ? _stats!['open_tickets'] : _stats!['unread_ticket_messages']}',
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _openScreen(const AdminTicketsScreen()),
          ),
          IconButton(
            tooltip: 'ئاگادارییەکان',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: const Icon(Iconsax.notification, color: Color(0xFF0F172A), size: 18),
            ),
            onPressed: () => _openScreen(const AdminNotificationsScreen()),
          ),
          const SizedBox(width: 8),
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
                // 1. Pending Alert (if any pending items exist)
                if (_totalPending > 0) ...[
                  _buildPendingBanner(),
                  const SizedBox(height: 16),
                ],

                // 2. Large Hero Key Stats
                _buildKeyStatsGrid(),
                const SizedBox(height: 24),

                // 3. Section Title: Essential Active Services
                _buildSectionTitle('خزمەتگوزارییە سەرەکییەکان', 'بەڕێوەبردنی ڕۆژانە و داواکارییەکان'),
                const SizedBox(height: 12),
                _buildEssentialServicesGrid(),
                const SizedBox(height: 24),

                // 4. Section Title: Marketing & Management
                _buildSectionTitle('ناوەڕۆک و دارایی', 'ڕیکلام، ئاگاداری، وتار و پارەدان'),
                const SizedBox(height: 12),
                _buildManagementGrid(),
                const SizedBox(height: 24),

                // 5. Section Title: Coming Soon Services
                _buildSectionTitle('خزمەتگوزارییەکانی داهاتوو', 'لە قۆناغی ئامادەکردندان'),
                const SizedBox(height: 12),
                _buildComingSoonRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextTitle(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 12,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
      ],
    );
  }

  // ── 1. Pending Alert Banner ──
  Widget _buildPendingBanner() {
    return GestureDetector(
      onTap: () {
        if ((_stats?['open_tickets'] ?? 0) > 0) {
          _openScreen(const AdminTicketsScreen());
        } else if ((_stats?['pending_orders'] ?? 0) > 0) {
          _openScreen(const AdminOrdersScreen());
        } else if ((_stats?['pending_nurses'] ?? 0) > 0) {
          _openScreen(const AdminNursesScreen());
        } else if ((_stats?['pending_drivers'] ?? 0) > 0) {
          _openScreen(const AdminDriversScreen());
        } else if ((_stats?['pending_labs'] ?? 0) > 0) {
          _openScreen(const AdminLabsScreen());
        } else {
          _openScreen(const AdminPharmaciesScreen());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFDE68A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2, color: Color(0xFFB45309), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalPending داواکاری چاوەڕوانکراو',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'پێویستیان بە پێداچوونەوە و پەسەندکردنە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'پیشاندان',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  // ── 2. Key Stats Cards (3 Pillars: Patients, Orders, Providers) ──
  Widget _buildKeyStatsGrid() {
    final totalPatients = '${_stats?['total_users'] ?? 0}';
    final totalOrders = '${_stats?['total_orders'] ?? 0}';
    final totalNurses = int.tryParse('${_stats?['total_nurses'] ?? 0}') ?? 0;
    final totalLabs = int.tryParse('${_stats?['total_labs'] ?? 0}') ?? 0;
    final totalPharmacies = int.tryParse('${_stats?['total_pharmacies'] ?? 0}') ?? 0;
    final totalProviders = '${totalLabs + totalPharmacies + totalNurses}';

    return Row(
      children: [
        Expanded(
          child: _buildBigStatCard(
            title: 'نەخۆشەکان',
            value: totalPatients,
            subtitle: 'بەکارهێنەرانی ئەپ',
            icon: Iconsax.profile_2user,
            color: const Color(0xFF0D9488),
            onTap: () => _openScreen(const AdminPatientsScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBigStatCard(
            title: 'داواکارییەکان',
            value: totalOrders,
            subtitle: 'کۆی ئۆردەرەکان',
            icon: Iconsax.box,
            color: const Color(0xFFF59E0B),
            onTap: () => _openScreen(const AdminOrdersScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBigStatCard(
            title: 'دابینکەران',
            value: totalProviders,
            subtitle: 'تاقیگە، دەرمان، ستاف',
            icon: Iconsax.health,
            color: const Color(0xFF2563EB),
            onTap: () => _openScreen(const AdminPharmaciesScreen()),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }

  Widget _buildBigStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.getSurface(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.getTextSubtitle(context)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextTitle(context),
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 10,
                  color: AppColors.getTextSubtitle(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. Essential Active Services Grid (Large & Clean) ──
  Widget _buildEssentialServicesGrid() {
    final int pendingOrders = (_stats?['pending_orders'] ?? 0) as int;
    final int totalOrders = (_stats?['total_orders'] ?? 0) as int;

    final int openTickets = (_stats?['open_tickets'] ?? 0) as int;
    final int unreadTicketMessages = (_stats?['unread_ticket_messages'] ?? 0) as int;

    final int pendingPharmacies = (_stats?['pending_pharmacies'] ?? 0) as int;
    final int totalPharmacies = (_stats?['total_pharmacies'] ?? 0) as int;

    final int pendingLabs = (_stats?['pending_labs'] ?? 0) as int;
    final int totalLabs = (_stats?['total_labs'] ?? 0) as int;

    final int pendingNurses = (_stats?['pending_nurses'] ?? 0) as int;
    final int totalNurses = (_stats?['total_nurses'] ?? 0) as int;

    final int pendingDrivers = int.tryParse('${_stats?['pending_drivers'] ?? 0}') ?? 0;
    final int totalDrivers = int.tryParse('${_stats?['total_drivers'] ?? 0}') ?? 0;
    final int onlineDrivers = int.tryParse('${_stats?['online_drivers'] ?? 0}') ?? 0;

    final int totalUsers = (_stats?['total_users'] ?? 0) as int;

    final List<Map<String, dynamic>> essentials = [
      {
        'title': 'داواکارییەکان',
        'subtitle': '$totalOrders ئۆردەری نەخۆش',
        'icon': Iconsax.box,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'badge': pendingOrders > 0 ? '$pendingOrders نوێ' : null,
        'screen': const AdminOrdersScreen(),
      },
      {
        'title': 'سکاڵا و پشتیوانی',
        'subtitle': openTickets > 0 ? '$openTickets تیکێتی کراوە' : 'پشتیوانی نەخۆش',
        'icon': Iconsax.message_question,
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'badge': openTickets > 0
            ? '$openTickets تیکێتی نوێ'
            : (unreadTicketMessages > 0 ? '$unreadTicketMessages نامە' : null),
        'screen': const AdminTicketsScreen(),
      },
      {
        'title': 'ئامار و ڕاپۆرت',
        'subtitle': 'گەشەکردن و داهات',
        'icon': Iconsax.chart_2,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'badge': null,
        'screen': const AdminAnalyticsScreen(),
      },
      {
        'title': 'پەرستارەکان',
        'subtitle': '$totalNurses پەرستاری ماڵەوە',
        'icon': Iconsax.profile_2user,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'badge': pendingNurses > 0 ? '$pendingNurses پەسەندکردن' : null,
        'screen': const AdminNursesScreen(),
      },
      {
        'title': 'تاقیگەکان',
        'subtitle': '$totalLabs تاقیگەی پزیشکی',
        'icon': Iconsax.microscope,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'badge': pendingLabs > 0 ? '$pendingLabs پەسەندکردن' : null,
        'screen': const AdminLabsScreen(),
      },
      {
        'title': 'دەرمانخانەکان',
        'subtitle': '$totalPharmacies دەرمانخانە',
        'icon': Iconsax.health,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
        'badge': pendingPharmacies > 0 ? '$pendingPharmacies پەسەندکردن' : null,
        'screen': const AdminPharmaciesScreen(),
      },
      {
        'title': 'نەخۆشەکان',
        'subtitle': '$totalUsers نەخۆش و بەکارهێنەر',
        'icon': Iconsax.profile_2user,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
        'badge': null,
        'screen': const AdminPatientsScreen(),
      },
      {
        'title': 'کارمەندانی گەیاندن',
        'subtitle': '$onlineDrivers لە هێڵ · $totalDrivers شۆفێر',
        'icon': Iconsax.truck_fast,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'badge': pendingDrivers > 0 ? '$pendingDrivers پەسەندکردن' : null,
        'screen': const AdminDriversScreen(),
      },
      {
        'title': 'کۆدەکانی داشکاندن',
        'subtitle': 'پڕۆمۆکۆدی داشکاندن',
        'icon': Iconsax.ticket_discount,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'badge': null,
        'screen': const AdminCouponsScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: essentials.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = essentials[index];
        final color = item['color'] as Color;
        final bg = item['bg'] as Color;
        final badge = item['badge'] as String?;

        return Material(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _openScreen(item['screen'] as Widget),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        child: Icon(item['icon'] as IconData, color: color, size: 22),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextTitle(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          color: AppColors.getTextSubtitle(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04, end: 0);
  }

  // ── 4. Management & Content Grid (Wide Cards) ──
  Widget _buildManagementGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'دارایی و داهاتی گشتی',
        'subtitle': 'تۆماری تراکنش و بزووتنەوە داراییەکان',
        'icon': Iconsax.wallet_3,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
        'screen': const AdminTransactionsScreen(),
      },
      {
        'title': 'بانەر و ڕیکلامەکان',
        'subtitle': 'ڕیکلام و پۆستەری سەرەکی ئەپ',
        'icon': Iconsax.picture_frame,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'screen': const AdminBannersScreen(),
      },
      {
        'title': 'ئاگاداری گشتی (Push Notification)',
        'subtitle': 'ناردنی پەیامی ڕاستەوخۆ بۆ بەکارهێنەران',
        'icon': Iconsax.notification_bing,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'screen': const AdminNotificationsScreen(),
      },
      {
        'title': 'فریاگوزاری و وتارەکان',
        'subtitle': 'ڕێنمایی پزیشکی و فریاگوزاری سەرەتایی',
        'icon': Iconsax.document_text,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
        'screen': const AdminArticlesScreen(),
      },
    ];

    return Column(
      children: items.map((item) {
        final color = item['color'] as Color;
        final bg = item['bg'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _openScreen(item['screen'] as Widget),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextTitle(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11.5,
                              color: AppColors.getTextSubtitle(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.04, end: 0);
  }

  // ── 5. Coming Soon Services ──
  Widget _buildComingSoonRow() {
    final List<Map<String, dynamic>> comingSoon = [
      {
        'title': 'پزیشکەکان',
        'icon': Iconsax.health,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'screen': const AdminDoctorsScreen(),
      },
      {
        'title': 'سەنتەری تیشک',
        'icon': Iconsax.scan,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'screen': const AdminXRaysScreen(),
      },
    ];

    return Row(
      children: comingSoon.map((item) {
        final color = item['color'] as Color;
        final bg = item['bg'] as Color;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'خزمەتگوزاری ${item['title']} بەمزوانە بەردەست دەبێت',
                        style: const TextStyle(fontFamily: 'Rabar'),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextTitle(context),
                              ),
                            ),
                            const Text(
                              'بەمزوانە',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
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
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.04, end: 0);
  }

  // ── Skeleton Shimmer Loading ──
  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: List.generate(
            6,
            (index) => Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/providers/order_provider.dart';
import 'home_screen.dart';
import '../requests/my_requests_screen.dart';
import '../ai_assistant/ai_symptom_checker_screen.dart';
import '../records/medical_records_screen.dart';
import '../body_map/body_map_screen.dart';
import '../settings/settings_screen.dart';
import '../surgery/surgery_timeline_screen.dart';
import '../prescriptions/pill_reminder_screen.dart';
import '../checkout/payment_history_screen.dart';
import '../first_aid/first_aid_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _aiTabIndex = 2;
  static const int _recordsTabIndex = 3;
  static const int _requestsTabIndex = 4;

  String _userName = '';
  String _userPhone = '';
  int _currentIndex = 0;

  final GlobalKey<MyRequestsScreenState> _requestsKey =
      GlobalKey<MyRequestsScreenState>();

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
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final un = prefs.getString('user_name') ?? '';
        _userName = un.isNotEmpty ? un : 'سڵاو لە ئێوە';
        _userPhone = prefs.getString('user_phone') ?? '';
      });
    }
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    const FirstAidScreen(),
    const AiSymptomCheckerScreen(),
    const MedicalRecordsScreen(),
    MyRequestsScreen(key: _requestsKey),
    const SettingsScreen(),
  ];

  static const List<Map<String, dynamic>> _navItems = [
    {'title': 'ماڵەوە', 'icon': Iconsax.home_2},
    {'title': 'فریاگوزاری', 'icon': Icons.medical_services_outlined},
    {'title': 'AI ڕاوێژکار', 'icon': Iconsax.message_programming, 'isAi': true},
    {'title': 'تۆمارەکان', 'icon': Iconsax.folder_2},
    {'title': 'داواکاری', 'icon': Iconsax.box},
    {'title': 'ڕێکخستن', 'icon': Iconsax.setting_2},
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    if (index == _requestsTabIndex) {
      _requestsKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      endDrawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Main Active Screen Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Modern Bottom Navigation Bar
          PositionedDirectional(
            start: 14,
            end: 14,
            bottom: 18,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  return Expanded(
                    child: _buildNavItem(index, _navItems[index], isDark),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, Map<String, dynamic> item, bool isDark) {
    final isActive = _currentIndex == index;
    final isAi = item['isAi'] == true;
    final icon = item['icon'] as IconData;
    final title = item['title'] as String;

    final activeColor = isAi ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive && !isAi
              ? activeColor.withValues(alpha: 0.1)
              : (isActive && isAi ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            index == _requestsTabIndex
                ? _buildOrdersIcon(icon, color)
                : (isAi && isActive
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF8B5CF6),
                        ),
                        child: const Icon(Iconsax.message_programming, color: Colors.white, size: 16),
                      )
                    : Icon(icon, color: color, size: 20)),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _kStyle(
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersIcon(IconData icon, Color color) {
    return Consumer2<OrderProvider, AppointmentProvider>(
      builder: (context, orderProvider, appointmentProvider, child) {
        final count =
            orderProvider.activeOrderCount +
            appointmentProvider.activeAppointmentCount;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            if (count > 0)
              PositionedDirectional(
                top: -4,
                end: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.only(
              top: 60,
              bottom: 28,
              start: 24,
              end: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadiusDirectional.only(
                bottomStart: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/doctor2.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _userName.isNotEmpty ? _userName : 'بەخێربێن بۆ Dr-Room',
                  style: _kStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _userPhone,
                    style: _kStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.star_1, color: Color(0xFF2563EB), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ئەندامی تایبەتی Dr-Room',
                        style: _kStyle(
                          color: const Color(0xFF2563EB),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.message_programming,
                    title: 'یاریدەدەری زیرەکی دەستکرد (AI)',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = _aiTabIndex);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.folder_2,
                    title: 'تۆماری پزیشکی',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = _recordsTabIndex);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.clock,
                    title: 'بیرخەرەوەی دەرمان',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PillReminderScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.hospital,
                    title: 'هێڵی کاتی نەشتەرگەری',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SurgeryTimelineScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.accessibility_new_rounded,
                    title: 'نەخشەی جەستە (دەستنیشان)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BodyMapScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.card_pos,
                    title: 'مێژووی پارەدان',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    IconData? icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Iconsax.arrow_left_2,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

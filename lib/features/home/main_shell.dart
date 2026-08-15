import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_room/features/requests/my_requests_screen.dart';
import 'package:flutter/material.dart';
import '../body_map/body_map_screen.dart';
import '../surgery/surgery_timeline_screen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/providers/order_provider.dart';
import 'home_screen.dart';
import '../settings/settings_screen.dart';
import '../pharmacy/pill_scanner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _requestsTabIndex = 1;
  static const int _bodyMapTabIndex = 2;
  static const int _settingsTabIndex = 3;

  String _userName = '';
  String _userPhone = '';

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

  static const List<IconData> _navIcons = [
    Iconsax.home_2,
    Iconsax.box,
    Icons.accessibility_new_rounded,
    Iconsax.setting_2,
  ];

  int _currentIndex = 0;

  final GlobalKey<MyRequestsScreenState> _requestsKey =
      GlobalKey<MyRequestsScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    MyRequestsScreen(key: _requestsKey),
    BodyMapScreen(onBack: () => setState(() => _currentIndex = 0)),
    const SettingsScreen(),
  ];

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PillScannerScreen()),
    );
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    if (index == _requestsTabIndex) {
      _requestsKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      endDrawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Floating Bottom Navigation Bar
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Symmetrical Nav Items Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildNavItem(0, _navIcons[0])),
                      Expanded(child: _buildNavItem(1, _navIcons[1])),
                      const SizedBox(width: 60), // Center gap for scanner
                      Expanded(child: _buildNavItem(2, _navIcons[2])),
                      Expanded(child: _buildNavItem(3, _navIcons[3])),
                    ],
                  ),

                  // Center Scanner Button
                  Positioned(
                    top: -12,
                    child: _buildScanNavItem(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            index == _requestsTabIndex
                ? _buildOrdersIcon(icon, color)
                : Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              _getLabelForIndex(index),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _kStyle(
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
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
            Icon(icon, color: color, size: 22),
            if (count > 0)
              PositionedDirectional(
                top: -4,
                end: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScanNavItem() {
    return GestureDetector(
      onTap: _openScanner,
      behavior: HitTestBehavior.opaque,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: const Icon(Iconsax.scan, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'ماڵەوە';
      case _requestsTabIndex:
        return 'داواکاری';
      case _bodyMapTabIndex:
        return 'نەخشەی جەستە';
      case _settingsTabIndex:
        return 'ڕێکخستن';
      default:
        return '';
    }
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
    String? imagePath,
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

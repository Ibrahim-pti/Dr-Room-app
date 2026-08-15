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
import '../../core/theme/app_colors.dart';
import 'home_screen.dart';
import '../settings/settings_screen.dart';
import '../pharmacy/pill_scanner_screen.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

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
        _userName = un.isNotEmpty ? un : 'guest_user'.tr();
        _userPhone = prefs.getString('user_phone') ?? '';
      });
    }
  }

  static const List<IconData> _navIcons = [
    Iconsax.home_2,
    Iconsax.box,
    Icons.accessibility_new_rounded,
    Iconsax.user,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      endDrawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Floating Bottom Navigation Bar
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                      const SizedBox(width: 64), // Symmetrical center gap for scanner
                      Expanded(child: _buildNavItem(2, _navIcons[2])),
                      Expanded(child: _buildNavItem(3, _navIcons[3])),
                    ],
                  ),

                  // Dead-Center Scanner Button
                  Positioned(
                    top: -10,
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
            const SizedBox(height: 4),
            Text(
              _getLabelForIndex(index),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: const Icon(Iconsax.scan, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'nav_home'.tr();
      case _requestsTabIndex:
        return 'nav_requests'.tr();
      case _bodyMapTabIndex:
        return 'nav_body'.tr();
      case _settingsTabIndex:
        return 'nav_profile'.tr();
      default:
        return '';
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.getSurface(context),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: const BorderRadiusDirectional.only(
                bottomStart: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/doctor2.png',
                          ), // Placeholder
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _userName.isNotEmpty ? _userName : 'guest_user'.tr(),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userPhone,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // DrRoom Plus Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DrRoom Plus Member',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Iconsax.star_1, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Everything a patient reaches for regularly now lives where
                  // they already look: the AI assistant, body map and pill
                  // reminder in the home services row, and medical records,
                  // favourite doctors and payment history under Profile. What
                  // is left here is the genuinely occasional.
                  _buildDrawerItem(
                    context,
                    icon: Iconsax.hospital,
                    title: 'surgery_timeline'.tr(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsetsDirectional.only(
            start: 16,
            end: 16,
            bottom: 8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceSecondary(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.getTextSubtitle(context),
                size: 20,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextTitle(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imagePath != null
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : Icon(icon, color: AppColors.primary, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

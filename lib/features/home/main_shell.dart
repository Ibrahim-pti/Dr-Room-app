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
import '../emergency_reels/emergency_reels_screen.dart';
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

  /// One entry per tab, in bar order. The screens list below follows the same
  /// order, so an index means the same thing in both.
  static const List<IconData> _navIcons = [
    Iconsax.home_2,
    Iconsax.box,
    Icons.accessibility_new_rounded,
    Iconsax.document_text,
    Iconsax.user,
  ];

  int _currentIndex = 0;

  /// Lets the shell refresh the requests list whenever its tab is reopened,
  /// since IndexedStack keeps the screen alive and initState runs only once.
  final GlobalKey<MyRequestsScreenState> _requestsKey =
      GlobalKey<MyRequestsScreenState>();

  /// Built once and reused, so switching tabs never rebuilds these screens
  /// from scratch (and never re-runs their startup fetches).
  late final List<Widget> _screens = [
    const HomeScreen(),
    MyRequestsScreen(key: _requestsKey),
    BodyMapScreen(onBack: () => setState(() => _currentIndex = 0)),
    const EmergencyReelsScreen(),
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
      backgroundColor: const Color(
        0xFFF1F5F9,
      ), // Light background to match Home
      endDrawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Floating Bottom Navigation Bar
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 30, // Floats above the bottom
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Five tabs plus the scan button no longer divide evenly, so
                  // the button is placed over the gap it actually leaves rather
                  // than at the centre of the bar — at the centre it would sit
                  // on top of a tab.
                  const scanSize = 56.0;
                  const tabsBeforeScan = 2;
                  final slot =
                      (constraints.maxWidth - scanSize) / _navIcons.length;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < _navIcons.length; i++) ...[
                            // Equal shares rather than sizing to the label, so
                            // a long translation cannot overflow the bar.
                            if (i == tabsBeforeScan)
                              const SizedBox(width: scanSize),
                            Expanded(child: _buildNavItem(i, _navIcons[i])),
                          ],
                        ],
                      ),
                      PositionedDirectional(
                        top: 0,
                        start: slot * tabsBeforeScan,
                        child: _buildScanNavItem(),
                      ),
                    ],
                  );
                },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          index == _requestsTabIndex
              ? _buildOrdersIcon(icon, color)
              : Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              _getLabelForIndex(index),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The Requests icon carries a count of everything the patient is still
  /// waiting on — open orders plus upcoming appointments — so a status change
  /// is visible without opening the tab.
  Widget _buildOrdersIcon(IconData icon, Color color) {
    return Consumer2<OrderProvider, AppointmentProvider>(
      builder: (context, orderProvider, appointmentProvider, child) {
        final count =
            orderProvider.activeOrderCount +
            appointmentProvider.activeAppointmentCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 22),
            if (count > 0)
              PositionedDirectional(
                top: -4,
                end: -6,
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: const Icon(Iconsax.scan, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  /// Short forms on purpose: five labels share the bar's width, so the full
  /// names ("نەخشەی جەستە", "داواکارییەکان") no longer fit a slot.
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'nav_home'.tr();
      case _requestsTabIndex:
        return 'nav_requests'.tr();
      case _bodyMapTabIndex:
        return 'nav_body'.tr();
      case 3:
        return 'nav_articles'.tr();
      case 4:
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

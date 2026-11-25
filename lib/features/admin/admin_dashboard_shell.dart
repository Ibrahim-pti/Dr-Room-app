import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_labs_screen.dart';
import 'admin_menu_screen.dart';
import '../../core/utils/admin_permissions.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // The menu hides what this account may not open; refresh once on entry.
    AdminPermissions.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  List<_NavItem> get _visibleNavItems {
    final all = <_NavItem>[
      const _NavItem(icon: Iconsax.category_2, label: 'سەرەکی', screen: AdminDashboardScreen()),
      if (AdminPermissions.can('manage_orders'))
        const _NavItem(icon: Iconsax.box, label: 'داواکارییەکان', screen: AdminOrdersScreen(isRoot: true)),
      if (AdminPermissions.can('manage_nurses'))
        _NavItem(icon: Iconsax.profile_2user, label: 'admin_health_centers'.tr(), screen: const AdminNursesScreen(isRoot: true)),
      if (AdminPermissions.can('manage_labs'))
        const _NavItem(icon: Iconsax.microscope, label: 'تاقیگەکان', screen: AdminLabsScreen(isRoot: true)),
      const _NavItem(icon: Iconsax.setting_2, label: 'ڕێکخستن', screen: AdminMenuScreen()),
    ];
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    final navItems = _visibleNavItems;
    final safeIndex = _currentIndex >= navItems.length ? 0 : _currentIndex;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // Screen content
            IndexedStack(
              index: safeIndex,
              children: navItems.map((e) => e.screen).toList(),
            ),

            // Floating nav bar
            PositionedDirectional(
              start: 20,
              end: 20,
              bottom: 30,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    navItems.length,
                    (i) => _buildNavItem(i, navItems[i], safeIndex),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, int safeIndex) {
    final isActive = safeIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0EEFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem({required this.icon, required this.label, required this.screen});
}
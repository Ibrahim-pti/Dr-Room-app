import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../pharmacy/providers/cart_provider.dart';
import '../../pharmacy/screens/cart_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../search/global_search_screen.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Curved Background Header ──
        ClipPath(
          clipper: OvalBottomBorderClipper(),
          child: Container(
            height: 285,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Glowing Background Circles
                Positioned(
                  top: -60,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Decorative Heart Icon
                Positioned(
                  left: -20,
                  top: 80,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      size: 120,
                      color: Colors.white,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.02, end: 0.04, duration: 5000.ms)
                      .moveX(begin: 0, end: 12, duration: 6000.ms, curve: Curves.easeInOut)
                      .rotate(begin: -0.02, end: 0.02, duration: 8000.ms),
                ),
              ],
            ),
          ),
        ),

        // ── Content Over Header ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // ── App Bar Row ──
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // User Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.getSurface(context),
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/doctor2.png'),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // User Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userName.isNotEmpty && userName.toLowerCase() != 'slaw'
                                      ? '${'greeting_hello'.tr()}، $userName'
                                      : '${'greeting_hello'.tr()}، ${'greeting_welcome'.tr()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'wishing_good_health'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cart Icon
                        Consumer(
                          builder: (context, ref, child) {
                            final cartState = ref.watch(cartProvider);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartScreen(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Iconsax.shopping_cart, color: Colors.white, size: 20),
                                  ),
                                  if (cartState.totalItems > 0)
                                    PositionedDirectional(
                                      top: 6,
                                      end: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          cartState.totalItems.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Notification Icon
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Iconsax.notification, color: Colors.white, size: 20),
                              ),
                              PositionedDirectional(
                                top: 10,
                                end: 10,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Menu Icon (Open Drawer)
                        GestureDetector(
                          onTap: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.menu_1, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                const SizedBox(height: 38),

                // ── Modern Soft Search Bar ──
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsetsDirectional.only(
                      start: 18,
                      end: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.search_normal_1,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'search_doctors'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Iconsax.microphone,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 2500.ms,
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OvalBottomBorderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
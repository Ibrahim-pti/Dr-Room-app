import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  final void Function(bool isLoggedIn, String role, bool isFirstTime) onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _ecgAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation timeline
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _ecgAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeInOutCubic),
    );

    _mainController.forward();

    // Smooth transition to next screen
    Future.delayed(const Duration(milliseconds: 2600), () async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role') ?? 'patient';
      final hasCompletedSetup = prefs.getBool('has_completed_setup') ?? false;

      if (mounted) {
        widget.onFinished(
          token != null && token.isNotEmpty,
          role,
          !hasCompletedSetup,
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Harmonious colors matching the app exactly (without heavy shadows)
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColorDr = isDark ? Colors.white : const Color(0xFF1E293B);
    const primaryBlue = Color(0xFF2E86DE);
    final sloganColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Emblem resting inside a soft brand-coloured halo
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryBlue.withValues(alpha: isDark ? 0.20 : 0.12),
                            primaryBlue.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 900.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.0, 1.0),
                          duration: 1100.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    Image.asset(
                      'assets/images/app_icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Iconsax.hospital,
                        size: 42,
                        color: primaryBlue,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 650.ms,
                          begin: const Offset(0.75, 0.75),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 500.ms),
                  ],
                ),
              ),

              // 2. Wordmark
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Dr',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: textColorDr,
                        fontFamily: 'Rabar',
                        letterSpacing: -1.0,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Room',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        fontFamily: 'Rabar',
                        letterSpacing: -1.0,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 220.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 18),

              // 3. Hairline rule that draws itself open under the wordmark
              AnimatedBuilder(
                animation: _ecgAnimation,
                builder: (context, _) {
                  return Container(
                    width: min(size.width * 0.5, 190) * _ecgAnimation.value,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withValues(alpha: 0),
                          primaryBlue.withValues(alpha: 0.55),
                          primaryBlue.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 4. Slogan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'app_slogan'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sloganColor,
                    letterSpacing: 0.2,
                    height: 1.5,
                  ),
                ),
              )
                  .animate(delay: 560.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}

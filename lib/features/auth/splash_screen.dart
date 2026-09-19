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
  late AnimationController _heartController;
  late Animation<double> _ecgAnimation;
  late Animation<double> _heartScaleAnimation;

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

    // Heart pulsing animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _heartScaleAnimation = Tween<double>(begin: 0.95, end: 1.12).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
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
    _heartController.dispose();
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
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F6FF);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Centered Main Content ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Clean 3D DrRoom Emblem (No Heavy Shadows, Matches App)
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.5),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Iconsax.hospital,
                          size: 42,
                          color: primaryBlue,
                        ),
                      ),
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

                  const SizedBox(height: 20),

                  // 2. Clean Typography: "DrRoom" (Sharp & Flat, No Blurry Shadow)
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Dr',
                          style: TextStyle(
                            fontSize: 48,
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
                            fontSize: 48,
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
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 12),

                  // 3. Heartbeat Pulse Line with Center Heart (Clean Vector)
                  SizedBox(
                    width: min(size.width * 0.72, 270),
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Pulse Line
                        AnimatedBuilder(
                          animation: _ecgAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size(min(size.width * 0.72, 270), 36),
                              painter: _CleanECGPainter(
                                progress: _ecgAnimation.value,
                                color: primaryBlue,
                              ),
                            );
                          },
                        ),

                        // Center Pulsing Heart (Clean Flat Border, No Shadow)
                        AnimatedBuilder(
                          animation: _heartScaleAnimation,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: _heartScaleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryBlue.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: primaryBlue,
                                  size: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 12),

                  // 4. Official Slogan: "پەیوەندی بە نێوان دکتۆر و نەخۆشەوە"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'app_slogan'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sloganColor,
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  )
                      .animate(delay: 550.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
            ),

            // ── Bottom Loading Line (Clean Minimal Design) ──
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 90,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _mainController.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ).animate(delay: 750.ms).fadeIn(duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clean, sharp ECG pulse line painter without blurry shadows
class _CleanECGPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CleanECGPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final totalW = size.width;
    final currentW = totalW * progress;

    final path = Path()..moveTo(0, midY);

    for (double x = 0; x <= currentW; x += 1.0) {
      final r = x / totalW;
      double y = midY;

      // Left heartbeat spike (before center heart)
      if (r > 0.22 && r < 0.26) {
        y = midY - sin((r - 0.22) / 0.04 * pi) * 5;
      } else if (r > 0.27 && r < 0.35) {
        y = midY - sin((r - 0.27) / 0.08 * pi) * 12;
      } else if (r > 0.35 && r < 0.40) {
        y = midY + sin((r - 0.35) / 0.05 * pi) * 7;
      }
      // Space between 0.40 and 0.60 is reserved for the heart badge

      // Right heartbeat spike (after center heart)
      else if (r > 0.60 && r < 0.65) {
        y = midY + sin((r - 0.60) / 0.05 * pi) * 7;
      } else if (r > 0.65 && r < 0.73) {
        y = midY - sin((r - 0.65) / 0.08 * pi) * 12;
      } else if (r > 0.74 && r < 0.78) {
        y = midY - sin((r - 0.74) / 0.04 * pi) * 5;
      }

      path.lineTo(x, y);
    }

    // Crisp Clean Stroke (No Blurry Mask Filter)
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip dot
    if (progress > 0.05 && progress < 0.98) {
      final dotX = currentW;
      final r = dotX / totalW;
      double dotY = midY;
      if (r > 0.27 && r < 0.35) {
        dotY = midY - sin((r - 0.27) / 0.08 * pi) * 12;
      } else if (r > 0.65 && r < 0.73) {
        dotY = midY - sin((r - 0.65) / 0.08 * pi) * 12;
      }

      canvas.drawCircle(
        Offset(dotX, dotY),
        3.5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_CleanECGPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
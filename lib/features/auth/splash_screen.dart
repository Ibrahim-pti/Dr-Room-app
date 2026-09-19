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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ecgAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entrance & ECG Animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _ecgAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeInOutCubic),
    );

    // 2. Continuous ambient heartbeat & floating animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _mainController.forward();

    // 3. Complete splash transition and verify auth state
    Future.delayed(const Duration(milliseconds: 2800), () async {
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Stack(
        children: [
          // ── Background Ambient Clinic Lighting & Gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.18),
                  radius: 0.85,
                  colors: [
                    Color(0xFF0E244D), // Soft medical blue back-glow
                    Color(0xFF091329),
                    Color(0xFF040814),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Animated Pulsing Glow Rings behind Logo ──
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Transform.translate(
                  offset: const Offset(0, -50),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer soft aura
                      Container(
                        width: 280 * _pulseAnimation.value,
                        height: 280 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        ),
                      ),
                      // Inner intense aura
                      Container(
                        width: 200 * _pulseAnimation.value,
                        height: 200 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Main Centered Content ──
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Official 3D Clinic Emblem Badge
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF38BDF8).withValues(alpha: 0.6),
                            const Color(0xFF0284C7).withValues(alpha: 0.3),
                            const Color(0xFF1E293B).withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0A1428),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: Image.asset(
                            'assets/images/dr_room_icon_clean.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0F172A),
                              ),
                              child: const Icon(
                                Iconsax.hospital,
                                size: 48,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 900.ms,
                        begin: const Offset(0.65, 0.65),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 22),

                  // 2. 3D Metallic Typography: "DrRoom"
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // "Dr" in Brilliant Medical Blue Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF60A5FA), // Light Blue
                              Color(0xFF2563EB), // Deep Royal Blue
                              Color(0xFF1D4ED8),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Dr',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              fontFamily: 'Rabar',
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF2563EB),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // "Room" in Chrome Silver / Metallic Titanium Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFFFFF), // Pure White Shine
                              Color(0xFFE2E8F0),
                              Color(0xFFCBD5E1),
                              Color(0xFF94A3B8), // Metallic Chrome Dark
                            ],
                            stops: [0.0, 0.35, 0.7, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'Room',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              fontFamily: 'Rabar',
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF64748B),
                                  blurRadius: 14,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 700.ms)
                      .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 14),

                  // 3. Glowing Heartbeat ECG Line with Center Heart
                  SizedBox(
                    width: min(size.width * 0.78, 300),
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Pulse Line Custom Painter
                        AnimatedBuilder(
                          animation: _ecgAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size(min(size.width * 0.78, 300), 38),
                              painter: _HeartbeatPainter(
                                progress: _ecgAnimation.value,
                              ),
                            );
                          },
                        ),

                        // Center Pulsing Heart
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B1426),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 14),

                  // 4. Official Brand Slogan in Kurdish
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'app_slogan'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 700.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),

          // ── Bottom Progress Indicator & Branding ──
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Slim Progress Bar
                Container(
                  width: 120,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
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
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0284C7),
                                Color(0xFF38BDF8),
                                Color(0xFF93C5FD),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Discreet Platform Label
                Text(
                  'DrRoom Medical Platform',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B).withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ).animate(delay: 900.ms).fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

/// Custom Heartbeat ECG Line Painter matching the official DrRoom logo design
class _HeartbeatPainter extends CustomPainter {
  final double progress;

  _HeartbeatPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final totalW = size.width;
    final currentW = totalW * progress;

    final path = Path()..moveTo(0, midY);

    // Generate heartbeat pattern with left and right spike clusters
    for (double x = 0; x <= currentW; x += 1.0) {
      final r = x / totalW;
      double y = midY;

      // Left heartbeat spike (before center heart)
      if (r > 0.22 && r < 0.26) {
        y = midY - sin((r - 0.22) / 0.04 * pi) * 6;
      } else if (r > 0.28 && r < 0.35) {
        y = midY - sin((r - 0.28) / 0.07 * pi) * 14;
      } else if (r > 0.35 && r < 0.40) {
        y = midY + sin((r - 0.35) / 0.05 * pi) * 8;
      }
      // Space between 0.40 and 0.60 is reserved for the heart badge

      // Right heartbeat spike (after center heart)
      else if (r > 0.60 && r < 0.65) {
        y = midY + sin((r - 0.60) / 0.05 * pi) * 8;
      } else if (r > 0.65 && r < 0.72) {
        y = midY - sin((r - 0.65) / 0.07 * pi) * 14;
      } else if (r > 0.74 && r < 0.78) {
        y = midY - sin((r - 0.74) / 0.04 * pi) * 6;
      }

      path.lineTo(x, y);
    }

    // Glow line (background blur)
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.4)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Crisp neon core line
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF38BDF8),
            Color(0xFF93C5FD),
          ],
        ).createShader(Rect.fromLTWH(0, 0, totalW, size.height))
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Glowing tip spark
    if (progress > 0.05 && progress < 0.98) {
      final sparkX = currentW;
      final r = sparkX / totalW;
      double sparkY = midY;
      if (r > 0.28 && r < 0.35) {
        sparkY = midY - sin((r - 0.28) / 0.07 * pi) * 14;
      } else if (r > 0.65 && r < 0.72) {
        sparkY = midY - sin((r - 0.65) / 0.07 * pi) * 14;
      }

      canvas.drawCircle(
        Offset(sparkX, sparkY),
        4.5,
        Paint()
          ..color = const Color(0xFFE0F2FE)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_HeartbeatPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
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

              const SizedBox(height: 14),

              // 3. Heartbeat pulse line with the pulsing heart at its centre
              SizedBox(
                width: min(size.width * 0.72, 270),
                height: 40,
                child: Stack(
                  // Sits on the trace's baseline, which the painter keeps below
                  // centre so the tall R spike has room.
                  alignment: const Alignment(0, 0.24),
                  children: [
                    AnimatedBuilder(
                      animation: _ecgAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(min(size.width * 0.72, 270), 40),
                          painter: _CleanECGPainter(
                            progress: _ecgAnimation.value,
                            color: primaryBlue,
                          ),
                        );
                      },
                    ),
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
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 14),

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

/// Draws a real ECG strip — P wave, sharp QRS spike, T wave — once on each
/// side of the heart badge, with a flat stretch in the middle where the badge
/// sits.
class _CleanECGPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CleanECGPainter({required this.progress, required this.color});

  // Where each complex sits along the trace. 0.42–0.58 stays flat: that
  // stretch runs behind the heart badge.
  static const double _leftStart = 0.02;
  static const double _leftEnd = 0.42;
  static const double _rightStart = 0.58;
  static const double _rightEnd = 0.98;

  /// One cardiac complex as an amplitude in -1..1 (positive points upward),
  /// for [t] running across the complex.
  static double _beat(double t) {
    if (t < 0.12 || t > 0.86) return 0; // isoelectric baseline
    if (t < 0.24) return 0.16 * sin((t - 0.12) / 0.12 * pi); // P wave
    if (t < 0.34) return 0; // PR segment
    if (t < 0.38) return -0.22 * (t - 0.34) / 0.04; // Q
    if (t < 0.44) return -0.22 + 1.22 * (t - 0.38) / 0.06; // R upstroke
    if (t < 0.50) return 1.0 - 1.42 * (t - 0.44) / 0.06; // R downstroke
    if (t < 0.55) return -0.42 + 0.42 * (t - 0.50) / 0.05; // S recovery
    if (t < 0.68) return 0; // ST segment
    return 0.34 * sin((t - 0.68) / 0.18 * pi); // T wave
  }

  static double _amplitudeAt(double r) {
    if (r >= _leftStart && r <= _leftEnd) {
      return _beat((r - _leftStart) / (_leftEnd - _leftStart));
    }
    if (r >= _rightStart && r <= _rightEnd) {
      return _beat((r - _rightStart) / (_rightEnd - _rightStart));
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.62; // baseline, matching the badge alignment
    final amp = midY - 3; // keeps the R spike inside the box
    final totalW = size.width;
    final currentW = totalW * progress;

    double yAt(double x) => midY - _amplitudeAt(x / totalW) * amp;

    final path = Path()..moveTo(0, midY);
    for (double x = 0; x <= currentW; x += 0.5) {
      path.lineTo(x, yAt(x));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (progress > 0.05 && progress < 0.98) {
      canvas.drawCircle(
        Offset(currentW, yAt(currentW)),
        3.5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_CleanECGPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

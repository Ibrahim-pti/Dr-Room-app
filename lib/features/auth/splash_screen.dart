import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class SplashScreen extends StatefulWidget {
  final void Function(bool isLoggedIn, String role, bool isFirstTime) onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // Remove splash screen after delay and check auth
    Future.delayed(const Duration(milliseconds: 2200), () async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role') ?? 'patient';
      final hasCompletedSetup = prefs.getBool('has_completed_setup') ?? false;

      if (mounted) {
        widget.onFinished(token != null && token.isNotEmpty, role, !hasCompletedSetup);
      }
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── App Name ──
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dr',
                        style: GoogleFonts.poppins(
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B), // Dark slate color
                          letterSpacing: -1.2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Room',
                        style: GoogleFonts.poppins(
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B82F6), // Primary Blue
                          letterSpacing: -1.2,
                          height: 1,
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                  ),

                  // ── ECG Line directly below text ──
                  AnimatedBuilder(
                    animation: _ecgController,
                    builder: (context, _) => ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                          stops: [0.0, 0.2, 0.8, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: CustomPaint(
                        size: Size(size.width, 80),
                        painter: _ECGPainter(progress: _ecgController.value),
                      ),
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ECGPainter extends CustomPainter {
  final double progress;
  _ECGPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final totalW = size.width;
    final drawW = totalW * progress;

    final path = Path()..moveTo(0, midY);

    for (double x = 0; x < drawW; x += 0.8) {
      final r = x / totalW;
      double y = midY;

      // Heartbeat spikes in the center (from r=0.35 to r=0.65)
      if (r > 0.35 && r < 0.40) {
        y = midY - sin((r - 0.35) / 0.05 * pi) * 8;
      } else if (r > 0.42 && r < 0.45) {
        y = midY + sin((r - 0.42) / 0.03 * pi) * 6;
      } else if (r > 0.45 && r < 0.53) {
        y = midY - sin((r - 0.45) / 0.08 * pi) * 35; // Big spike
      } else if (r > 0.53 && r < 0.58) {
        y = midY + sin((r - 0.53) / 0.05 * pi) * 12; // Down spike
      } else if (r > 0.62 && r < 0.70) {
        y = midY - sin((r - 0.62) / 0.08 * pi) * 10;
      }

      path.lineTo(x, y);
    }

    // Core Line
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3B82F6) // Primary Blue
        ..strokeWidth = 3.0 // Slightly thicker
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip dot
    if (progress > 0.01 && progress < 0.99) {
      final tx = drawW;
      final r = tx / totalW;
      double ty = midY;
      if (r > 0.35 && r < 0.40) ty = midY - sin((r - 0.35) / 0.05 * pi) * 8;
      else if (r > 0.42 && r < 0.45) ty = midY + sin((r - 0.42) / 0.03 * pi) * 6;
      else if (r > 0.45 && r < 0.53) ty = midY - sin((r - 0.45) / 0.08 * pi) * 35;
      else if (r > 0.53 && r < 0.58) ty = midY + sin((r - 0.53) / 0.05 * pi) * 12;
      else if (r > 0.62 && r < 0.70) ty = midY - sin((r - 0.62) / 0.08 * pi) * 10;

      // Solid dot
      canvas.drawCircle(Offset(tx, ty), 5, Paint()..color = const Color(0xFF3B82F6));
    }
  }

  @override
  bool shouldRepaint(_ECGPainter old) => old.progress != progress;
}

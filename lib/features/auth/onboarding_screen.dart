import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Gradient Background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4A9FFF), // Deeper blue at top
                    Color(0xFF8ABEF9), // Lighter blue
                    Color(0xFFE6EDF5), // Light grayish blue at the bottom
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Background Circles (Behind Doctor) ──
          PositionedDirectional(
            top: size.height * 0.1,
            start: -size.width * 0.1,
            end: -size.width * 0.1,
            child: Container(
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          PositionedDirectional(
            top: size.height * 0.15,
            start: size.width * 0.05,
            end: size.width * 0.05,
            child: Container(
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          PositionedDirectional(
            top: size.height * 0.22,
            start: size.width * 0.2,
            end: size.width * 0.2,
            child: Container(
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),

          // ── Doctor Image ──
          PositionedDirectional(
            top: size.height * 0.08,
            start: -20,
            end: -20,
            bottom: size.height * 0.38, // Moved up from 0.35
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.75, 1.0], // Fades out the bottom 25% smoothly
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/doctor1.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0, duration: 800.ms),
          ),

          // ── Bottom Content ──
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: Container(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(28, 0, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Title: Smarter Health Better
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'smarter_health'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white, // White background
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'better'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF3B82F6), // Blue text
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  // Title: Doctors Everyday
                  Text(
                    'doctors_everyday'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'onboarding_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // Get Started Button
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6), // Bright blue
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFinished,
                        borderRadius: BorderRadius.circular(32),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 24, end: 8),
                          child: Row(
                            children: [
                              Text(
                                'get_started'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.north_east,
                                  color: Color(0xFF3B82F6),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

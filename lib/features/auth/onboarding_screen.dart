import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  /// Rabar for Kurdish/Arabic, Inter for Latin — set explicitly here so the
  /// screen never falls back to the system font.
  TextStyle _font({
    required bool isRtl,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    if (isRtl) {
      return TextStyle(
        fontFamily: 'Rabar',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    // Typography scales with the screen instead of being pinned to one device.
    // Rabar has a small x-height, so Kurdish/Arabic gets an extra bump.
    final scale = (size.width / 390).clamp(0.85, 1.15) * (isRtl ? 1.12 : 1.0);
    // Kurdish/Arabic glyphs need room to breathe — no negative tracking.
    final tracking = isRtl ? 0.0 : -0.5;

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

          // Cap the OS text scale so long translations can never overflow.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // ── Hero: circles + doctor, takes whatever the text leaves ──
                  Expanded(child: _buildHero()),

                  // ── Bottom Content ──
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      28,
                      0,
                      28,
                      24 * scale,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title: Smarter Health + Better badge
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'smarter_health'.tr(),
                                style: _font(
                                  isRtl: isRtl,
                                  fontSize: 30 * scale,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: tracking,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(width: 6 * scale),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14 * scale,
                                  vertical: 4 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white, // White background
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'better'.tr(),
                                  style: _font(
                                    isRtl: isRtl,
                                    fontSize: 28 * scale,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3B82F6), // Blue text
                                    letterSpacing: tracking,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        SizedBox(height: 8 * scale),

                        // Title: Doctors Everyday
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'doctors_everyday'.tr(),
                            style: _font(
                              isRtl: isRtl,
                              fontSize: 30 * scale,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1E293B),
                              letterSpacing: tracking,
                              height: 1.3,
                            ),
                          ),
                        )
                            .animate(delay: 400.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        SizedBox(height: 14 * scale),

                        // Subtitle
                        Text(
                          'onboarding_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: _font(
                            isRtl: isRtl,
                            fontSize: 17 * scale,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: isRtl ? 1.8 : 1.5,
                          ),
                        )
                            .animate(delay: 500.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        // Breathing room that shrinks on short screens.
                        SizedBox(height: (size.height * 0.055).clamp(20, 48)),

                        // Get Started Button
                        Container(
                          height: (64 * scale).clamp(56, 68),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6), // Bright blue
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.25),
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
                                padding: const EdgeInsetsDirectional.only(
                                  start: 24,
                                  end: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'get_started'.tr(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _font(
                                          isRtl: isRtl,
                                          fontSize: 21 * scale,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
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
                        )
                            .animate(delay: 600.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Circles + doctor, laid out against the space actually left over rather
  /// than against fixed fractions of the whole screen.
  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return ClipRect(
          child: Stack(
            children: [
              // ── Background Circles (Behind Doctor) ──
              _circle(top: h * 0.06, inset: -w * 0.1, diameter: w * 1.2, alpha: 0.1),
              _circle(top: h * 0.14, inset: w * 0.05, diameter: w * 0.9, alpha: 0.15),
              _circle(top: h * 0.26, inset: w * 0.2, diameter: w * 0.6, alpha: 0.2),

              // ── Doctor Image ──
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + h * 0.02,
                start: -20,
                end: -20,
                bottom: 0,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      // Fades out the bottom 25% smoothly
                      stops: [0.0, 0.75, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/doctor1.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: 0.1, end: 0, duration: 800.ms),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circle({
    required double top,
    required double inset,
    required double diameter,
    required double alpha,
  }) {
    return PositionedDirectional(
      top: top,
      start: inset,
      end: inset,
      child: Container(
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

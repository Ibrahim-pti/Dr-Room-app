import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  static const _ink = Color(0xFF0B1E33);
  static const _muted = Color(0xFF44586F);
  static const _blue = Color(0xFF2563EB);

  /// Natural aspect ratio of doctor1.png (505 × 768).
  static const _doctorAspect = 505 / 768;

  /// Rabar for Kurdish/Arabic, Inter for Latin — set explicitly so the screen
  /// never falls back to the system font.
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

    // Gentle scaling only — the layout stays calm across device sizes.
    final scale = (size.width / 390).clamp(0.92, 1.06);
    // Joined Kurdish/Arabic letterforms shouldn't be pulled together.
    final tracking = isRtl ? 0.0 : -0.4;

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
                    Color(0xFF57A6FF), // Deeper blue at top
                    Color(0xFF9CCAFB), // Lighter blue
                    Color(0xFFF1F5F9), // Almost white at the bottom
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),

          // Cap the OS text scale so long translations can never overflow.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // ── Hero: halo + doctor, takes whatever the text leaves ──
                  Expanded(child: _buildHero()),

                  // ── Bottom Content ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeadline(isRtl, scale, tracking),

                        SizedBox(height: 16 * scale),

                        // Subtitle — held to a comfortable measure.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: Text(
                            'onboarding_subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: _font(
                              isRtl: isRtl,
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              height: isRtl ? 2.05 : 1.7,
                            ),
                          ),
                        )
                            .animate(delay: 450.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.15, end: 0),

                        // Wide gap: pushes the text block up and the button down.
                        SizedBox(height: (size.height * 0.085).clamp(48, 92)),

                        _buildButton(isRtl, scale),
                      ],
                    ),
                  ),

                  // Button settles near the bottom edge.
                  SizedBox(height: (size.height * 0.035).clamp(22, 38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Two-line headline: a light first line, a bold second line, and the accent
  /// word resting in a soft white pill.
  Widget _buildHeadline(bool isRtl, double scale, double tracking) {
    final headline = _font(
      isRtl: isRtl,
      fontSize: 25 * scale,
      fontWeight: FontWeight.w500,
      color: _ink,
      letterSpacing: tracking,
      height: 1.4,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('smarter_health'.tr(), style: headline),
              SizedBox(width: 8 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'better'.tr(),
                  style: headline.copyWith(
                    color: _blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: 250.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.15, end: 0),

        SizedBox(height: 8 * scale),

        // Bold second line carries the weight — Rabar-Bold on Kurdish/Arabic.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'doctors_everyday'.tr(),
            style: headline.copyWith(fontWeight: FontWeight.w700),
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.15, end: 0),
      ],
    );
  }

  Widget _buildButton(bool isRtl, double scale) {
    final height = 58.0 * scale;
    final knob = height - 16;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C8DF6), Color(0xFF2F6FE0)],
          ),
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onFinished,
            borderRadius: BorderRadius.circular(height / 2),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 26, end: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'get_started'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        isRtl: isRtl,
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: isRtl ? 0 : 0.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Container(
                    width: knob,
                    height: knob,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.north_east,
                      color: _blue,
                      size: 20 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: 550.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.15, end: 0);
  }

  /// Doctor sized off her own aspect ratio, with concentric halo rings
  /// centred on her head rather than on arbitrary screen fractions.
  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final topInset = MediaQuery.paddingOf(context).top;

        // Keep her comfortably inside the frame on both tall and short screens.
        final imgW = math.min(w * 0.72, (h - topInset) * _doctorAspect);
        final imgH = imgW / _doctorAspect;

        // Her head sits roughly a fifth down from the top of the artwork.
        final haloCenterY = h - imgH + imgH * 0.20;

        return ClipRect(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _ring(w, haloCenterY, imgW * 1.75, 0.10),
              _ring(w, haloCenterY, imgW * 1.35, 0.14),
              _ring(w, haloCenterY, imgW * 0.98, 0.18),

              // ── Doctor Image ──
              Positioned(
                bottom: 0,
                width: imgW,
                height: imgH,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      // Fades out the bottom 22% smoothly
                      stops: [0.0, 0.78, 1.0],
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
                    .slideY(begin: 0.08, end: 0, duration: 800.ms),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double w, double centerY, double diameter, double alpha) {
    return Positioned(
      left: (w - diameter) / 2,
      top: centerY - diameter / 2,
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

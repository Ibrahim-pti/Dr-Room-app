import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _baseKurdish => GoogleFonts.notoNaskhArabic();

  // ─── Headings ─────────────────────────────────────────────
  static TextStyle headingXL = _baseKurdish.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headingLg = _baseKurdish.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headingMd = _baseKurdish.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle headingSm = _baseKurdish.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────
  static TextStyle bodyLg = _baseKurdish.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle bodyMd = _baseKurdish.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySm = _baseKurdish.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Labels ───────────────────────────────────────────────
  static TextStyle labelLg = _baseKurdish.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle labelMd = _baseKurdish.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle labelSm = _baseKurdish.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ─── Button ───────────────────────────────────────────────
  static TextStyle button = _baseKurdish.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.3,
  );
}

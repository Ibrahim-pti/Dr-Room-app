import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Blue ─────────────────────
  static const Color primary = Color(0xFF2E86DE);
  static const Color primaryLight = Color(0xFF54A0FF);
  static const Color primarySoft = Color(0xFFDBECFF);
  
  // ─── Background (Light Mode) ───────────────────
  static const Color backgroundLight = Color(0xFFF6F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightSecondary = Color(0xFFF0F4FA);

  // ─── Background (Dark Mode) ────────────────────
  static const Color backgroundDark = Color(0xFF0F172A); // Deep slate
  static const Color surfaceDark = Color(0xFF1E293B); // Slate card
  static const Color surfaceDarkSecondary = Color(0xFF334155);

  // ─── Text (Light Mode) ──────────────────────────
  static const Color textDark = Color(0xFF1A1F36);
  static const Color textMedium = Color(0xFF6E7191);
  static const Color textLight = Color(0xFFA0A3BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Text (Dark Mode) ───────────────────────────
  static const Color textDarkBg = Color(0xFFF8FAFC); // Almost white
  static const Color textMediumDarkBg = Color(0xFFCBD5E1);
  static const Color textLightDarkBg = Color(0xFF94A3B8);

  // ─── Status ───────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF2E86DE);

  // ─── Misc ─────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFEAEDF3);
  static const Color dividerDark = Color(0xFF334155);
  static const Color cardBorderLight = Color(0xFFE8ECF4);
  static const Color cardBorderDark = Color(0xFF334155);

  // ─── Helpers ─────────────────────────────────────────────
  static Color getBackground(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;
  
  static Color getSurface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;
      
  static Color getSurfaceSecondary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? surfaceDarkSecondary : surfaceLightSecondary;

  static Color getTextTitle(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textDarkBg : textDark;
      
  static Color getTextSubtitle(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? textMediumDarkBg : textMedium;
      
  static Color getDivider(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? dividerDark : dividerLight;
      
  static Color getBorder(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? cardBorderDark : cardBorderLight;
}

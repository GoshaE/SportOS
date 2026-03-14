import 'package:flutter/material.dart';

/// AppColors: The centralized source of truth for all colors in SportOS.
/// Usage: AppColors.primary, AppColors.success
class AppColors {
  // Brand Colors (Deep Indigo / Electric Blue)
  static const Color primary = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF312E81); // Indigo 900
  static const Color accent = Color(0xFF0EA5E9); // Sky 500

  // Neutral / Greyscale
  static const Color black = Color(0xFF0F172A); // Slate 900
  static const Color grey800 = Color(0xFF1E293B); // Slate 800
  static const Color grey600 = Color(0xFF475569); // Slate 600
  static const Color grey500 = Color(0xFF64748B); // Slate 500
  static const Color grey400 = Color(0xFF94A3B8); // Slate 400
  static const Color grey200 = Color(0xFFE2E8F0); // Slate 200
  static const Color grey100 = Color(0xFFF1F5F9); // Slate 100
  static const Color white = Color(0xFFFFFFFF);

  // Awards / Medals
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // Semantic Colors (Success, Error, Warning, Info)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color successDark = Color(0xFF047857); // Emerald 700

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorDark = Color(0x00b91c1c); // Red 700

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFFB45309); // Amber 700

  // Surfaces (Backgrounds, Cards)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White

  // Dark Mode specific
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceElevatedDark = Color(0xFF334155); // Slate 700
}

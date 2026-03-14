import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTypography: The centralized source of truth for all text styles in SportOS.
/// Uses Flutter's TextTheme mapping.
class AppTypography {
  static const String _fontFamily = 'Satoshi'; // Primary modern geometric sans-serif

  // Font features for tabular numbers (fixed width digits) in Satoshi
  static const List<FontFeature> _tabularFeatures = [FontFeature.tabularFigures()];

  // HEADING / DISPLAY: Bold, tight tracking
  static const TextStyle displayLarge = TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1, fontFeatures: _tabularFeatures);
  static const TextStyle displayMedium = TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w800, letterSpacing: -0.75, height: 1.15, fontFeatures: _tabularFeatures);
  static const TextStyle displaySmall = TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2, fontFeatures: _tabularFeatures);

  static const TextStyle headlineLarge = TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.25, height: 1.2, fontFeatures: _tabularFeatures);
  static const TextStyle headlineMedium = TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25, fontFeatures: _tabularFeatures);
  static const TextStyle headlineSmall = TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.15, height: 1.3, fontFeatures: _tabularFeatures);

  // TITLE: Medium-bold, neutral tracking
  static const TextStyle titleLarge = TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0.0, height: 1.3, fontFeatures: _tabularFeatures);
  static const TextStyle titleMedium = TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4, fontFeatures: _tabularFeatures);
  static const TextStyle titleSmall = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.05, height: 1.4, fontFeatures: _tabularFeatures);

  // BODY: Regular weight, relaxed tracking, extra height (leading) for readability
  static const TextStyle bodyLarge = TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.5, fontFeatures: _tabularFeatures);
  static const TextStyle bodyMedium = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.45, fontFeatures: _tabularFeatures);
  static const TextStyle bodySmall = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.4, fontFeatures: _tabularFeatures);

  // LABEL: Medium weight, wide tracking for small utility text (buttons, badges)
  static const TextStyle labelLarge = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.3, height: 1.2, fontFeatures: _tabularFeatures);
  static const TextStyle labelMedium = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.4, height: 1.2, fontFeatures: _tabularFeatures);
  static const TextStyle labelSmall = TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.2, fontFeatures: _tabularFeatures);

  /// Specific token for Chronometry (Split times, Finish times)
  static TextStyle get monoTiming => GoogleFonts.jetBrainsMono(
    fontSize: 24, // Configurable per use-case, but base weight/spacing defined here
    fontWeight: FontWeight.w700, // JetBrains Mono looks highly technical in bold
    letterSpacing: 1.5, 
    fontFeatures: _tabularFeatures,
  );
}

import 'package:flutter/material.dart';

/// SportOS Material 3 Theme
class SportOsTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1B5E20), // Deep Green — спортивная тема
      brightness: Brightness.light,
      fontFamily: 'Inter',
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1B5E20),
      brightness: Brightness.dark,
      fontFamily: 'Inter',
    );
  }
}

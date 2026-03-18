import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  /// Generate a light theme — Telegram-style: clean, flat, compact.
  static ThemeData lightTheme({required ColorScheme colorScheme}) {
    final cs = colorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,

      textTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: AppTypography.displayLarge.copyWith(color: cs.onSurface),
        displayMedium: AppTypography.displayMedium.copyWith(color: cs.onSurface),
        displaySmall: AppTypography.displaySmall.copyWith(color: cs.onSurface),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: cs.onSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: cs.onSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: cs.onSurface),
        titleLarge: AppTypography.titleLarge.copyWith(color: cs.onSurface),
        titleMedium: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant),
        titleSmall: AppTypography.titleSmall.copyWith(color: cs.onSurfaceVariant),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: cs.onSurfaceVariant),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        bodySmall: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: cs.onSurface),
        labelMedium: AppTypography.labelMedium.copyWith(color: cs.onSurface),
        labelSmall: AppTypography.labelSmall.copyWith(color: cs.onSurface),
      ),

      // ── Cards: Telegram-style flat cells ──
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
        ),
        color: cs.surfaceContainerLow,
        margin: EdgeInsets.zero,
      ),

      // ── Inputs: Clean, minimal borders ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      ),

      // ── AppBar: Clean ──
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: cs.onSurface),
      ),

      // ── ListTile: Compact Telegram-style ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minVerticalPadding: 4,
        dense: true,
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w400),
        subtitleTextStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
      ),

      // ── Divider: Thin Telegram-style ──
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.2),
        thickness: 0.5,
        indent: 16,
        endIndent: 0,
      ),

      // ── BottomSheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
        showDragHandle: true,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),

      // ── Chips: Compact ──
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      // ── Switch: iOS/Telegram-like ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.3)),
      ),

      // ── Radio: Compact ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.outline),
        visualDensity: VisualDensity.compact,
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        visualDensity: VisualDensity.compact,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── SegmentedButton ──
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  /// Generate a dark theme — Telegram-style: clean, flat, compact.
  static ThemeData darkTheme({required ColorScheme colorScheme}) {
    final cs = colorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,

      textTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: AppTypography.displayLarge.copyWith(color: cs.onSurface),
        displayMedium: AppTypography.displayMedium.copyWith(color: cs.onSurface),
        displaySmall: AppTypography.displaySmall.copyWith(color: cs.onSurface),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: cs.onSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: cs.onSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: cs.onSurface),
        titleLarge: AppTypography.titleLarge.copyWith(color: cs.onSurface),
        titleMedium: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant),
        titleSmall: AppTypography.titleSmall.copyWith(color: cs.onSurfaceVariant),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: cs.onSurfaceVariant),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        bodySmall: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: cs.onSurface),
        labelMedium: AppTypography.labelMedium.copyWith(color: cs.onSurface),
        labelSmall: AppTypography.labelSmall.copyWith(color: cs.onSurface),
      ),

      // ── Cards: Dark Telegram cells ──
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.12)),
        ),
        color: cs.surfaceContainerHigh,
        margin: EdgeInsets.zero,
      ),

      // ── Inputs: Dark clean ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: cs.onSurface),
      ),

      // ── ListTile: Compact ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minVerticalPadding: 4,
        dense: true,
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w400),
        subtitleTextStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
      ),

      // ── Divider: Thin ──
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.15),
        thickness: 0.5,
        indent: 16,
        endIndent: 0,
      ),

      // ── BottomSheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
        showDragHandle: true,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── Chips: Compact ──
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      // ── Switch: iOS/Telegram-like ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.2)),
      ),

      // ── Radio ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.outline),
        visualDensity: VisualDensity.compact,
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        visualDensity: VisualDensity.compact,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── SegmentedButton ──
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

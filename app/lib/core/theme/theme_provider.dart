import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════
// ARCHITECTURE:
//   1. BasePreset  — neutral surface/background palette (Zinc, Slate)
//   2. AccentColor — user-selected primary/accent color
//   3. ThemeState   — combines preset + accent + mode
//
// The preset defines the "feel" of the app (surfaces, text, outlines).
// The accent color defines the interactive elements (buttons, links, chips).
// This prevents "everything is green" when switching themes.
// ═══════════════════════════════════════

// ────────────────────────────────────
// Base Presets — neutral surface palettes
// ────────────────────────────────────

class BasePreset {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  /// Neutral light scheme — NO primary/secondary set, those come from accent
  final NeutralPalette light;
  /// Neutral dark scheme
  final NeutralPalette dark;

  const BasePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.light,
    required this.dark,
  });
}

/// Surface-only palette (no primary colors — those are injected from accent)
class NeutralPalette {
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  const NeutralPalette({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });
}

// Tailwind Zinc scale
const _zincLight = NeutralPalette(
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF09090B),          // zinc-950
  onSurfaceVariant: Color(0xFF71717A),   // zinc-500
  outline: Color(0xFFA1A1AA),            // zinc-400
  outlineVariant: Color(0xFFE4E4E7),     // zinc-200
  surfaceContainerLow: Color(0xFFFAFAFA),  // zinc-50
  surfaceContainerHigh: Color(0xFFF4F4F5), // zinc-100
  surfaceContainerHighest: Color(0xFFE4E4E7), // zinc-200
);

const _zincDark = NeutralPalette(
  surface: Color(0xFF09090B),            // zinc-950
  onSurface: Color(0xFFFAFAFA),          // zinc-50
  onSurfaceVariant: Color(0xFFA1A1AA),   // zinc-400
  outline: Color(0xFF52525B),            // zinc-600
  outlineVariant: Color(0xFF27272A),     // zinc-800
  surfaceContainerLow: Color(0xFF0F0F12),
  surfaceContainerHigh: Color(0xFF18181B), // zinc-900
  surfaceContainerHighest: Color(0xFF27272A), // zinc-800
);

// Tailwind Slate scale — slightly blue-tinted neutrals
const _slateLight = NeutralPalette(
  surface: Color(0xFFF8FAFC),            // slate-50
  onSurface: Color(0xFF0F172A),          // slate-900
  onSurfaceVariant: Color(0xFF64748B),   // slate-500
  outline: Color(0xFF94A3B8),            // slate-400
  outlineVariant: Color(0xFFE2E8F0),     // slate-200
  surfaceContainerLow: Color(0xFFF1F5F9),  // slate-100
  surfaceContainerHigh: Color(0xFFE2E8F0), // slate-200
  surfaceContainerHighest: Color(0xFFCBD5E1), // slate-300
);

const _slateDark = NeutralPalette(
  surface: Color(0xFF020617),            // slate-950
  onSurface: Color(0xFFF8FAFC),          // slate-50
  onSurfaceVariant: Color(0xFF94A3B8),   // slate-400
  outline: Color(0xFF475569),            // slate-600
  outlineVariant: Color(0xFF1E293B),     // slate-800
  surfaceContainerLow: Color(0xFF0B1120),
  surfaceContainerHigh: Color(0xFF0F172A), // slate-900
  surfaceContainerHighest: Color(0xFF1E293B), // slate-800
);

final basePresets = <BasePreset>[
  const BasePreset(
    id: 'zinc',
    name: 'Цинк',
    subtitle: 'Чистый нейтральный',
    icon: Icons.contrast,
    light: _zincLight,
    dark: _zincDark,
  ),
  const BasePreset(
    id: 'slate',
    name: 'Сланец',
    subtitle: 'С лёгким синим оттенком',
    icon: Icons.water_drop,
    light: _slateLight,
    dark: _slateDark,
  ),
];

// ────────────────────────────────────
// Accent Colors — user-selected primary
// shadcn-inspired accent palette
// ────────────────────────────────────

class AccentColor {
  final String id;
  final String name;
  final Color color;        // The main accent color
  final Color lightOn;      // Text on accent in light mode
  final Color darkVariant;  // Lighter variant for dark mode

  const AccentColor({
    required this.id,
    required this.name,
    required this.color,
    this.lightOn = Colors.white,
    required this.darkVariant,
  });
}

final accentColors = <AccentColor>[
  const AccentColor(id: 'green',   name: 'Зелёный',    color: Color(0xFF15803D), darkVariant: Color(0xFF22C55E)),   // green-700 → green-500
  const AccentColor(id: 'blue',    name: 'Синий',       color: Color(0xFF1D4ED8), darkVariant: Color(0xFF3B82F6)),   // blue-700 → blue-500
  const AccentColor(id: 'violet',  name: 'Фиолетовый', color: Color(0xFF6D28D9), darkVariant: Color(0xFF8B5CF6)),   // violet-700 → violet-500
  const AccentColor(id: 'rose',    name: 'Роза',        color: Color(0xFFBE123C), darkVariant: Color(0xFFF43F5E)),   // rose-700 → rose-500
  const AccentColor(id: 'orange',  name: 'Оранжевый',  color: Color(0xFFC2410C), darkVariant: Color(0xFFF97316)),   // orange-700 → orange-500
  const AccentColor(id: 'yellow',  name: 'Жёлтый',     color: Color(0xFFA16207), darkVariant: Color(0xFFEAB308)),   // yellow-700 → yellow-500
];

// ────────────────────────────────────
// Build final ColorScheme by combining preset + accent
// ────────────────────────────────────

ColorScheme buildColorScheme({
  required NeutralPalette neutral,
  required AccentColor accent,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? accent.darkVariant : accent.color;
  final onPrimary = isDark ? const Color(0xFF09090B) : accent.lightOn;

  // Derive container colors from the primary
  final primaryContainer = isDark
      ? Color.lerp(primary, Colors.black, 0.7)!
      : Color.lerp(primary, Colors.white, 0.85)!;
  final onPrimaryContainer = isDark
      ? Color.lerp(primary, Colors.white, 0.6)!
      : Color.lerp(primary, Colors.black, 0.7)!;

  // Secondary = muted version of primary
  final secondary = isDark
      ? Color.lerp(primary, neutral.onSurfaceVariant, 0.4)!
      : Color.lerp(primary, neutral.onSurfaceVariant, 0.5)!;
  final onSecondary = isDark ? Colors.black : Colors.white;
  final secondaryContainer = isDark
      ? Color.lerp(secondary, Colors.black, 0.7)!
      : Color.lerp(secondary, Colors.white, 0.85)!;
  final onSecondaryContainer = isDark
      ? Color.lerp(secondary, Colors.white, 0.6)!
      : Color.lerp(secondary, Colors.black, 0.7)!;

  // Tertiary = softer complementary
  final tertiary = neutral.onSurfaceVariant;
  final onTertiary = isDark ? Colors.black : Colors.white;

  // Error containers — must be explicit for dart2js (auto-generated getters
  // can be mangled by minification / tree-shaking in release web builds).
  final errorColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
  final errorContainer = isDark
      ? Color.lerp(errorColor, Colors.black, 0.7)!
      : Color.lerp(errorColor, Colors.white, 0.85)!;
  final onErrorContainer = isDark
      ? Color.lerp(errorColor, Colors.white, 0.6)!
      : Color.lerp(errorColor, Colors.black, 0.7)!;

  // Surface containers — derive missing tiers from existing palette.
  final surfaceContainer = Color.lerp(
    neutral.surfaceContainerLow, neutral.surfaceContainerHigh, 0.5)!;
  final surfaceContainerLowest = isDark
      ? Color.lerp(neutral.surface, Colors.black, 0.3)!
      : Color.lerp(neutral.surface, Colors.white, 0.5)!;

  return ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: neutral.surfaceContainerHighest,
    onTertiaryContainer: neutral.onSurface,
    error: errorColor,
    onError: isDark ? const Color(0xFF7F1D1D) : Colors.white,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: neutral.surface,
    onSurface: neutral.onSurface,
    onSurfaceVariant: neutral.onSurfaceVariant,
    outline: neutral.outline,
    outlineVariant: neutral.outlineVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainer: surfaceContainer,
    surfaceContainerLow: neutral.surfaceContainerLow,
    surfaceContainerHigh: neutral.surfaceContainerHigh,
    surfaceContainerHighest: neutral.surfaceContainerHighest,
  );
}

// ────────────────────────────────────
// Helpers
// ────────────────────────────────────

BasePreset getPresetById(String id) =>
    basePresets.firstWhere((p) => p.id == id, orElse: () => basePresets.first);

AccentColor getAccentById(String id) =>
    accentColors.firstWhere((a) => a.id == id, orElse: () => accentColors.first);

// ═══════════════════════════════════════
// Theme State + Notifier
// ═══════════════════════════════════════

class ThemeState {
  final ThemeMode mode;
  final String presetId;
  final String accentId;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.presetId = 'zinc',
    this.accentId = 'green',
  });

  BasePreset get preset => getPresetById(presetId);
  AccentColor get accent => getAccentById(accentId);

  ColorScheme get lightScheme => buildColorScheme(
    neutral: preset.light,
    accent: accent,
    brightness: Brightness.light,
  );

  ColorScheme get darkScheme => buildColorScheme(
    neutral: preset.dark,
    accent: accent,
    brightness: Brightness.dark,
  );

  ThemeState copyWith({ThemeMode? mode, String? presetId, String? accentId}) =>
      ThemeState(
        mode: mode ?? this.mode,
        presetId: presetId ?? this.presetId,
        accentId: accentId ?? this.accentId,
      );
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeState> {
  static const _fileName = 'theme_settings.json';

  @override
  ThemeState build() {
    // Загружаем сохранённые настройки асинхронно
    _load();
    return const ThemeState();
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void setPreset(String id) {
    state = state.copyWith(presetId: id);
    _save();
  }

  void setAccent(String id) {
    state = state.copyWith(accentId: id);
    _save();
  }

  bool get isDark => state.mode == ThemeMode.dark;
  bool get isSystem => state.mode == ThemeMode.system;

  // ── Persistence ──

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (!f.existsSync()) return;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      state = ThemeState(
        mode: ThemeMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ThemeMode.system,
        ),
        presetId: json['presetId'] as String? ?? 'zinc',
        accentId: json['accentId'] as String? ?? 'green',
      );
    } catch (_) {
      // Первый запуск или повреждённый файл — используем дефолты
    }
  }

  Future<void> _save() async {
    try {
      final f = await _file;
      final json = jsonEncode({
        'mode': state.mode.name,
        'presetId': state.presetId,
        'accentId': state.accentId,
      });
      await f.writeAsString(json);
    } catch (_) {
      // Не критично — настройки просто не сохранятся
    }
  }
}

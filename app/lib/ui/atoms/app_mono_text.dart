import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// AppMonoText: Monospace timing text atom.
///
/// Standardizes all timing displays (results, gaps, pace, clock)
/// with consistent font, weight, and color.
///
/// Usage:
/// ```dart
/// AppMonoText('05:30.456')
/// AppMonoText('05:30.456', size: MonoSize.large, bold: true)
/// AppMonoText('+0:15.2', color: cs.error)
/// ```

enum MonoSize {
  small,  // 11px — inline chip labels
  medium, // 13px — table cells, default
  large,  // 15px — card highlights
  hero,   // 20px — podium, main time
}

class AppMonoText extends StatelessWidget {
  final String text;
  final MonoSize size;
  final bool bold;
  final Color? color;
  final TextAlign textAlign;

  const AppMonoText(
    this.text, {
    super.key,
    this.size = MonoSize.medium,
    this.bold = false,
    this.color,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    final (fontSize, letterSpacing) = _sizeValues();

    return Text(
      text,
      textAlign: textAlign,
      style: AppTypography.monoTiming.copyWith(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
        color: resolvedColor,
        letterSpacing: letterSpacing,
      ),
    );
  }

  (double fontSize, double letterSpacing) _sizeValues() => switch (size) {
    MonoSize.small  => (11.0, 0.3),
    MonoSize.medium => (13.0, 0.5),
    MonoSize.large  => (15.0, 0.5),
    MonoSize.hero   => (20.0, 0.8),
  };
}

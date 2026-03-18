import 'package:flutter/material.dart';

/// Semantic type for chip coloring.
enum ChipType {
  neutral,   // Grey — default, informational
  primary,   // Primary color — selected, active
  success,   // Green — ok, verified, paid
  warning,   // Orange/amber — attention needed
  error,     // Red — DNS, DNF, debt
  info,      // Blue — info, ongoing
}

/// Chip variant (visual weight).
enum ChipVariant {
  filled,    // Solid background
  tinted,    // Light background, strong text
  outlined,  // Border only, transparent bg
}

/// Chip size.
enum ChipSize {
  small,     // 10px font, 4×6 padding — inline labels
  medium,    // 12px font, 4×8 padding — default
  large,     // 14px font, 6×12 padding — prominent
}

/// AppChip: Universal chip/badge/tag atom.
///
/// Replaces 15+ inline Container+Text patterns scattered across
/// EventCard, ClubCard, InfoPanel, ResultTable, etc.
///
/// Usage:
/// ```dart
/// AppChip(text: 'LIVE', type: ChipType.error)
/// AppChip.icon(Icons.pets, 'Ездовой', type: ChipType.primary)
/// AppChip(text: 'DNS', type: ChipType.error, variant: ChipVariant.filled)
/// ```
class AppChip extends StatelessWidget {
  final String text;
  final ChipType type;
  final ChipVariant variant;
  final ChipSize size;
  final IconData? icon;
  final bool uppercase;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.text,
    this.type = ChipType.neutral,
    this.variant = ChipVariant.tinted,
    this.size = ChipSize.medium,
    this.icon,
    this.uppercase = false,
    this.onTap,
  });

  /// Convenience: chip with leading icon.
  factory AppChip.icon(
    IconData icon,
    String text, {
    Key? key,
    ChipType type = ChipType.neutral,
    ChipVariant variant = ChipVariant.tinted,
    ChipSize size = ChipSize.medium,
    VoidCallback? onTap,
  }) {
    return AppChip(
      key: key,
      text: text,
      type: type,
      variant: variant,
      size: size,
      icon: icon,
      onTap: onTap,
    );
  }

  /// Convenience: status badge (filled, uppercase, small).
  factory AppChip.status(
    String text, {
    Key? key,
    ChipType type = ChipType.neutral,
  }) {
    return AppChip(
      key: key,
      text: text,
      type: type,
      variant: ChipVariant.filled,
      size: ChipSize.small,
      uppercase: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(cs);
    final border = variant == ChipVariant.outlined
        ? Border.all(color: fg.withValues(alpha: 0.4), width: 1)
        : null;
    final resolvedBg = variant == ChipVariant.outlined
        ? Colors.transparent
        : bg;

    final (fontSize, hPad, vPad, iconSize) = _sizeValues();
    final displayText = uppercase ? text.toUpperCase() : text;

    Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            SizedBox(width: size == ChipSize.small ? 3 : 4),
          ],
          Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: uppercase ? 0.5 : 0,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chip = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: chip,
      );
    }

    return chip;
  }

  (Color bg, Color fg) _colors(ColorScheme cs) => switch (type) {
    ChipType.neutral => (
      cs.surfaceContainerHighest,
      cs.onSurfaceVariant,
    ),
    ChipType.primary => (
      variant == ChipVariant.filled
          ? cs.primary
          : cs.primaryContainer.withValues(alpha: 0.3),
      variant == ChipVariant.filled ? cs.onPrimary : cs.primary,
    ),
    ChipType.success => (
      variant == ChipVariant.filled
          ? cs.tertiary
          : cs.tertiaryContainer.withValues(alpha: 0.3),
      variant == ChipVariant.filled ? cs.onTertiary : cs.tertiary,
    ),
    ChipType.warning => (
      variant == ChipVariant.filled
          ? cs.secondary
          : cs.secondaryContainer.withValues(alpha: 0.3),
      variant == ChipVariant.filled ? cs.onSecondary : cs.secondary,
    ),
    ChipType.error => (
      variant == ChipVariant.filled
          ? cs.error
          : cs.errorContainer.withValues(alpha: 0.3),
      variant == ChipVariant.filled ? cs.onError : cs.error,
    ),
    ChipType.info => (
      variant == ChipVariant.filled
          ? cs.primaryContainer
          : cs.primaryContainer.withValues(alpha: 0.2),
      variant == ChipVariant.filled
          ? cs.onPrimaryContainer
          : cs.onPrimaryContainer,
    ),
  };

  (double fontSize, double hPad, double vPad, double iconSize) _sizeValues() => switch (size) {
    ChipSize.small  => (10.0, 6.0, 3.0, 12.0),
    ChipSize.medium => (12.0, 8.0, 4.0, 14.0),
    ChipSize.large  => (14.0, 12.0, 6.0, 16.0),
  };
}

import 'package:flutter/material.dart';

enum BadgeType {
  success,    // Green (Paid, Vet Check OK)
  warning,    // Orange/Amber (Missing docs, partial)
  error,      // Red (DNS, DNF, Debt)
  info,       // Blue (Selected, Ongoing)
  neutral     // Grey (Not started, Waiting)
}

/// StatusBadge: Universal status chip for SportOS
/// Uses theme-aware semantic colors that adapt to light/dark mode.
class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
    this.icon,
  });

  (Color, Color) _colors(ColorScheme cs) => switch (type) {
    BadgeType.neutral => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    BadgeType.success => (cs.tertiary, cs.onTertiary),
    BadgeType.warning => (cs.secondary, cs.onSecondary),
    BadgeType.error   => (cs.error, cs.onError),
    BadgeType.info    => (cs.primaryContainer, cs.onPrimaryContainer),     // Use primaryContainer for info so it's not as loud as error
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6), // RoundedSquare signifies non-clickable label
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 12, // Bumped from 10 to 12 for outdoor glanceability
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

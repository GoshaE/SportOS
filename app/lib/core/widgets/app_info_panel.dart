import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// AppInfoPanel: Operational info bar for race screens.
///
/// Replaces 5+ ad-hoc Container(color:surfaceContainerHighest)+Row
/// across starter, finish, start_list, vet_check, participants screens.
///
/// Usage:
/// ```dart
/// AppInfoPanel(
///   children: [
///     AppInfoPanel.icon(Icons.flag, 'Sprint 5km'),
///     AppInfoPanel.badge('Мастер Времени', cs.primary),
///     AppInfoPanel.timer('01:23:45'),
///     AppInfoPanel.count('2/35'),
///   ],
/// )
/// ```
class AppInfoPanel extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const AppInfoPanel({
    super.key,
    required this.children,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// Icon + label item
  static Widget icon(IconData iconData, String label) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(iconData, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
      ]);
    });
  }

  /// Colored badge pill
  static Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cell_tower, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, height: 1.1)),
      ]),
    );
  }

  /// Monospace timer display
  static Widget timer(String time) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Text(
        '⏱ $time',
        style: AppTypography.monoTiming.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      );
    });
  }

  /// Counter display (e.g. "2/35")
  static Widget count(String value) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Text(value, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    });
  }

  /// Stat item with value + label
  static Widget stat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: backgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: padding,
      child: Row(
        children: children.expand((child) sync* {
          yield child;
          yield const SizedBox(width: 12);
        }).toList()..removeLast(),
      ),
    );
  }
}

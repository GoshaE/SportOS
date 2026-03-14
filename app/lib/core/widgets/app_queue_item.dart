import 'package:flutter/material.dart';

/// AppQueueItem: Styled list item for operational queues (starter, finish, vet).
///
/// Provides consistent background coloring by status and standardized layout
/// for items in race operation screens.
///
/// Usage:
/// ```dart
/// AppQueueItem(
///   leading: Icon(Icons.check_circle, color: cs.primary),
///   title: Text('BIB 07 — Петров А.А.'),
///   subtitle: Text('Ушёл'),
///   onTap: () {},
///   backgroundColor: cs.primaryContainer.withAlpha(13),
/// )
/// ```
class AppQueueItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;

  const AppQueueItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: ListTile(
        dense: dense,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

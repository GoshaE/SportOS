import 'package:flutter/material.dart';

/// AppSectionHeader: Section title with optional trailing action.
///
/// Usage:
/// ```dart
/// AppSectionHeader(title: 'Мои собаки', action: 'Добавить', onAction: () => ...)
/// AppSectionHeader(title: 'Результаты', icon: Icons.emoji_events)
/// ```
class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.action,
    this.onAction,
    this.actionIcon,
    this.padding = const EdgeInsets.only(left: 4, right: 4, top: 16, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom to stick to the list
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (action != null)
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add, size: 16),
              label: Text(action!, style: theme.textTheme.labelMedium),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
        ],
      ),
    );
  }
}

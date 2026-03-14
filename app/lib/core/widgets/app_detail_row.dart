import 'package:flutter/material.dart';

/// AppDetailRow: Key-value display row for detail screens.
///
/// Usage:
/// ```dart
/// AppDetailRow(label: 'Город', value: 'Екатеринбург')
/// AppDetailRow(label: 'Телефон', value: '+7 912 345-67-89', icon: Icons.phone)
/// AppDetailRow(label: 'Email', value: 'alex@example.com', copyable: true)
/// ```
class AppDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool copyable;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.copyable = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                )),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onTap,
                  child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  )),
                ),
              ],
            ),
          ),
          ?trailing,
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              onPressed: () {
                // Clipboard integration handled by caller
              },
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// AppToggle: Apple-style toggle switch with label.
///
/// Replaces raw `Switch` + `SwitchListTile` patterns.
///
/// Usage:
/// ```dart
/// AppToggle(label: 'Включить уведомления', value: true, onChanged: (v) => ...)
/// AppToggle(label: 'Авто-старт', subtitle: 'Включать GPS автоматически', value: false, onChanged: ...)
/// ```
class AppToggle extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final bool enabled;

  const AppToggle({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

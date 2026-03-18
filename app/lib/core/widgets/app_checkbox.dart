import 'package:flutter/material.dart';

/// AppCheckbox: Checkbox with label in a tappable row.
///
/// Replaces raw `Checkbox` + `CheckboxListTile` patterns.
///
/// Usage:
/// ```dart
/// AppCheckbox(label: 'Согласен с правилами', value: true, onChanged: (v) => ...)
/// AppCheckbox(label: 'Показать DNS', subtitle: 'Не стартовавшие', value: false, onChanged: ...)
/// ```
class AppCheckbox extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool tristate;

  const AppCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.tristate = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox.adaptive(
                value: value,
                onChanged: enabled
                    ? (v) => onChanged?.call(v ?? false)
                    : null,
                tristate: tristate,
                activeColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
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
          ],
        ),
      ),
    );
  }
}

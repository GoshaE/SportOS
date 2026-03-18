import 'package:flutter/material.dart';
import 'app_bottom_sheet.dart';

/// Item for AppSelect
class SelectItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SelectItem({required this.value, required this.label, this.icon});
}

/// AppSelect: Apple-inspired select / dropdown replacement.
///
/// Looks like a text field, taps to open a bottom sheet with options.
///
/// Usage:
/// ```dart
/// AppSelect<String>(
///   label: 'Пол',
///   value: selectedGender,
///   items: [
///     SelectItem(value: 'male', label: 'Мужской'),
///     SelectItem(value: 'female', label: 'Женский'),
///   ],
///   onChanged: (v) => setState(() => selectedGender = v),
/// )
/// ```
class AppSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<SelectItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? placeholder;
  final String? hintText;
  final String? helperText;
  final bool enabled;

  const AppSelect({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.placeholder,
    this.hintText,
    this.helperText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;

    // Find current label
    final currentItem = items.where((i) => i.value == value).firstOrNull;
    final displayText = currentItem?.label ?? hintText ?? placeholder ?? 'Выберите...';
    final isPlaceholder = currentItem == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label above ──
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),

        // ── Select trigger ──
        InkWell(
          onTap: enabled ? () => _showOptions(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: inputTheme.enabledBorder is OutlineInputBorder
                    ? (inputTheme.enabledBorder as OutlineInputBorder).borderSide.color
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 15,
                    color: isPlaceholder
                        ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                        : cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ]),
          ),
        ),

        // ── Helper text ──
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  void _showOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.value == value;

          return ListTile(
            leading: item.icon != null
                ? Icon(item.icon, color: isSelected ? cs.primary : cs.onSurfaceVariant)
                : null,
            title: Text(
              item.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_rounded, color: cs.primary, size: 20)
                : null,
            onTap: () {
              onChanged?.call(item.value);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}

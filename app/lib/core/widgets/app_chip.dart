import 'package:flutter/material.dart';

/// AppChip: Unified chip component for tags, filters, and selections.
///
/// Replaces raw `Chip`, `ChoiceChip`, `FilterChip`, `InputChip`.
///
/// Usage:
/// ```dart
/// AppChip(label: 'Каникросс', selected: true, onTap: () => ...)
/// AppChip.filter(label: 'Мужской', selected: true, onSelected: (v) => ...)
/// AppChip.deletable(label: 'Иван Петров', onDeleted: () => ...)
/// ```
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final IconData? icon;
  final Color? selectedColor;
  final bool enabled;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onSelected,
    this.onDeleted,
    this.icon,
    this.selectedColor,
    this.enabled = true,
  });

  /// Choice-style chip with selected callback.
  factory AppChip.filter({
    Key? key,
    required String label,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    IconData? icon,
    Color? selectedColor,
  }) {
    return AppChip(
      key: key,
      label: label,
      selected: selected,
      onSelected: onSelected,
      icon: icon,
      selectedColor: selectedColor,
    );
  }

  /// Chip with delete button.
  factory AppChip.deletable({
    Key? key,
    required String label,
    VoidCallback? onDeleted,
    IconData? icon,
  }) {
    return AppChip(
      key: key,
      label: label,
      onDeleted: onDeleted,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = selectedColor ?? cs.primary;

    if (onDeleted != null) {
      return InputChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 18) : null,
        onDeleted: enabled ? onDeleted : null,
        deleteIconColor: cs.onSurfaceVariant,
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      );
    }

    if (onSelected != null) {
      return FilterChip(
        label: Text(label),
        avatar: icon != null
            ? Icon(icon,
                size: 18,
                color: selected ? effectiveColor : cs.onSurfaceVariant)
            : null,
        selected: selected,
        onSelected: enabled ? onSelected : null,
        selectedColor: effectiveColor.withOpacity(0.15),
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide(
          color: selected
              ? effectiveColor.withOpacity(0.5)
              : cs.outlineVariant.withOpacity(0.3),
        ),
        checkmarkColor: effectiveColor,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? effectiveColor : cs.onSurface,
        ),
      );
    }

    return ChoiceChip(
      label: Text(label),
      avatar: icon != null && !selected
          ? Icon(icon, size: 18, color: cs.onSurfaceVariant)
          : null,
      selected: selected,
      onSelected: enabled
          ? (_) => onTap?.call()
          : null,
      selectedColor: effectiveColor.withOpacity(0.15),
      backgroundColor: cs.surfaceContainerHigh,
      side: BorderSide(
        color: selected
            ? effectiveColor.withOpacity(0.5)
            : cs.outlineVariant.withOpacity(0.3),
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? effectiveColor : cs.onSurface,
      ),
    );
  }
}

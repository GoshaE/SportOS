import 'package:flutter/material.dart';

/// Segment item for AppSegment.
class Segment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const Segment({required this.value, required this.label, this.icon});
}

/// AppSegment: Apple-style segmented control.
///
/// Replaces raw `SegmentedButton` with consistent styling.
///
/// Usage:
/// ```dart
/// AppSegment<String>(
///   segments: [
///     Segment(value: 'day', label: 'День'),
///     Segment(value: 'week', label: 'Неделя'),
///     Segment(value: 'month', label: 'Месяц'),
///   ],
///   selected: 'day',
///   onChanged: (v) => setState(() => _period = v),
/// )
/// ```
class AppSegment<T> extends StatelessWidget {
  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expanded;

  const AppSegment({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SegmentedButton<T>(
      segments: segments.map((s) {
        return ButtonSegment<T>(
          value: s.value,
          label: Text(s.label),
          icon: s.icon != null ? Icon(s.icon, size: 18) : null,
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.onPrimary;
          }
          return cs.onSurfaceVariant;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

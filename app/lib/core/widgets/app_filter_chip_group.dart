import 'package:flutter/material.dart';

/// AppFilterChipGroup: A horizontal scrollable group of filter chips.
///
/// Usage:
/// ```dart
/// AppFilterChipGroup(
///   items: ['Скиджоринг', 'Каникросс', 'Байкджоринг'],
///   selected: {'Скиджоринг'},
///   onChanged: (selected) => setState(() => _selected = selected),
/// )
///
/// // Single-select mode:
/// AppFilterChipGroup.single(
///   items: ['Все', 'Оплачено', 'Долг'],
///   selected: 'Все',
///   onChanged: (value) => setState(() => _filter = value),
/// )
/// ```
class AppFilterChipGroup extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const AppFilterChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  /// Single-select convenience constructor.
  static Widget single({
    Key? key,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onChanged,
    bool scrollable = true,
  }) {
    return _AppSingleFilterChipGroup(
      key: key,
      items: items,
      selected: selected,
      onChanged: onChanged,
      scrollable: scrollable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) {
      final isSelected = selected.contains(item);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (sel) {
            final newSelected = Set<String>.from(selected);
            if (sel) {
              newSelected.add(item);
            } else {
              newSelected.remove(item);
            }
            onChanged(newSelected);
          },
          showCheckmark: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(children: chips),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}

class _AppSingleFilterChipGroup extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool scrollable;

  const _AppSingleFilterChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) {
      final isSelected = item == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onChanged(item),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: chips),
      );
    }

    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}

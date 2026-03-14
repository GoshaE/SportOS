import 'package:flutter/material.dart';

/// AppDisciplineChips: Horizontal scrollable discipline filter chips.
///
/// Replaces 5+ ad-hoc ChoiceChip/FilterChip scroll rows across
/// protocol, start_list, draw, participants, hub_search screens.
///
/// Usage:
/// ```dart
/// AppDisciplineChips(
///   items: ['Скидж. 5км', 'Скидж. 10км', 'Каникросс', 'Нарты'],
///   selected: 'Скидж. 5км',
///   onSelected: (disc) => setState(() => _disc = disc),
/// )
/// ```
class AppDisciplineChips extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;
  final bool showAll;
  final String allLabel;

  const AppDisciplineChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.showAll = false,
    this.allLabel = 'Все',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          if (showAll) Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(allLabel),
              selected: selected == null,
              onSelected: (_) => onSelected(allLabel),
            ),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(item, style: Theme.of(context).textTheme.labelSmall),
              selected: selected == item,
              onSelected: (_) => onSelected(item),
              visualDensity: VisualDensity.compact,
            ),
          )),
        ],
      ),
    );
  }
}

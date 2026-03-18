import 'package:flutter/material.dart';
import '../atoms/app_chip.dart';

/// AppChipGroup: Horizontal scrollable group of selectable chips.
///
/// Replaces:
/// - `AppDisciplineChips`
/// - `AppFilterChipGroup`
///
/// Usage:
/// ```dart
/// AppChipGroup(
///   items: ['Все', 'Спринт', 'Средняя', 'Фристайл'],
///   selected: 'Спринт',
///   onSelected: (value) => setState(() => _selected = value),
/// )
///
/// AppChipGroup.multi(
///   items: ['GPS', 'Фото', 'Видео'],
///   selected: {'GPS', 'Фото'},
///   onChanged: (set) => setState(() => _selected = set),
/// )
/// ```
class AppChipGroup extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String>? onSelected;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const AppChipGroup({
    super.key,
    required this.items,
    this.selected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) {
      final isSelected = item == selected;
      return AppChip(
        text: item,
        type: isSelected ? ChipType.primary : ChipType.neutral,
        variant: isSelected ? ChipVariant.filled : ChipVariant.outlined,
        onTap: onSelected != null ? () => onSelected!(item) : null,
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: chips.expand((chip) sync* {
            yield chip;
            yield const SizedBox(width: 8);
          }).toList()..removeLast(),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }
}

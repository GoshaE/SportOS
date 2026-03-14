import 'package:flutter/material.dart';

/// AppTabSwitcher: Styled segmented control for switching content views.
///
/// Usage:
/// ```dart
/// AppTabSwitcher(
///   tabs: ['День 1', 'День 2', 'Итог'],
///   selectedIndex: _current,
///   onChanged: (i) => setState(() => _current = i),
/// )
///
/// AppTabSwitcher.withIcons(
///   tabs: [
///     TabItem(icon: Icons.list, label: 'Список'),
///     TabItem(icon: Icons.grid_view, label: 'Сетка'),
///   ],
///   selectedIndex: _current,
///   onChanged: (i) => ...,
/// )
/// ```
class TabItem {
  final IconData? icon;
  final String label;

  const TabItem({this.icon, required this.label});
}

class AppTabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isExpanded;

  const AppTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.isExpanded = true,
  });

  /// Constructor with icons
  static Widget withIcons({
    Key? key,
    required List<TabItem> tabs,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    bool isExpanded = true,
  }) {
    return _AppTabSwitcherWithIcons(
      key: key,
      tabs: tabs,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      isExpanded: isExpanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (int i = 0; i < tabs.length; i++)
          ButtonSegment(value: i, label: Text(tabs[i])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (set) => onChanged(set.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _AppTabSwitcherWithIcons extends StatelessWidget {
  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isExpanded;

  const _AppTabSwitcherWithIcons({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (int i = 0; i < tabs.length; i++)
          ButtonSegment(
            value: i,
            label: Text(tabs[i].label),
            icon: tabs[i].icon != null ? Icon(tabs[i].icon, size: 18) : null,
          ),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (set) => onChanged(set.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// AppExpandableList: Shows a limited number of items with an animated
/// expand/collapse. Supports an optional [headerBuilder] for inline
/// expand/collapse button in the section header row.
///
/// Usage:
/// ```dart
/// // Inline header expand:
/// AppExpandableList<StartResult>(
///   items: allResults,
///   initialCount: 3,
///   itemBuilder: (item) => ResultCard(item),
///   expandLabel: 'стартов',
///   headerBuilder: (expandWidget) => Row(children: [
///     AppSectionHeader(title: 'Старты', icon: Icons.history),
///     const Spacer(),
///     expandWidget, // ← inline expand/collapse
///   ]),
/// )
/// ```
class AppExpandableList<T> extends StatefulWidget {
  /// Full list of items.
  final List<T> items;

  /// Number of items to show initially.
  final int initialCount;

  /// Builder for each item.
  final Widget Function(T item) itemBuilder;

  /// Noun label for the "show more" button, e.g. 'стартов' → "Ещё 9 стартов".
  final String? expandLabel;

  /// Custom expand button text override.
  final String? expandText;

  /// Custom collapse button text override.
  final String? collapseText;

  /// Duration of the expand/collapse animation.
  final Duration animationDuration;

  /// If provided, renders a header row with inline expand/collapse widget.
  /// The callback receives the expand/collapse widget to place anywhere in your header.
  /// When provided, the default centered expand button is replaced by this.
  final Widget Function(Widget expandToggle)? headerBuilder;

  const AppExpandableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 3,
    this.expandLabel,
    this.expandText,
    this.collapseText,
    this.animationDuration = const Duration(milliseconds: 300),
    this.headerBuilder,
  });

  @override
  State<AppExpandableList<T>> createState() => _AppExpandableListState<T>();
}

class _AppExpandableListState<T> extends State<AppExpandableList<T>>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = widget.items.length;
    final showCount = _expanded ? total : total.clamp(0, widget.initialCount);
    final hiddenCount = total - widget.initialCount;
    final needsExpand = total > widget.initialCount;

    // Expand/collapse toggle widget (reusable)
    Widget expandToggle = needsExpand
        ? InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _expanded
                      ? (widget.collapseText ?? 'Свернуть')
                      : (widget.expandText ?? _defaultExpandText(hiddenCount)),
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: widget.animationDuration,
                  child: Icon(Icons.expand_more, size: 18, color: cs.primary),
                ),
              ]),
            ),
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header (if provided)
        if (widget.headerBuilder != null) ...[
          widget.headerBuilder!(expandToggle),
          const SizedBox(height: 4),
        ],

        // Visible items
        AnimatedSize(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.items
                .take(showCount)
                .map((item) => widget.itemBuilder(item))
                .toList(),
          ),
        ),

        // Centered expand button (only if no headerBuilder)
        if (needsExpand && widget.headerBuilder == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: expandToggle,
          ),
      ],
    );
  }

  String _defaultExpandText(int count) {
    if (widget.expandLabel != null) {
      return 'Ещё $count ${widget.expandLabel}';
    }
    return 'Показать ещё ($count)';
  }
}

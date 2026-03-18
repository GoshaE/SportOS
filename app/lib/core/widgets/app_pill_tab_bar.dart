
import 'package:flutter/material.dart';

/// AppPillTabBar: Rounded tab bar with animated floating pill indicator.
///
/// Google-style sliding pill animation. The pill smoothly slides between
/// tabs using the TabController's animation value for frame-perfect motion.
///
/// Usage:
/// ```dart
/// AppPillTabBar(
///   controller: _tabController,
///   tabs: ['Дашборд', 'Взносы', 'Промокоды'],
/// )
/// ```
class AppPillTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// Explicit controller. If null, uses DefaultTabController.of(context).
  final TabController? controller;
  final List<String> tabs;
  final List<IconData>? icons;
  final bool isScrollable;
  final EdgeInsetsGeometry padding;
  final double height;

  const AppPillTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.icons,
    this.isScrollable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.height = 48,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final ctrl = controller ?? DefaultTabController.of(context);

    return SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: Container(
          clipBehavior: Clip.none, // Don't clip — pill handles its own radius
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: isScrollable
                ? _ScrollablePillTabs(controller: ctrl, tabs: tabs, icons: icons, cs: cs, theme: theme)
                : _FixedPillTabs(controller: ctrl, tabs: tabs, icons: icons, cs: cs, theme: theme),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Fixed-width tabs with smooth sliding pill
// ═══════════════════════════════════════════════
class _FixedPillTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final List<IconData>? icons;
  final ColorScheme cs;
  final ThemeData theme;

  const _FixedPillTabs({
    required this.controller,
    required this.tabs,
    this.icons,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const inset = 4.0;
    return Padding(
      padding: const EdgeInsets.all(inset),
      child: LayoutBuilder(builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;

        return AnimatedBuilder(
          animation: controller.animation ?? controller,
          builder: (context, _) {
            final animVal = controller.animation?.value ?? controller.index.toDouble();

            return Stack(
              children: [
                // ── Sliding pill ──
                Positioned(
                  left: animVal * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Tab labels row ──
                Row(
                  children: List.generate(tabs.length, (i) {
                    final selectedness = (1.0 - (animVal - i).abs()).clamp(0.0, 1.0);
                    final color = Color.lerp(cs.onSurfaceVariant, cs.onPrimary, selectedness)!;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.animateTo(i),
                        child: SizedBox.expand(
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icons != null && i < icons!.length) ...[
                                  Icon(icons![i], size: 15, color: color),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  tabs[i],
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: color,
                                    fontWeight: selectedness > 0.5 ? FontWeight.w700 : FontWeight.w500,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════
// Scrollable tabs with smooth sliding pill
// Uses GlobalKeys to measure tab widths and animate
// the pill position using controller.animation.
// Auto-scrolls to keep active tab visible.
// ═══════════════════════════════════════════════
class _ScrollablePillTabs extends StatefulWidget {
  final TabController controller;
  final List<String> tabs;
  final List<IconData>? icons;
  final ColorScheme cs;
  final ThemeData theme;

  const _ScrollablePillTabs({
    required this.controller,
    required this.tabs,
    this.icons,
    required this.cs,
    required this.theme,
  });

  @override
  State<_ScrollablePillTabs> createState() => _ScrollablePillTabsState();
}

class _ScrollablePillTabsState extends State<_ScrollablePillTabs> {
  final List<GlobalKey> _keys = [];
  final ScrollController _scroll = ScrollController();
  bool _measured = false;
  int _lastScrolledTo = -1;

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));
    widget.controller.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_measured) {
        setState(() => _measured = true);
        _scrollToTab(widget.controller.index, animate: false);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!widget.controller.indexIsChanging) return;
    _scrollToTab(widget.controller.index);
  }

  /// Auto-scroll so the active tab is visible with comfortable padding.
  void _scrollToTab(int index, {bool animate = true}) {
    if (!_scroll.hasClients || !mounted) return;
    if (index == _lastScrolledTo && animate) return;
    _lastScrolledTo = index;

    final tabRect = _getTabRect(index);
    if (tabRect == null) return;

    final viewportWidth = _scroll.position.viewportDimension;
    final scrollOffset = _scroll.offset;
    const edgePadding = 24.0;

    // Check if tab is fully visible
    final tabLeft = tabRect.left + scrollOffset;
    final tabRight = tabLeft + tabRect.width;

    double? targetScroll;

    if (tabLeft - scrollOffset < edgePadding) {
      // Tab is off-screen to the left
      targetScroll = (tabLeft - edgePadding).clamp(0.0, _scroll.position.maxScrollExtent);
    } else if (tabRight - scrollOffset > viewportWidth - edgePadding) {
      // Tab is off-screen to the right
      targetScroll = (tabRight - viewportWidth + edgePadding).clamp(0.0, _scroll.position.maxScrollExtent);
    }

    if (targetScroll != null) {
      if (animate) {
        _scroll.animateTo(targetScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(targetScroll);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const inset = 4.0;
    return AnimatedBuilder(
      animation: widget.controller.animation ?? widget.controller,
      builder: (context, _) {
        final animVal = widget.controller.animation?.value ?? widget.controller.index.toDouble();

        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(inset),
          physics: const BouncingScrollPhysics(),
          child: _buildRow(animVal),
        );
      },
    );
  }

  Widget _buildRow(double animVal) {
    return Stack(
      children: [
        // ── Row for layout measurement (invisible, defines size) ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.tabs.length, (i) {
            return Container(
              key: _keys[i],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icons != null && i < widget.icons!.length) ...[
                    Icon(widget.icons![i], size: 15, color: Colors.transparent),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    widget.tabs[i],
                    style: widget.theme.textTheme.labelLarge?.copyWith(
                      color: Colors.transparent,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        // ── Sliding pill (behind text) ──
        _buildPill(animVal),
        // ── Tab labels (on top of pill) ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.tabs.length, (i) {
            final selectedness = (1.0 - (animVal - i).abs()).clamp(0.0, 1.0);
            final color = Color.lerp(widget.cs.onSurfaceVariant, widget.cs.onPrimary, selectedness)!;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.controller.animateTo(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icons != null && i < widget.icons!.length) ...[
                      Icon(widget.icons![i], size: 15, color: color),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      widget.tabs[i],
                      style: widget.theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: selectedness > 0.5 ? FontWeight.w700 : FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPill(double animVal) {
    if (!_measured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _measured = true);
      });
      return const SizedBox.shrink();
    }

    final floor = animVal.floor().clamp(0, widget.tabs.length - 1);
    final ceil = animVal.ceil().clamp(0, widget.tabs.length - 1);
    final t = animVal - floor;

    final floorRect = _getTabRect(floor);
    final ceilRect = _getTabRect(ceil);
    if (floorRect == null || ceilRect == null) {
      return const SizedBox.shrink();
    }

    // Interpolate position and width
    final left = floorRect.left + (ceilRect.left - floorRect.left) * t;
    final width = floorRect.width + (ceilRect.width - floorRect.width) * t;

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: widget.cs.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: widget.cs.primary.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect? _getTabRect(int index) {
    if (index < 0 || index >= _keys.length) return null;
    final key = _keys[index];
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    // Find the Stack ancestor (the row parent in the scrollable content)
    final stackBox = context.findRenderObject() as RenderBox?;
    if (stackBox == null) return null;

    final pos = box.localToGlobal(Offset.zero, ancestor: stackBox);
    return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
  }
}

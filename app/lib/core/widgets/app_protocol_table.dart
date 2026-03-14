import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_card.dart';

/// AppProtocolTable: Adaptive table with lazy rendering, synchronized scroll,
/// and automatic table↔card switching based on screen width.
///
/// Table mode: Single horizontal scroll for header+body (synchronized),
///             vertical scroll via ListView.builder (lazy rendering).
/// Card mode:  ListView.builder — each item wrapped in AppCard with glassmorphism.
class AppProtocolTable extends StatelessWidget {
  /// Header row widget (shown only in table mode).
  final Widget headerRow;

  /// Total number of data rows.
  final int itemCount;

  /// Builder for each row. `isCardView` tells which layout to use.
  final Widget Function(BuildContext context, int index, bool isCardView) itemBuilder;

  /// Override automatic table/card switching.
  /// `true` = always table, `false` = always card, `null` = auto (>600px = table).
  final bool? forceTableView;

  /// Minimum width for the table content when horizontal scrolling is needed.
  /// Defaults to 900px.
  final double minTableWidth;

  const AppProtocolTable({
    super.key,
    required this.headerRow,
    required this.itemCount,
    required this.itemBuilder,
    this.forceTableView,
    this.minTableWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTable = forceTableView ?? (constraints.maxWidth > 600);

        if (isTable) {
          return _buildTableView(context, constraints);
        } else {
          return _buildCardView(context);
        }
      },
    );
  }

  /// Table mode: Single horizontal scroll with header + lazy body.
  /// Glassmorphism container built manually (not AppCard) to avoid Column/Flexible issues.
  Widget _buildTableView(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tableWidth = math.max(constraints.maxWidth - 32, minTableWidth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.onSurfaceVariant.withValues(alpha: 0.2), // Soft semantic border
          ),
        ),
            // Single horizontal scroll wrapping BOTH header and body
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header (scrolls with body horizontally) ──
                    headerRow,
                    Divider(
                      height: 1,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.2), // Semantic divider
                    ),
                    // ── Body: shrinkWrap ListView for lazy-ish rendering ──
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemCount,
                      separatorBuilder: (_, i) => Divider(
                        height: 1,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2), // Semantic divider
                      ),
                      itemBuilder: (ctx, i) => itemBuilder(ctx, i, false),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  /// Card mode: Each item wrapped in AppCard for visible glass background.
  Widget _buildCardView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _i) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => AppCard(
          padding: EdgeInsets.zero,
          children: [
            itemBuilder(ctx, i, true),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:sportos_app/domain/timing/result_table.dart';

/// Column-driven result table powered by [ResultTable].
///
/// Receives a pre-built [ResultTable] from [ResultTableBuilder] and renders
/// it automatically — columns from [ColumnDef], cells from [ResultRow].
///
/// **Adaptive:**
/// - Wide screens (>600px): Table mode with horizontal scroll
/// - Narrow screens (<600px): Card mode for mobile readability
///
/// **Mobile-first:**
/// - Min font 12px (above 11px floor from design system)
/// - Touch-friendly row height (min 44px)
/// - Horizontal scroll when table exceeds viewport
/// - Medal badges 🥇🥈🥉 for top-3
/// - Mono font for time/speed/gap columns
class AppResultTable extends StatelessWidget {
  /// Pre-built result table from the engine.
  final ResultTable table;

  /// Callback when a data row is tapped.
  final void Function(ResultRow row)? onRowTap;

  /// Minimum width for table content when horizontal scroll kicks in.
  /// Defaults to 700px — enough for 6-8 columns to breathe.
  final double minTableWidth;

  /// Force table or card mode. `null` = auto (>600px = table).
  final bool? forceTableView;

  const AppResultTable({
    super.key,
    required this.table,
    this.onRowTap,
    this.minTableWidth = 700,
    this.forceTableView,
  });

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final isTable = forceTableView ?? (constraints.maxWidth > 600);
      if (isTable) {
        return _buildTableMode(context, constraints);
      } else {
        return _buildCardMode(context);
      }
    });
  }

  // ═══════════════════════════════════════
  // TABLE MODE — horizontal scroll, sticky header, zebra
  // ═══════════════════════════════════════

  Widget _buildTableMode(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tableWidth = math.max(constraints.maxWidth - 24, minTableWidth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        // Horizontal scroll wraps BOTH header and body (synced)
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                // ── Sticky Header ──
                _TableHeader(columns: table.columns),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
                // ── Scrollable body ──
                Expanded(
                  child: ListView.separated(
                    itemCount: table.rows.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.12),
                    ),
                    itemBuilder: (ctx, i) => _TableRow(
                      columns: table.columns,
                      row: table.rows[i],
                      index: i,
                      onTap: onRowTap != null ? () => onRowTap!(table.rows[i]) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CARD MODE — mobile-friendly, one card per athlete
  // ═══════════════════════════════════════

  Widget _buildCardMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: table.rows.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final row = table.rows[i];
        return GestureDetector(
          onTap: onRowTap != null ? () => onRowTap!(row) : null,
          child: _CardRow(columns: table.columns, row: row, theme: theme, cs: cs),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TABLE HEADER
// ─────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<ColumnDef> columns;
  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: columns.map((col) => Expanded(
          flex: (col.flex * 10).round(),
          child: Text(
            col.label,
            textAlign: _textAlign(col.align),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
              fontSize: 12, // ≥11 min from design system
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TABLE DATA ROW
// ─────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final ResultRow row;
  final int index;
  final VoidCallback? onTap;

  const _TableRow({
    required this.columns,
    required this.row,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Zebra
    final bgColor = index.isEven
        ? Colors.transparent
        : cs.surfaceContainerLowest.withValues(alpha: 0.4);

    // Status tint
    final rowTint = _rowTint(row.type, cs);

    Widget content = Container(
      // Min height 44px for touch targets (Material guidelines)
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: rowTint ?? bgColor,
      child: Row(
        children: columns.map((col) {
          final cell = row.cells[col.id] ?? CellValue.empty;
          return Expanded(
            flex: (col.flex * 10).round(),
            child: _CellWidget(col: col, cell: cell),
          );
        }).toList(),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─────────────────────────────────────────────────────────────────
// CARD ROW (mobile)
// ─────────────────────────────────────────────────────────────────

class _CardRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final ResultRow row;
  final ThemeData theme;
  final ColorScheme cs;

  const _CardRow({
    required this.columns,
    required this.row,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final place = row.cells['place'];
    final bib = row.cells['bib'];
    final name = row.cells['name'];
    final time = row.cells['result_time'];
    final category = row.cells['category'];
    final penalty = row.cells['penalty'];

    final isDnf = row.type == RowType.dnf || row.type == RowType.dns || row.type == RowType.dsq;
    final rowTint = _rowTint(row.type, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: rowTint ?? (theme.cardTheme.color ?? cs.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: place + bib + name + category ──
          Row(children: [
            // Place (medal or text)
            SizedBox(width: 32, child: _placeInCard(place)),
            // BIB chip
            if (bib != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bib.display,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Name
            Expanded(
              child: Text(
                name?.display ?? '',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDnf ? cs.onSurfaceVariant : cs.onSurface,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Category badge
            if (category != null && category.display.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category.display,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          // ── Bottom: lap times / penalties / result time ──
          Row(children: [
            // Lap times (dynamic)
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _lapChips(),
              ),
            ),
            // Penalty
            if (penalty != null && penalty.display.isNotEmpty && penalty.display != '—') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Штр: ${penalty.display}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Result time
            Text(
              time?.display ?? '',
              style: AppTypography.monoTiming.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _timeColor(row, cs),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _placeInCard(CellValue? cell) {
    if (cell == null) return const SizedBox.shrink();
    if (cell.raw is int) {
      final p = cell.raw as int;
      if (p >= 1 && p <= 3) {
        return Text(['🥇', '🥈', '🥉'][p - 1], style: const TextStyle(fontSize: 18));
      }
      return Text('$p', textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, fontSize: 15));
    }
    // Status text
    final isError = cell.style == CellStyle.error;
    return Text(
      cell.display,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: isError ? cs.error : cs.onSurfaceVariant,
        fontSize: 11,
      ),
    );
  }

  List<Widget> _lapChips() {
    final chips = <Widget>[];
    // Collect lap times from cells
    for (final col in columns) {
      if (col.id.startsWith('lap') && col.id.endsWith('_time')) {
        final cell = row.cells[col.id];
        if (cell != null && cell.display.isNotEmpty) {
          chips.add(Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cell.style == CellStyle.highlight
                  ? cs.primaryContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${col.label}: ${cell.display}',
              style: AppTypography.monoTiming.copyWith(
                fontSize: 11,
                fontWeight: cell.style == CellStyle.highlight ? FontWeight.w700 : FontWeight.w400,
                color: cell.style == CellStyle.highlight ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ));
        }
      }
    }
    // Gap
    final gap = row.cells['gap_leader'] ?? row.cells['gap_prev'];
    if (gap != null && gap.display.isNotEmpty) {
      chips.add(Text(
        'Δ ${gap.display}',
        style: AppTypography.monoTiming.copyWith(fontSize: 11, color: cs.onSurfaceVariant),
      ));
    }
    return chips;
  }

  Color _timeColor(ResultRow row, ColorScheme cs) {
    final cell = row.cells['place'];
    if (cell?.raw is int && (cell!.raw as int) == 1) return cs.primary;
    if (row.type == RowType.dnf || row.type == RowType.dns || row.type == RowType.dsq) return cs.error;
    return cs.onSurface;
  }
}

// ─────────────────────────────────────────────────────────────────
// CELL WIDGET (used in table mode)
// ─────────────────────────────────────────────────────────────────

class _CellWidget extends StatelessWidget {
  final ColumnDef col;
  final CellValue cell;

  const _CellWidget({required this.col, required this.cell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Special: place column
    if (col.id == 'place') return _placeCell(cell, theme, cs);

    // Special: bib column
    if (col.id == 'bib') return _bibCell(cell, theme, cs);

    // Generic cell with type-based styling
    final style = _baseStyle(col.type, theme, cs).copyWith(
      color: _cellColor(cell.style, cs),
      fontWeight: _cellWeight(cell.style),
    );

    return Text(
      cell.display,
      textAlign: _textAlign(col.align),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _placeCell(CellValue cell, ThemeData theme, ColorScheme cs) {
    // Status text (DNF, DNS, DSQ, LIVE, —)
    if (cell.raw is! int) {
      final isError = cell.style == CellStyle.error;
      final isLive = cell.style == CellStyle.highlight;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isError
              ? cs.errorContainer.withValues(alpha: 0.2)
              : (isLive ? cs.primaryContainer.withValues(alpha: 0.2) : Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          cell.display,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isError ? cs.error : (isLive ? cs.primary : cs.onSurfaceVariant),
            fontSize: 11, // min from design system
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // Medal for top-3
    final place = cell.raw as int;
    if (place >= 1 && place <= 3) {
      return Text(
        ['🥇', '🥈', '🥉'][place - 1],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      );
    }

    // Regular number
    return Text(
      cell.display,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  Widget _bibCell(CellValue cell, ThemeData theme, ColorScheme cs) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          cell.display,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Type-based styles (all ≥12px, above 11px min) ──

  TextStyle _baseStyle(ColumnType type, ThemeData theme, ColorScheme cs) {
    switch (type) {
      case ColumnType.time:
      case ColumnType.gap:
        return AppTypography.monoTiming.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
          letterSpacing: 0.5,
        );
      case ColumnType.speed:
        return AppTypography.monoTiming.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3,
        );
      case ColumnType.number:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          fontSize: 13,
        ) ?? const TextStyle();
      case ColumnType.status:
        return theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontSize: 12,
        ) ?? const TextStyle();
      case ColumnType.text:
        return theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface,
          fontSize: 13,
        ) ?? const TextStyle();
    }
  }

  Color? _cellColor(CellStyle style, ColorScheme cs) {
    switch (style) {
      case CellStyle.highlight: return cs.primary;
      case CellStyle.error: return cs.error;
      case CellStyle.muted: return cs.onSurfaceVariant.withValues(alpha: 0.6);
      case CellStyle.success: return AppColors.success;
      case CellStyle.bold: return null;
      case CellStyle.normal: return null;
    }
  }

  FontWeight? _cellWeight(CellStyle style) {
    switch (style) {
      case CellStyle.bold: return FontWeight.w700;
      case CellStyle.highlight: return FontWeight.w700;
      case CellStyle.error: return FontWeight.w600;
      case CellStyle.normal: return null;
      case CellStyle.muted: return null;
      case CellStyle.success: return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────

TextAlign _textAlign(ColumnAlign align) {
  switch (align) {
    case ColumnAlign.left: return TextAlign.left;
    case ColumnAlign.center: return TextAlign.center;
    case ColumnAlign.right: return TextAlign.right;
  }
}

Color? _rowTint(RowType type, ColorScheme cs) {
  switch (type) {
    case RowType.dnf:
    case RowType.dsq:
      return cs.errorContainer.withValues(alpha: 0.08);
    case RowType.dns:
    case RowType.waiting:
      return cs.onSurface.withValues(alpha: 0.03);
    case RowType.onTrack:
      return cs.primaryContainer.withValues(alpha: 0.08);
    case RowType.finished:
      return null;
  }
}

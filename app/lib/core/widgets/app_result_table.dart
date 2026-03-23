
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:sportos_app/domain/timing/result_table.dart';

/// Universal column-driven result table powered by [ResultTable].
///
/// **Smart scroll:** Horizontal scroll appears ONLY when columns exceed
/// available width. Each column has a minimum width based on its type.
///
/// **View modes:**
/// - Table (default, even on mobile) — rows with cells
/// - Card — per-athlete cards for quick scanning
/// Switch via [showCards] or use [AppResultTable.withToggle] for built-in button.
///
/// **Edge-to-edge:** No side margins — critical info fills the screen.
///
/// **Universal features:**
/// - Flex columns from [ColumnDef]
/// - Zebra striping for readability
/// - Status row tints (onTrack, DNF, DNS, DSQ)
/// - Medal badges 🥇🥈🥉
/// - Mono font for time/speed/gap
/// - [CellStyle] → color/weight
/// - Min row height 44px (Material touch target)
class AppResultTable extends StatelessWidget {
  final ResultTable table;
  final void Function(ResultRow row)? onRowTap;
  final void Function(ResultRow row)? onRowLongPress;

  /// IDs of selected rows (for multi-select highlight).
  final Set<String>? selectedRowIds;

  /// Show card mode instead of table mode.
  final bool showCards;

  const AppResultTable({
    super.key,
    required this.table,
    this.onRowTap,
    this.onRowLongPress,
    this.selectedRowIds,
    this.showCards = false,
  });

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    if (showCards) return _buildCardMode(context);
    return _buildTableMode(context);
  }

  // ═══════════════════════════════════════
  // TABLE MODE — smart horizontal scroll, edge-to-edge
  // ═══════════════════════════════════════

  Widget _buildTableMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate minimum total width from column types
      final totalMinWidth = _calcMinTableWidth(table.columns);
      final availableWidth = constraints.maxWidth;
      final needsScroll = totalMinWidth > availableWidth;
      final tableWidth = needsScroll ? totalMinWidth : availableWidth;

      // Auto-detect unbounded height (e.g. inside SliverToBoxAdapter / SingleChildScrollView)
      final isUnbounded = constraints.maxHeight == double.infinity;

      final listView = ListView.separated(
        shrinkWrap: isUnbounded,
        physics: isUnbounded ? const NeverScrollableScrollPhysics() : null,
        itemCount: table.rows.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: cs.outlineVariant.withOpacity(0.08),
        ),
        itemBuilder: (ctx, i) => _TableRow(
          columns: table.columns,
          row: table.rows[i],
          index: i,
          isSelected: selectedRowIds?.contains(table.rows[i].entryId) ?? false,
          showCheckbox: selectedRowIds != null,
          onTap: onRowTap != null ? () => onRowTap!(table.rows[i]) : null,
          onLongPress: onRowLongPress != null ? () => onRowLongPress!(table.rows[i]) : null,
        ),
      );

      Widget tableContent = SizedBox(
        width: tableWidth,
        child: Column(
          mainAxisSize: isUnbounded ? MainAxisSize.min : MainAxisSize.max,
          children: [
            // ── Header ──
            _TableHeader(columns: table.columns),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.25)),
            // ── Body ──
            if (isUnbounded)
              listView
            else
              Expanded(child: listView),
          ],
        ),
      );

      // Wrap in horizontal scroll only when needed
      if (needsScroll) {
        tableContent = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: tableContent,
        );
      }

      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? cs.surfaceContainerHigh,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.2)),
            bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.2)),
          ),
        ),
        child: tableContent,
      );
    });
  }

  /// Calculate minimum table width from [ColumnDef.minWidth].
  ///
  /// If sum(minWidth) > viewport → horizontal scroll ON.
  /// If sum(minWidth) ≤ viewport → columns stretch via flex, no scroll.
  double _calcMinTableWidth(List<ColumnDef> columns) {
    double total = 28; // horizontal padding (14 * 2)
    for (final col in columns) {
      total += col.minWidth;
    }
    return total;
  }

  // ═══════════════════════════════════════
  // CARD MODE — mobile-friendly
  // ═══════════════════════════════════════

  Widget _buildCardMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isUnbounded = constraints.maxHeight == double.infinity;
      return ListView.separated(
        shrinkWrap: isUnbounded,
        physics: isUnbounded ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: table.rows.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (ctx, i) {
          final row = table.rows[i];
          final isSelected = selectedRowIds?.contains(row.entryId) ?? false;
          return GestureDetector(
            onTap: onRowTap != null ? () => onRowTap!(row) : null,
            onLongPress: onRowLongPress != null ? () => onRowLongPress!(row) : null,
            child: Container(
              decoration: isSelected ? BoxDecoration(
                border: Border.all(color: cs.primary, width: 2),
                borderRadius: BorderRadius.circular(14),
              ) : null,
              child: _CardRow(columns: table.columns, row: row),
            ),
          );
        },
      );
    });
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
      color: cs.surfaceContainerHighest.withOpacity(0.35),
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
              fontSize: 12,
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
// TABLE ROW
// ─────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final ResultRow row;
  final int index;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TableRow({
    required this.columns,
    required this.row,
    required this.index,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Zebra
    final bgColor = isSelected
        ? cs.primaryContainer.withOpacity(0.25)
        : index.isEven
            ? Colors.transparent
            : cs.surfaceContainerLowest.withOpacity(0.4);

    final rowTint = isSelected ? null : _rowTint(row.type, cs);

    Widget content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: rowTint ?? bgColor,
      child: Row(
        children: [
          if (showCheckbox) ...[
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? cs.primary : cs.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
          ],
          ...columns.map((col) {
            final cell = row.cells[col.id] ?? CellValue.empty;
            return Expanded(
              flex: (col.flex * 10).round(),
              child: _CellWidget(col: col, cell: cell),
            );
          }),
        ],
      ),
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(onTap: onTap, onLongPress: onLongPress, child: content);
    }
    return content;
  }
}

// ─────────────────────────────────────────────────────────────────
// CARD ROW (mobile-friendly)
// ─────────────────────────────────────────────────────────────────

class _CardRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final ResultRow row;

  const _CardRow({
    required this.columns,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Use row.cell() — encapsulated Map lookup avoids dart2js issues
    final nameDisplay = row.cell('name');
    final placeStr = row.cell('place');
    final bibStr = row.cell('bib');
    final categoryStr = row.cell('category');
    final gapStr = row.cell('gap_leader').isNotEmpty
        ? row.cell('gap_leader') : row.cell('gap_prev');
    final totalTime = row.cell('result_time');

    final isDnf = row.type == RowType.dnf || row.type == RowType.dns || row.type == RowType.dsq;
    final rowTint = _rowTint(row.type, cs);



    // Time color
    Color timeColor = cs.onSurface;
    if (placeStr == '1') timeColor = cs.primary;
    else if (isDnf) timeColor = cs.error;

    // Place badge (no emoji — they don't render on web CanvasKit)
    Widget placeWidget;
    if (placeStr == '1' || placeStr == '2' || placeStr == '3') {
      const colors = {'1': Color(0xFFFFD700), '2': Color(0xFFC0C0C0), '3': Color(0xFFCD7F32)};
      placeWidget = Container(
        width: 26, height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors[placeStr]!.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: colors[placeStr]!, width: 1.5),
        ),
        child: Text(placeStr, textAlign: TextAlign.center,
          style: TextStyle(color: colors[placeStr], fontSize: 13, fontWeight: FontWeight.w900)),
      );
    } else {
      placeWidget = Text(placeStr, textAlign: TextAlign.center,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700));
    }

    // Lap chips
    final lapChips = <Widget>[];
    for (final col in columns) {
      if (col.id.startsWith('lap') && col.id.endsWith('_time')) {
        final display = row.cell(col.id);
        if (display.isNotEmpty) {
          lapChips.add(Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('${col.label}: $display',
              style: AppTypography.monoTiming.copyWith(
                fontSize: 11, color: cs.onSurfaceVariant)),
          ));
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowTint ?? cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Top row ──
          Row(children: [
            SizedBox(width: 30, child: placeWidget),
            const SizedBox(width: 6),
            if (bibStr.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(bibStr, style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(nameDisplay, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDnf ? cs.onSurfaceVariant : cs.onSurface,
                fontSize: 14, fontWeight: FontWeight.w600))),
            if (categoryStr.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(categoryStr, style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
              ),
          ]),
          const SizedBox(height: 6),
          // ── Bottom row ──
          Row(children: [
            if (lapChips.isNotEmpty)
              Expanded(child: Wrap(spacing: 4, runSpacing: 3, children: lapChips)),
            if (lapChips.isEmpty) const Spacer(),
            if (gapStr.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(gapStr, style: AppTypography.monoTiming.copyWith(
                fontSize: 11, color: cs.onSurfaceVariant)),
            ],
            const SizedBox(width: 6),
            Text(totalTime.isEmpty ? '—' : totalTime, style: AppTypography.monoTiming.copyWith(
              fontSize: 15, fontWeight: FontWeight.w700, color: timeColor)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CELL WIDGET (table mode)
// ─────────────────────────────────────────────────────────────────

class _CellWidget extends StatelessWidget {
  final ColumnDef col;
  final CellValue cell;

  const _CellWidget({required this.col, required this.cell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (col.id == 'place') return _placeCell(cell, theme, cs);
    if (col.id == 'bib') return _bibCell(cell, theme, cs);

    // Empty cell
    if (cell.display.isEmpty) {
      return Text('—', textAlign: _textAlign(col.align),
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.3)));
    }

    final style = _baseStyle(col.type, theme, cs).copyWith(
      color: _cellColor(cell.style, cs),
      fontWeight: _cellWeight(cell.style),
    );

    return Text(cell.display,
      textAlign: _textAlign(col.align),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis);
  }

  Widget _placeCell(CellValue cell, ThemeData theme, ColorScheme cs) {
    if (cell.raw is! int) {
      final isError = cell.style == CellStyle.error;
      final isLive = cell.style == CellStyle.highlight;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: isError ? cs.errorContainer.withOpacity(0.2)
              : (isLive ? cs.primaryContainer.withOpacity(0.2) : Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(cell.display, textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isError ? cs.error : (isLive ? cs.primary : cs.onSurfaceVariant),
            fontSize: 11, letterSpacing: 0.5)),
      );
    }

    final place = cell.raw as int;
    if (place >= 1 && place <= 3) {
      return Text(['🥇', '🥈', '🥉'][place - 1],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15));
    }

    return Text(cell.display, textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, fontSize: 13));
  }

  Widget _bibCell(CellValue cell, ThemeData theme, ColorScheme cs) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(cell.display,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, fontSize: 13)),
      ),
    );
  }

  TextStyle _baseStyle(ColumnType type, ThemeData theme, ColorScheme cs) {
    switch (type) {
      case ColumnType.time:
      case ColumnType.gap:
        return AppTypography.monoTiming.copyWith(
          fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface, letterSpacing: 0.5);
      case ColumnType.speed:
        return AppTypography.monoTiming.copyWith(
          fontSize: 12, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant, letterSpacing: 0.3);
      case ColumnType.number:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 13) ?? const TextStyle();
      case ColumnType.status:
        return theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 12) ?? const TextStyle();
      case ColumnType.text:
        return theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface, fontSize: 13) ?? const TextStyle();
    }
  }

  Color? _cellColor(CellStyle style, ColorScheme cs) {
    switch (style) {
      case CellStyle.highlight: return cs.primary;
      case CellStyle.error: return cs.error;
      case CellStyle.muted: return cs.onSurfaceVariant.withOpacity(0.6);
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
      return cs.errorContainer.withOpacity(0.08);
    case RowType.dns:
    case RowType.waiting:
      return cs.onSurface.withOpacity(0.03);
    case RowType.onTrack:
      return cs.primaryContainer.withOpacity(0.06);
    case RowType.finished:
      return null;
  }
}

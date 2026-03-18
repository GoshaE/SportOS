import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:sportos_app/domain/timing/result_table.dart';

/// Column-driven result table powered by [ResultTable].
///
/// Receives a pre-built [ResultTable] from [ResultTableBuilder] and renders
/// it automatically — columns from [ColumnDef], cells from [ResultRow].
///
/// Features:
/// - Flex-based column widths from [ColumnDef.flex]
/// - Zebra striping for readability
/// - Sticky header
/// - Medal badges 🥇🥈🥉 for top-3
/// - Mono font for time/speed/gap columns
/// - [CellStyle] → visual styling (highlight, error, muted, bold)
///
/// ```dart
/// AppResultTable(table: resultTable, onRowTap: (row) => ...)
/// ```
class AppResultTable extends StatelessWidget {
  /// Pre-built result table from the engine.
  final ResultTable table;

  /// Callback when a data row is tapped.
  final void Function(ResultRow row)? onRowTap;

  /// Compact mode: denser padding, smaller fonts.
  final bool compact;

  const AppResultTable({
    super.key,
    required this.table,
    this.onRowTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // ── Sticky Header ──
          _HeaderRow(columns: table.columns, compact: compact),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          // ── Body ──
          Expanded(
            child: ListView.builder(
              itemCount: table.rows.length,
              padding: EdgeInsets.zero,
              itemBuilder: (ctx, i) => _DataRow(
                columns: table.columns,
                row: table.rows[i],
                index: i,
                compact: compact,
                onTap: onRowTap != null ? () => onRowTap!(table.rows[i]) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HEADER ROW
// ─────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final bool compact;

  const _HeaderRow({required this.columns, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vPad = compact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: columns.map((col) {
          return Expanded(
            flex: (col.flex * 10).round(),
            child: Text(
              col.label,
              textAlign: _textAlign(col.align),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: compact ? 10 : 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DATA ROW
// ─────────────────────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final List<ColumnDef> columns;
  final ResultRow row;
  final int index;
  final bool compact;
  final VoidCallback? onTap;

  const _DataRow({
    required this.columns,
    required this.row,
    required this.index,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vPad = compact ? 6.0 : 10.0;

    // Zebra striping
    final bgColor = index.isEven
        ? Colors.transparent
        : cs.surfaceContainerLowest.withValues(alpha: 0.5);

    // Row-level tint for special statuses
    final Color? rowTint;
    switch (row.type) {
      case RowType.dnf:
      case RowType.dsq:
        rowTint = cs.errorContainer.withValues(alpha: 0.08);
        break;
      case RowType.dns:
      case RowType.waiting:
        rowTint = cs.onSurface.withValues(alpha: 0.03);
        break;
      case RowType.onTrack:
        rowTint = cs.primaryContainer.withValues(alpha: 0.08);
        break;
      default:
        rowTint = null;
    }

    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
      color: rowTint ?? bgColor,
      child: Row(
        children: columns.map((col) {
          final cell = row.cells[col.id] ?? CellValue.empty;
          return Expanded(
            flex: (col.flex * 10).round(),
            child: _cellWidget(col, cell, theme, cs),
          );
        }).toList(),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _cellWidget(ColumnDef col, CellValue cell, ThemeData theme, ColorScheme cs) {
    // Special: place column with medal
    if (col.id == 'place') {
      return _placeCell(cell, theme, cs);
    }

    // Special: BIB column with chip
    if (col.id == 'bib') {
      return _bibCell(cell, theme, cs);
    }

    // Style resolution
    final baseStyle = _baseStyle(col.type, theme, cs);
    final styledText = baseStyle.copyWith(
      color: _cellColor(cell.style, cs) ?? baseStyle.color,
      fontWeight: _cellWeight(cell.style) ?? baseStyle.fontWeight,
      fontSize: compact ? (baseStyle.fontSize ?? 12) - 1 : baseStyle.fontSize,
    );

    return Text(
      cell.display,
      textAlign: _textAlign(col.align),
      style: styledText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Place cell: medal badges for top-3, status chips for DNF/DNS/DSQ ──

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
            fontSize: compact ? 9 : 10,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // Medal for top-3
    final place = cell.raw as int;
    if (place >= 1 && place <= 3) {
      const medals = ['🥇', '🥈', '🥉'];
      return Text(
        medals[place - 1],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: compact ? 14 : 16),
      );
    }

    // Regular place number
    return Text(
      cell.display,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
        fontSize: compact ? 12 : 13,
      ),
    );
  }

  // ── BIB cell: compact chip ──

  Widget _bibCell(CellValue cell, ThemeData theme, ColorScheme cs) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          cell.display,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            fontSize: compact ? 11 : 12,
          ),
        ),
      ),
    );
  }

  // ── Style helpers ──

  TextStyle _baseStyle(ColumnType type, ThemeData theme, ColorScheme cs) {
    switch (type) {
      case ColumnType.time:
      case ColumnType.gap:
        return AppTypography.monoTiming.copyWith(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
          letterSpacing: 0.5,
        );
      case ColumnType.speed:
        return AppTypography.monoTiming.copyWith(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w400,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3,
        );
      case ColumnType.number:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          fontSize: compact ? 11 : 12,
        ) ?? const TextStyle();
      case ColumnType.status:
        return theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontSize: compact ? 10 : 11,
        ) ?? const TextStyle();
      case ColumnType.text:
        return theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface,
          fontSize: compact ? 11 : 12,
        ) ?? const TextStyle();
    }
  }

  Color? _cellColor(CellStyle style, ColorScheme cs) {
    switch (style) {
      case CellStyle.highlight: return cs.primary;
      case CellStyle.error: return cs.error;
      case CellStyle.muted: return cs.onSurfaceVariant.withValues(alpha: 0.6);
      case CellStyle.success: return AppColors.success;
      default: return null;
    }
  }

  FontWeight? _cellWeight(CellStyle style) {
    switch (style) {
      case CellStyle.bold: return FontWeight.w700;
      case CellStyle.highlight: return FontWeight.w700;
      case CellStyle.error: return FontWeight.w600;
      default: return null;
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

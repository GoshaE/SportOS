import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'app_card.dart';

/// Shared chart styling helpers for consistent look across all SportOS charts.
///
/// Usage:
/// ```dart
/// final style = AppChartStyle(Theme.of(context));
/// style.gridLine          // FlLine for grids
/// style.tooltipData(...)  // Styled tooltip
/// ```
class AppChartStyle {
  final ThemeData theme;
  final ColorScheme cs;

  AppChartStyle(this.theme) : cs = theme.colorScheme;

  // ── Colors ──
  Color get primary => cs.primary;
  Color get secondary => cs.secondary;
  Color get tertiary => cs.tertiary;
  Color get error => cs.error;
  Color get surface => cs.surface;
  Color get onSurface => cs.onSurface;
  Color get muted => cs.onSurfaceVariant;
  Color get gridColor => cs.outlineVariant.withOpacity(0.3);

  /// Preset palette for multi-series charts
  List<Color> get palette => [
    cs.primary,
    cs.tertiary,
    cs.secondary,
    cs.error,
    const Color(0xFF26A69A), // teal
    const Color(0xFFAB47BC), // purple
  ];

  // ── Grid lines ──
  FlLine get gridLine => FlLine(
    color: gridColor,
    strokeWidth: 0.8,
    dashArray: [4, 4],
  );

  FlLine get borderLine => FlLine(
    color: gridColor,
    strokeWidth: 1,
  );

  // ── Titles ──
  SideTitleWidget sideTitle(double value, TitleMeta meta, {String? suffix}) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        '${value.toInt()}${suffix ?? ''}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: muted,
          fontSize: 12,
        ),
      ),
    );
  }

  SideTitleWidget bottomTitle(double value, TitleMeta meta, List<String> labels) {
    final idx = value.toInt();
    final text = idx >= 0 && idx < labels.length ? labels[idx] : '';
    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: muted,
          fontSize: 12,
        ),
      ),
    );
  }

  // ── Touch tooltip ──
  LineTouchData lineTouch({String Function(LineBarSpot)? formatter}) {
    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => cs.inverseSurface,
        getTooltipItems: (spots) => spots.map((s) {
          return LineTooltipItem(
            formatter?.call(s) ?? s.y.toStringAsFixed(1),
            theme.textTheme.labelMedium?.copyWith(color: cs.onInverseSurface, fontWeight: FontWeight.bold) ?? TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.bold),
          );
        }).toList(),
      ),
    );
  }

  BarTouchData barTouch({String Function(BarChartGroupData, BarChartRodData)? formatter}) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => cs.inverseSurface,
        getTooltipItem: (group, gIdx, rod, rIdx) {
          return BarTooltipItem(
            formatter?.call(group, rod) ?? rod.toY.toStringAsFixed(0),
            theme.textTheme.labelMedium?.copyWith(color: cs.onInverseSurface, fontWeight: FontWeight.bold) ?? TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }

  PieTouchData pieTouch() {
    return PieTouchData(
      touchCallback: (event, response) {},
    );
  }

  // ── Gradient fills for line charts ──
  LinearGradient lineGradient(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
  );

  static Widget chartCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget chart,
    double height = 200,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              SizedBox(height: height, child: chart),
            ],
          ),
        ],
      ),
    );
  }
}

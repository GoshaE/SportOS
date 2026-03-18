import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import '../../ui/molecules/app_chip_group.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR3 — Мои результаты (с PB-трекером)
class MyResultsScreen extends StatefulWidget {
  const MyResultsScreen({super.key});

  @override
  State<MyResultsScreen> createState() => _MyResultsScreenState();
}

class _MyResultsScreenState extends State<MyResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _sportFilter = 'Все';

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Мои результаты'),
        bottom: AppPillTabBar(
          controller: _tab,
          tabs: const ['Результаты', 'Personal Best'],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // ── Tab 1: История ──
        ListView(padding: const EdgeInsets.all(12), children: [
          // Статистика
          Row(children: [
            Expanded(child: AppStatCard(value: '12', label: 'Стартов', color: cs.primary)),
            const SizedBox(width: 6),
            Expanded(child: AppStatCard(value: '5', label: 'Подиумов', color: cs.tertiary)),
            const SizedBox(width: 6),
            Expanded(child: AppStatCard(value: '2', label: 'Побед', color: cs.secondary)),
            const SizedBox(width: 6),
            Expanded(child: AppStatCard(value: '1', label: 'DNF', color: cs.error)),
          ]),
          const SizedBox(height: 12),
          _buildProgressChart(cs),
          const SizedBox(height: 8),

          // Фильтр
          AppChipGroup(
            items: const ['Все', 'Ездовой спорт', 'Каникросс', 'Лыжные гонки'],
            selected: _sportFilter,
            onSelected: (v) => setState(() => _sportFilter = v),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          _resultCard('🥇', '1-е место', 'Чемпионат Урала 2026', 'Скиджоринг 5км · 00:38:12 · Rex', '15.03.2026'),
          _resultCard('🥈', '2-е место', 'Кубок Сибири 2025', 'Скиджоринг 10км · 01:12:45 · Rex', '20.12.2025'),
          _resultCard('4', '4-е место', 'Кубок Москвы', 'Скиджоринг 5км · 00:42:30 · Rex', '15.11.2025'),
          _resultCard('🥉', '3-е место', 'Кубок Урала 2025', 'Каникросс 3км · 00:18:05 · Luna', '20.10.2025'),
          _resultCard('DNF', 'Не финишировал', 'Марафон 2025', 'Нарты 30км · Rex + Luna', '05.03.2025'),
        ]),

        // ── Tab 2: Personal Best ──
        ListView(padding: const EdgeInsets.all(12), children: [
          Text('Лучшие результаты по дисциплинам', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _pbCard('Скиджоринг 5км', '00:38:12', 'Чемпионат Урала 2026', '15.03.2026', cs.primary, [
            _pbBar('Чемп.Урала 2026', 38.2, 38.2),
            _pbBar('Кубок Москвы', 42.5, 38.2),
            _pbBar('Осенний Кубок', 40.1, 38.2),
          ]),
          _pbCard('Скиджоринг 10км', '01:12:45', 'Кубок Сибири 2025', '20.12.2025', cs.secondary, [
            _pbBar('Кубок Сибири', 72.75, 72.75),
            _pbBar('Марафон 2025', 78.0, 72.75),
          ]),
          _pbCard('Каникросс 3км', '00:18:05', 'Кубок Урала 2025', '20.10.2025', cs.tertiary, [
            _pbBar('Кубок Урала', 18.08, 18.08),
            _pbBar('Лесной забег', 19.5, 18.08),
            _pbBar('Городской старт', 20.2, 18.08),
          ]),
          _pbCard('Нарты 30км', '—', 'DNF', '—', cs.outline, []),
        ]),
      ]),
    );
  }



  Widget _buildProgressChart(ColorScheme cs) {
    final style = AppChartStyle(Theme.of(context));
    final events = ['Лесной', 'Урал\'25', 'Москва', 'Сибирь', 'Урал\'26'];
    // Minutes — lower is better
    final times = [44.3, 40.1, 42.5, 38.8, 38.2];

    return AppChartStyle.chartCard(
      context: context,
      title: 'Динамика результатов',
      subtitle: 'Скиджоринг 5км · минуты',
      height: 180,
      chart: LineChart(LineChartData(
        minY: 34,
        maxY: 48,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(times.length, (i) => FlSpot(i.toDouble(), times[i])),
            isCurved: true,
            curveSmoothness: 0.3,
            color: style.primary,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, _, spotIndex, barData) => FlDotCirclePainter(
              radius: 4, color: style.primary, strokeWidth: 2, strokeColor: cs.surface,
            )),
            belowBarData: BarAreaData(
              show: true,
              gradient: style.lineGradient(style.primary),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 32, interval: 4,
            getTitlesWidget: (v, meta) => style.sideTitle(v, meta),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, meta) => style.bottomTitle(v, meta, events),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: 4,
          getDrawingHorizontalLine: (_) => style.gridLine,
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: style.lineTouch(formatter: (s) => '${s.y.toStringAsFixed(1)} мин'),
      )),
    );
  }

  Widget _resultCard(String emoji, String place, String event, String detail, String date) {
    final theme = Theme.of(context);
    final isDnf = emoji == 'DNF';
    final emojiBgColor = isDnf ? theme.colorScheme.error : theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard.padded(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: emojiBgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: emojiBgColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: isDnf 
                ? Icon(Icons.close, color: theme.colorScheme.error, size: 20)
                : Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          title: Text(place, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$detail · $date', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {},
        ),
      ),
    );
  }

  Widget _pbCard(String discipline, String time, String event, String date, Color color, List<Widget> bars) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard.padded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.emoji_events, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(discipline, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$event · $date', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(time, style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, fontSize: 16, fontFamily: 'monospace')),
            ),
          ]),
          if (bars.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('ДИНАМИКА УЛУЧШЕНИЙ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...bars,
          ],
        ])
      ),
    );
  }

  Widget _pbBar(String label, double minutes, double best) {
    final ratio = best / minutes;
    final isBest = minutes == best;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Stack(children: [
          Container(height: 12, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(widthFactor: ratio.clamp(0, 1), child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: isBest ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ])),
        const SizedBox(width: 4),
        Text('${minutes.toStringAsFixed(1)}\'', style: TextStyle(fontSize: 10, fontWeight: isBest ? FontWeight.bold : FontWeight.normal)),
        if (isBest) const Text(' 🏆', style: TextStyle(fontSize: 10)),
      ]),
    );
  }
}

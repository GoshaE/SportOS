import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/domain/timing/timing.dart';
import '../../domain/event/config_providers.dart';

/// Screen ID: RS1 — Live результаты (с split-times, multi-day, отсечки)
///
/// Подключён к [raceSessionProvider]: показывает реальные данные из Timing Engine.
/// Использует [ResultTableBuilder] для генерации таблицы — экран только рендерит.
class LiveResultsScreen extends ConsumerStatefulWidget {
  const LiveResultsScreen({super.key});

  @override
  ConsumerState<LiveResultsScreen> createState() => _LiveResultsScreenState();
}

class _LiveResultsScreenState extends ConsumerState<LiveResultsScreen> {
  int _currentDay = 1;
  bool _showSplits = false;
  String? _selectedDiscId;

  static const _tableBuilder = ResultTableBuilder();
  static const _resultCalc = ResultCalculator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Live результаты'),
        actions: [
          // LIVE badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: session != null ? cs.error : cs.outline, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                session != null ? 'LIVE' : 'OFFLINE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: session != null ? cs.error : cs.outline, letterSpacing: 1),
              ),
            ]),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: session == null ? _buildNoSession(cs) : _buildBody(theme, cs, session),
    );
  }

  // ═══════════════════════════════════════
  // Empty / Waiting states
  // ═══════════════════════════════════════

  Widget _buildNoSession(ColorScheme cs) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_off_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text('Нет активной сессии', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Результаты появятся после старта гонки', style: TextStyle(fontSize: 13, color: cs.outline)),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Main body with session (powered by ResultTableEngine)
  // ═══════════════════════════════════════

  Widget _buildBody(ThemeData theme, ColorScheme cs, RaceSessionState session) {
    final ds = session.config.displaySettings;

    // ── Build ResultTable from engine ──
    final results = _resultCalc.calculate(
      config: session.config,
      startList: session.startList.all,
      marks: session.marking.officialMarks,
      penalties: session.penalties,
    );
    final table = _tableBuilder.build(
      results: results,
      config: session.config,
      display: ds,
      athletes: session.startList.all,
      marks: session.marking.officialMarks,
    );

    // ── Compute stats from table rows ──
    final finishedCount = table.rows.where((r) => r.type == RowType.finished).length;
    final onTrackCount = table.rows.where((r) => r.type == RowType.onTrack).length;
    final dnfCount = table.rows.where((r) => r.type == RowType.dnf).length;
    final dnsCount = table.rows.where((r) => r.type == RowType.dns).length;
    final dsqCount = table.rows.where((r) => r.type == RowType.dsq).length;
    final waitingCount = table.rows.where((r) => r.type == RowType.waiting).length;

    // ── Read Config Engine ──
    final eventConfig = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final totalDays = eventConfig.isMultiDay ? eventConfig.days.length : 0;

    _selectedDiscId ??= disciplines.isNotEmpty ? disciplines.first.id : null;

    return Column(children: [
      // ── Шапка: дни + дисциплины + статистика ──
      Container(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Multi-day (from Config Engine)
          if (totalDays > 1) ...[
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              Icon(Icons.calendar_month, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              ...List.generate(totalDays, (d) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('День ${d + 1}', style: const TextStyle(fontSize: 12)),
                  selected: _currentDay == d + 1,
                  onSelected: (_) => setState(() => _currentDay = d + 1),
                  visualDensity: VisualDensity.compact,
                ),
              )),
            ])),
            const SizedBox(height: 6),
          ],
          // Дисциплины (from Config Engine)
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            ...disciplines
                .where((d) => _currentDay == 0 || d.dayNumber == _currentDay || d.dayNumber == null)
                .map((d) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d.displayName, style: const TextStyle(fontSize: 12)),
                    selected: _selectedDiscId == d.id,
                    onSelected: (_) => setState(() => _selectedDiscId = d.id),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
          ])),
          const SizedBox(height: 8),
          // Статистика
          Row(children: [
            Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              _statPill(cs, theme, '$finishedCount', 'Финиш', cs.primary),
              const SizedBox(width: 6),
              _statPill(cs, theme, '$onTrackCount', 'На трассе', cs.tertiary),
              const SizedBox(width: 6),
              if (waitingCount > 0) ...[
                _statPill(cs, theme, '$waitingCount', 'Ожидает', cs.outline),
                const SizedBox(width: 6),
              ],
              if (dnfCount > 0) ...[
                _statPill(cs, theme, '$dnfCount', 'DNF', cs.error),
                const SizedBox(width: 6),
              ],
              if (dsqCount > 0) ...[
                _statPill(cs, theme, '$dsqCount', 'DSQ', cs.error),
                const SizedBox(width: 6),
              ],
              if (dnsCount > 0) ...[
                _statPill(cs, theme, '$dnsCount', 'DNS', cs.outline),
              ],
            ]))),
            const SizedBox(width: 8),
            // Splits toggle
            GestureDetector(
              onTap: () => setState(() => _showSplits = !_showSplits),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showSplits ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _showSplits ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_showSplits ? Icons.timer : Icons.timer_outlined, size: 14, color: _showSplits ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Сплиты', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _showSplits ? cs.primary : cs.onSurfaceVariant)),
                ]),
              ),
            ),
          ]),
        ]),
      ),

      // ── Таблица результатов (from ResultTableEngine) ──
      Expanded(child: table.rows.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.hourglass_empty, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('Ожидание старта спортсменов...', style: TextStyle(color: cs.onSurfaceVariant)),
            ]))
          : AppProtocolTable(
              itemCount: table.rows.length,
              forceTableView: true,
              headerRow: AppProtocolRow(
                isHeader: true,
                bib: 'BIB',
                name: ds.showDogNames ? 'Спортсмен / Собака' : 'Спортсмен',
                cat: 'Кат.',
                dog: _showSplits
                    ? (session.config.laps > 1 ? 'Круги' : 'Сплиты')
                    : (ds.showDogNames ? 'Собака' : (ds.showSpeed ? 'Скор.' : '—')),
                time: 'Время',
                delta: ds.showGapToLeader ? '+Лидер' : (ds.showGapToPrev ? 'Разр.' : ''),
                penalty: 'Штр.',
              ),
              itemBuilder: (ctx, i, isCard) {
                final row = table.rows[i];

                // Build split/dog column from ResultTable cells
                final String dogCol;
                if (_showSplits) {
                  final lapParts = <String>[];
                  for (var lap = 1; lap <= session.config.laps; lap++) {
                    final val = row.cell('lap${lap}_time');
                    if (val.isNotEmpty) lapParts.add(val);
                  }
                  if (lapParts.isNotEmpty) {
                    dogCol = lapParts.join(' / ');
                  } else {
                    dogCol = row.cell('split').isNotEmpty ? row.cell('split') : '—';
                  }
                } else {
                  dogCol = row.cell('dog').isNotEmpty ? row.cell('dog') : '—';
                }

                return AppProtocolRow(
                  isCardView: isCard,
                  place: row.rawCell('place') is int ? row.rawCell('place') as int : null,
                  placeText: row.rawCell('place') is! int ? row.cell('place') : null,
                  bib: row.cell('bib'),
                  name: row.cell('name'),
                  cat: row.cell('category'),
                  dog: dogCol,
                  time: row.cell('result_time'),
                  delta: row.cell('gap_leader').isNotEmpty
                      ? row.cell('gap_leader')
                      : (row.cell('gap_prev').isNotEmpty ? row.cell('gap_prev') : ''),
                  penalty: row.cell('penalty'),
                );
              },
            ),
      ),

      // ── Auto-refresh indicator ──
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.sync, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '${TimeFormatter.clockTime(DateTime.now())} · Timing Engine',
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
          ),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // UI Widgets
  // ═══════════════════════════════════════

  Widget _statPill(ColorScheme cs, ThemeData theme, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: RS1 — Live результаты (с split-times, multi-day, отсечки)
///
/// Подключён к [raceSessionProvider]: показывает реальные данные из Timing Engine.
/// - Нет сессии → пустое состояние
/// - Сессия запущена, но никто не стартовал → "Ожидание старта"
/// - Атлеты на трассе / финишировавшие → live таблица через AppProtocolTable
class LiveResultsScreen extends ConsumerStatefulWidget {
  const LiveResultsScreen({super.key});

  @override
  ConsumerState<LiveResultsScreen> createState() => _LiveResultsScreenState();
}

class _LiveResultsScreenState extends ConsumerState<LiveResultsScreen> {
  int _currentDay = 1;
  final int _totalDays = 2;
  bool _showSplits = false;
  String _disc = 'Скиджоринг 5км';

  final ElapsedCalculator _elapsedCalc = const ElapsedCalculator();

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
  // Main body with session
  // ═══════════════════════════════════════

  Widget _buildBody(ThemeData theme, ColorScheme cs, RaceSessionState session) {

    // Compute stats
    int finishedCount = 0;
    int onTrackCount = 0;
    int dnfCount = 0;
    int dnsCount = 0;

    for (final a in session.startList.all) {
      final bibMarks = session.marking.officialMarksForBib(a.bib);
      final finishMarks = bibMarks.where((m) => m.type == MarkType.finish).toList();
      final hasFinish = finishMarks.length >= session.config.laps;

      if (a.status == AthleteStatus.dns) {
        dnsCount++;
      } else if (a.status == AthleteStatus.dnf) {
        dnfCount++;
      } else if (hasFinish) {
        finishedCount++;
      } else if (a.status == AthleteStatus.started || a.status == AthleteStatus.current) {
        onTrackCount++;
      }
    }

    // Build sorted results list
    final resultRows = _buildResultRows(session);

    return Column(children: [
      // ── Шапка: дни + дисциплины + статистика ──
      Container(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Multi-day
          if (_totalDays > 1) ...[
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              Icon(Icons.calendar_month, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              ...List.generate(_totalDays, (d) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('День ${d + 1}', style: const TextStyle(fontSize: 12)),
                  selected: _currentDay == d + 1,
                  onSelected: (_) => setState(() => _currentDay = d + 1),
                  visualDensity: VisualDensity.compact,
                ),
              )),
              ChoiceChip(
                label: Text('Общий', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _currentDay == 0 ? null : cs.tertiary)),
                selected: _currentDay == 0,
                onSelected: (_) => setState(() => _currentDay = 0),
                visualDensity: VisualDensity.compact,
              ),
            ])),
            const SizedBox(height: 6),
          ],
          // Дисциплины
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _chip('Скиджоринг 5км'), _chip('Скиджоринг 10км'), _chip('Каникросс 3км'), _chip('Нарты 15км'),
          ])),
          const SizedBox(height: 8),
          // Статистика (динамическая)
          Row(children: [
            _statPill(cs, theme, '$finishedCount', 'Финиш', cs.primary),
            const SizedBox(width: 6),
            _statPill(cs, theme, '$onTrackCount', 'На трассе', cs.tertiary),
            const SizedBox(width: 6),
            _statPill(cs, theme, '$dnfCount', 'DNF', cs.error),
            const SizedBox(width: 6),
            _statPill(cs, theme, '$dnsCount', 'DNS', cs.onSurfaceVariant),
            const Spacer(),
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

      // ── Таблица результатов ──
      Expanded(child: resultRows.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.hourglass_empty, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('Ожидание старта спортсменов...', style: TextStyle(color: cs.onSurfaceVariant)),
            ]))
          : AppProtocolTable(
              itemCount: resultRows.length,
              forceTableView: true,
              headerRow: AppProtocolRow(
                isHeader: true,
                bib: 'BIB',
                name: 'Спортсмен / Собака',
                cat: 'Кат.',
                dog: _showSplits ? 'CP1 / CP2' : 'Собака',
                time: 'Время',
                delta: 'Отст.',
                penalty: 'Штр.',
              ),
              itemBuilder: (ctx, i, isCard) {
                final r = resultRows[i];
                return AppProtocolRow(
                  isCardView: isCard,
                  place: r.place > 0 ? r.place : null,
                  placeText: r.placeText,
                  bib: r.bib,
                  name: r.name,
                  cat: r.category,
                  dog: _showSplits ? r.splitDisplay : r.dogName,
                  time: r.timeDisplay,
                  delta: r.deltaDisplay,
                  penalty: r.penaltyDisplay,
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
  // Build result rows from Timing Engine
  // ═══════════════════════════════════════

  List<_ResultRow> _buildResultRows(RaceSessionState session) {
    final athletes = session.startList.all;
    if (athletes.isEmpty) return [];

    final rows = <_ResultRow>[];
    Duration? leaderTime;

    // Separate: finished athletes (sorted by net time) + on track + DNF/DNS
    final finished = <_ResultRow>[];
    final onTrack = <_ResultRow>[];
    final statusRows = <_ResultRow>[]; // DNF, DNS

    for (final a in athletes) {
      final bibMarks = session.marking.officialMarksForBib(a.bib);
      final finishMarks = bibMarks.where((m) => m.type == MarkType.finish).toList();
      final hasFinish = finishMarks.length >= session.config.laps;

      // Include ALL checkpoint marks (including marshal) for visual info
      final allBibMarks = session.marking.marksForBib(a.bib);
      final allCheckpoints = allBibMarks.where((m) => m.type == MarkType.checkpoint).toList()
        ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));

      // Build split display: checkpoint splits + finish lap times
      final splitParts = <String>[];
      for (final cp in allCheckpoints) {
        splitParts.add(TimeFormatter.compact(_elapsedCalc.netTime(a, cp.correctedTime)));
      }
      if (finishMarks.isNotEmpty) {
        for (final fm in finishMarks) {
          splitParts.add(TimeFormatter.compact(_elapsedCalc.netTime(a, fm.correctedTime)));
        }
      }
      final splitDisplay = splitParts.isEmpty ? '—' : splitParts.join(' / ');

      if (a.status == AthleteStatus.dns) {
        statusRows.add(_ResultRow(
          place: -1, placeText: 'DNS', bib: a.bib, name: a.name,
          category: 'M', dogName: a.categoryName ?? '—', splitDisplay: splitDisplay,
          timeDisplay: 'DNS', deltaDisplay: '', penaltyDisplay: '—',
        ));
      } else if (a.status == AthleteStatus.dnf) {
        statusRows.add(_ResultRow(
          place: -1, placeText: 'DNF', bib: a.bib, name: a.name,
          category: 'M', dogName: a.categoryName ?? '—', splitDisplay: splitDisplay,
          timeDisplay: 'DNF', deltaDisplay: '', penaltyDisplay: '—',
        ));
      } else if (hasFinish) {
        final netTime = _elapsedCalc.netTime(a, finishMarks.last.correctedTime);
        finished.add(_ResultRow(
          place: 0, placeText: null, bib: a.bib, name: a.name,
          category: 'M', dogName: a.categoryName ?? '—', splitDisplay: splitDisplay,
          timeDisplay: TimeFormatter.full(netTime), deltaDisplay: '',
          penaltyDisplay: '—', netTime: netTime,
        ));
      } else {
        onTrack.add(_ResultRow(
          place: 0, placeText: 'LIVE', bib: a.bib, name: a.name,
          category: 'M', dogName: a.categoryName ?? '—', splitDisplay: splitDisplay,
          timeDisplay: 'на трассе', deltaDisplay: '', penaltyDisplay: '—',
        ));
      }
    }

    // Sort finished by net time
    finished.sort((a, b) => (a.netTime ?? Duration.zero).compareTo(b.netTime ?? Duration.zero));

    // Assign places and deltas
    for (int i = 0; i < finished.length; i++) {
      final r = finished[i];
      leaderTime ??= r.netTime;
      final delta = i == 0
          ? '—'
          : '+${TimeFormatter.compact(r.netTime! - leaderTime!)}';
      rows.add(r.copyWith(place: i + 1, deltaDisplay: delta));
    }

    // Add on-track athletes
    rows.addAll(onTrack);
    // Add DNF/DNS
    rows.addAll(statusRows);

    return rows;
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

  Widget _chip(String label) {
    final sel = _disc == label;
    return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: sel,
      onSelected: (_) => setState(() => _disc = label),
      visualDensity: VisualDensity.compact,
    ));
  }
}

// ═══════════════════════════════════════
// Data model for result rows
// ═══════════════════════════════════════

class _ResultRow {
  final int place;
  final String? placeText;
  final String bib;
  final String name;
  final String category;
  final String dogName;
  final String splitDisplay;
  final String timeDisplay;
  final String deltaDisplay;
  final String penaltyDisplay;
  final Duration? netTime;

  const _ResultRow({
    required this.place,
    this.placeText,
    required this.bib,
    required this.name,
    required this.category,
    required this.dogName,
    required this.splitDisplay,
    required this.timeDisplay,
    required this.deltaDisplay,
    required this.penaltyDisplay,
    this.netTime,
  });

  _ResultRow copyWith({int? place, String? deltaDisplay}) {
    return _ResultRow(
      place: place ?? this.place,
      placeText: placeText,
      bib: bib,
      name: name,
      category: category,
      dogName: dogName,
      splitDisplay: splitDisplay,
      timeDisplay: timeDisplay,
      deltaDisplay: deltaDisplay ?? this.deltaDisplay,
      penaltyDisplay: penaltyDisplay,
      netTime: netTime,
    );
  }
}

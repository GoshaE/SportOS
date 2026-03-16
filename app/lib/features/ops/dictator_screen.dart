import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: R4 — Диктор (с тап на атлета → карточка)
class DictatorScreen extends StatefulWidget {
  const DictatorScreen({super.key});

  @override
  State<DictatorScreen> createState() => _DictatorScreenState();
}

class _DictatorScreenState extends State<DictatorScreen> {
  String _disc = 'Sprint 5km';

  // ── Timing Engine ──
  late final RaceClock _raceClock;
  late final StartListService _startListService;
  late final MarkingService _markingService;
  late final ResultCalculator _resultCalc;
  late final DisciplineConfig _config;

  late List<RaceResult> _results;

  @override
  void initState() {
    super.initState();

    final raceStart = DateTime.now().subtract(const Duration(minutes: 42));

    _config = DisciplineConfig(
      id: 'disc-dictator',
      name: 'Sprint 5km',
      distanceKm: 5.0,
      startType: StartType.individual,
      interval: const Duration(seconds: 30),
      firstStartTime: raceStart,
      laps: 3,
    );

    _raceClock = RaceClock();
    _raceClock.start(raceStart);

    _startListService = StartListService(config: _config);
    _startListService.buildStartList([
      (entryId: 'e1', bib: '07', name: 'Петров А.А.', category: 'Скидж.', waveId: null),
      (entryId: 'e2', bib: '24', name: 'Иванов В.В.', category: 'Нарты', waveId: null),
      (entryId: 'e3', bib: '55', name: 'Волков Е.Е.', category: 'Пулка', waveId: null),
      (entryId: 'e4', bib: '12', name: 'Сидоров Б.Б.', category: 'Скидж.', waveId: null),
      (entryId: 'e5', bib: '77', name: 'Новиков З.З.', category: 'Нарты', waveId: null),
      (entryId: 'e6', bib: '42', name: 'Морозов Д.Д.', category: 'Скидж.', waveId: null),
      (entryId: 'e7', bib: '88', name: 'Кузнецов П.П.', category: 'Скидж.', waveId: null),
    ]);

    // Все стартовали
    for (final entry in _startListService.all) {
      _startListService.markStarted(entry.bib, actualTime: entry.plannedStartTime);
    }

    _markingService = MarkingService(
      minLapTime: const Duration(seconds: 10),
      totalLaps: 3,
    );

    // Demo: 5 финишировали с 3 кругами
    _addDemoFinish('07', const Duration(minutes: 38, seconds: 12));
    _addDemoFinish('24', const Duration(minutes: 39, seconds: 45));
    _addDemoFinish('55', const Duration(minutes: 41, seconds: 2));
    _addDemoFinish('12', const Duration(minutes: 41, seconds: 33));
    _addDemoFinish('77', const Duration(minutes: 42, seconds: 15));

    _resultCalc = const ResultCalculator();

    _results = _resultCalc.calculate(
      config: _config,
      startList: _startListService.all,
      marks: _markingService.marks,
      penalties: [],
    );
  }

  void _addDemoFinish(String bib, Duration elapsed) {
    final athlete = _startListService.findByBib(bib);
    if (athlete == null) return;

    // Add 3 laps per athlete
    for (var lap = 1; lap <= 3; lap++) {
      final lapTime = athlete.plannedStartTime.add(elapsed * lap ~/ 3);
      _markingService.insertMark(lapTime, bib: bib, entryId: bib, reason: 'demo');
    }
  }

  @override
  void dispose() {
    _raceClock.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Athlete card
  // ═══════════════════════════════════════

  void _showAthleteCard(BuildContext context, RaceResult result) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final position = '${result.position}-е место';
    final netStr = _fmtDur(result.netTime);

    // Split times from result
    final splitDurations = result.splitTimes;

    AppBottomSheet.show(
      context,
      title: 'BIB ${result.bib} — ${result.name}',
      initialHeight: 0.65,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: cs.primaryContainer, child: Text(result.bib, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('$position · $netStr', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text('Клуб: Хаски Урал · Екатеринбург', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 24),

        // Собака
        Text('Собака', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            AppStatusRow(
              icon: Icons.pets,
              title: 'Rex',
              subtitle: 'Сибирский хаски · 4 года',
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Split-times
        Text('Split-times по кругам', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            for (var i = 0; i < splitDurations.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AppSplitRow(
                label: 'Круг ${i + 1}',
                time: _fmtDurMs(splitDurations[i]),
                delta: i == 0 ? null : _formatDelta(splitDurations[i] - splitDurations[i - 1]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // История
        Text('История стартов', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Text('🥈', style: TextStyle(fontSize: 20)), title: const Text('Кубок Сибири 2025'), subtitle: Text('Скидж. 10км — 01:12:45', style: TextStyle(color: cs.onSurfaceVariant))),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Text('🥉', style: TextStyle(fontSize: 20)), title: const Text('Кубок Урала 2025'), subtitle: Text('Скидж. 5км — 00:40:20', style: TextStyle(color: cs.onSurfaceVariant))),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtDur(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtDurMs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '00:$m:$s';
  }

  String? _formatDelta(Duration delta) {
    final sign = delta.isNegative ? '-' : '+';
    final abs = delta.abs();
    return '$sign${abs.inSeconds}с';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final finishedCount = _markingService.finishedCount;
    final totalAthletes = _startListService.all.length;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Диктор'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.error, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(children: [
        // ── Инфо-панель ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(children: [
                Icon(Icons.mic, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Live трансляция', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.directions_run, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('$finishedCount/$totalAthletes финишировали', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: AppDisciplineChips(
            items: const ['Sprint 5km', 'Sprint 10km', 'Каникросс', 'Нарты'],
            selected: _disc,
            onSelected: (v) => setState(() => _disc = v),
          ),
        ),

        // ── ТОП-5 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('ТОП-5', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...List.generate(_results.length.clamp(0, 5), (i) {
          final result = _results[i];
          final medal = switch (i) { 0 => '🥇', 1 => '🥈', 2 => '🥉', _ => null };
          final bool isTop3 = i < 3;
          final netStr = _fmtDur(result.netTime);
          final gapStr = result.gapToLeader != null ? '+${_fmtDur(result.gapToLeader!)}' : '—';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: AppCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              backgroundColor: isTop3 ? cs.primaryContainer.withValues(alpha: 0.08 * (3 - i)) : cs.surface,
              borderColor: isTop3 ? cs.primary.withValues(alpha: 0.2 * (3 - i)) : cs.outlineVariant.withValues(alpha: 0.3),
              children: [
                ListTile(
                  dense: true,
                  leading: medal != null
                    ? Text(medal, style: const TextStyle(fontSize: 22))
                    : SizedBox(width: 28, child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                  title: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                      child: Text(result.bib, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.name, style: TextStyle(fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal))),
                  ]),
                  subtitle: Row(children: [
                    Text(netStr, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: i == 0 ? cs.primary : null)),
                    if (gapStr != '—') ...[const SizedBox(width: 8), Text(gapStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))],
                  ]),
                  trailing: Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                  onTap: () => _showAthleteCard(context, result),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // ── Последний финиш и На трассе (Bento Grid) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
                borderColor: cs.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(children: [
                    Icon(Icons.flag, color: cs.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Последний финиш', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
                  ]),
                  const SizedBox(height: 8),
                  if (_results.isNotEmpty) ...[
                    Text('BIB ${_results.last.bib} ${_results.last.name.split(' ').first}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_fmtDur(_results.last.netTime)} (${_results.last.position}-е место)', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.15),
                borderColor: cs.tertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(children: [
                    Icon(Icons.timeline, color: cs.tertiary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text('На трассе: ${totalAthletes - finishedCount}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary))),
                  ]),
                  const SizedBox(height: 8),
                  Text('~2 мин до финиша', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('BIB 42 Морозов', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Подсказки для диктора ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text('Подсказки', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        ),
        if (_results.length >= 3)
          _hintCard(cs, theme, Icons.local_fire_department, 'BIB ${_results[2].bib} вошёл в ТОП-3!', cs.tertiary),
        if (_results.length > 1)
          _hintCard(cs, theme, Icons.emoji_events, '${_results.first.name} лидирует с отрывом +${_fmtDur(_results[1].gapToLeader ?? Duration.zero)}', cs.primary),
        _hintCard(cs, theme, Icons.timer, 'Последний на трассе: BIB 88 Кузнецов — на 2-м кругу', cs.primary),
        _hintCard(cs, theme, Icons.trending_up, 'Средняя скорость лидера: ${_results.isNotEmpty ? (_results.first.speedKmh?.toStringAsFixed(1) ?? '?') : '?'} км/ч', cs.onSurfaceVariant),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _hintCard(ColorScheme cs, ThemeData theme, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: color.withValues(alpha: 0.06),
        borderColor: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500))),
          ]),
        ],
      ),
    );
  }
}

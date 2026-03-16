
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: CT1 — Тренерский Хронометраж (Live-отсечки + разрывы)
///
/// Три таба:
/// 1. Гонка — live-таблица соревнования (read-only)
/// 2. Мои отсечки — BIB-сетка + Секундомер + таблица разрывов
/// 3. Аналитика — полная таблица сплитов + экспорт
class CoachTimingScreen extends ConsumerStatefulWidget {
  const CoachTimingScreen({super.key});

  @override
  ConsumerState<CoachTimingScreen> createState() => _CoachTimingScreenState();
}

class _CoachTimingScreenState extends ConsumerState<CoachTimingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Режим ввода: сетка или секундомер ──
  bool _isStopwatchMode = false;

  final ElapsedCalculator _elapsedCalc = const ElapsedCalculator();

  // ── UI state ──
  Duration _elapsed = Duration.zero;
  int _selectedLapFilter = 0; // 0 = все

  // ── Mock: официальные результаты (таб "Гонка") ──
  final List<Map<String, dynamic>> _raceResults = [
    {'pos': 1, 'bib': '07', 'name': 'Петров А.', 'split1': '04:12', 'finish': '12:34', 'gap': '—', 'status': 'finished'},
    {'pos': 2, 'bib': '24', 'name': 'Иванов В.', 'split1': '04:18', 'finish': '12:57', 'gap': '+0:23', 'status': 'finished'},
    {'pos': 3, 'bib': '42', 'name': 'Морозов Д.', 'split1': '04:25', 'finish': '13:15', 'gap': '+0:41', 'status': 'finished'},
    {'pos': 4, 'bib': '31', 'name': 'Козлов Г.', 'split1': '04:30', 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 5, 'bib': '55', 'name': 'Волков Е.', 'split1': '04:35', 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 6, 'bib': '63', 'name': 'Лебедев Ж.', 'split1': null, 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 7, 'bib': '12', 'name': 'Сидоров Б.', 'split1': null, 'finish': null, 'gap': null, 'status': 'started'},
    {'pos': 8, 'bib': '77', 'name': 'Новиков З.', 'split1': null, 'finish': null, 'gap': null, 'status': 'dns'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);

    // Подписка на тик часов из сессии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(raceSessionProvider);
      session?.clock.addListener(_onClockTick);
    });
  }

  void _onClockTick(Duration elapsed) {
    if (mounted) setState(() => _elapsed = elapsed);
  }

  @override
  void dispose() {
    _tabController.dispose();
    ref.read(raceSessionProvider)?.clock.removeListener(_onClockTick);
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Логика отсечек (через MarkingService)
  // ═══════════════════════════════════════

  /// Добавить быструю отсечку (секундомер) без BIB
  void _addQuickMark() {
    HapticFeedback.heavyImpact();
    ref.read(raceSessionProvider.notifier).addMark();
  }

  /// Назначить BIB конкретной отсечке
  void _assignBib(String markId, String bib) {
    ref.read(raceSessionProvider.notifier).assignBib(markId, bib, entryId: bib);
  }

  /// Отсечка из сетки BIB (тап по плитке)
  void _markFromGrid(String bib) {
    HapticFeedback.mediumImpact();
    final session = ref.read(raceSessionProvider);
    if (session == null) return;
    final athlete = session.startList.findByBib(bib);
    if (athlete == null) return;

    final notifier = ref.read(raceSessionProvider.notifier);
    final mark = notifier.addMark();
    if (mark == null) return;

    notifier.assignBib(mark.id, bib, entryId: bib);

    final lap = session.marking.resolveCurrentLap(bib);
    final elapsed = _elapsedCalc.netTime(athlete, mark.correctedTime);

    AppSnackBar.success(context, 'BIB $bib · Круг ${lap - 1} · ${_fmtDur(elapsed)} от старта');
  }

  /// Удалить отсечку
  void _removeMark(String markId) {
    ref.read(raceSessionProvider.notifier).deleteMark(markId);
  }

  /// BIB-пикер
  void _showBibPicker(String markId) {
    AppBottomSheet.show(
      context,
      title: 'Назначить BIB',
      initialHeight: 0.6,
      child: Builder(builder: (ctx) {
        final session = ref.read(raceSessionProvider);
        if (session == null) return const SizedBox();
        return GridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        maxCrossAxisExtent: 130,
        childAspectRatio: 1.1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: session.startList.all.map((a) {
          final bibMarks = session.marking.marksForBib(a.bib);
          final alreadyMarked = bibMarks.isNotEmpty;
          return AppBibTile(
            bib: a.bib,
            name: a.name,
            lapInfo: alreadyMarked
                ? 'Круг ${bibMarks.length}'
                : 'Старт: ${_fmtTime(a.effectiveStartTime)}',
            state: alreadyMarked ? BibState.assigned : BibState.available,
            onTap: () {
              _assignBib(markId, a.bib);
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'BIB ${a.bib} назначен');
            },
          );
        }).toList(),
      );
      }),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtDur(Duration d) {
    if (d.isNegative) return '-${_fmtDur(-d)}';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDurMs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Построить таблицу разрывов через GapCalculator
  List<GapRow> _buildGapRows(int lap) {
    final session = ref.read(raceSessionProvider);
    if (session == null) return [];
    final marks = session.marking.marks;
    final starts = session.startList.all;
    final gapCalc = session.gap;

    // Отфильтровать tracked BIBs (те, у кого есть отсечки)
    final trackedBibs = marks
        .where((m) => m.bib != null)
        .map((m) => m.bib!)
        .toSet()
        .toList();

    if (trackedBibs.isEmpty) return [];

    if (lap == 0) {
      // "Все" — показать последний круг каждого
      final allRows = gapCalc.gapTable(trackedBibs, marks, starts);
      // Взять последний круг каждого BIB
      final Map<String, GapRow> latest = {};
      for (final r in allRows) {
        latest[r.bib] = r;
      }
      final rows = latest.values.toList()
        ..sort((a, b) => a.elapsed.compareTo(b.elapsed));
      return rows;
    } else {
      // Конкретный круг
      final ranked = gapCalc.rankedAtLap(lap, marks, starts);
      return ranked.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final athlete = starts.where((s) => s.bib == r.bib).firstOrNull;

        // Lap split
        final laps = athlete != null
            ? _elapsedCalc.lapTimes(r.bib, marks, athlete)
            : <Duration>[];
        final lapSplit = lap <= laps.length ? laps[lap - 1] : null;

        return GapRow(
          bib: r.bib,
          name: r.name,
          lap: lap,
          elapsed: r.elapsed,
          gapToLeader: i == 0 ? null : gapCalc.gapToLeader(r.bib, lap, marks, starts),
          trend: gapCalc.trend(r.bib, lap, marks, starts),
          gapToPrev: lapSplit,
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Хронометраж'),
        actions: [
          // ── Часы мероприятия ──
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_fmtElapsed(_elapsed), style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w900, color: cs.error)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 20, color: cs.onSurfaceVariant),
            tooltip: 'Настройки',
            onPressed: () => _showSettings(context),
          ),
        ],
        bottom: AppPillTabBar(
          controller: _tabController,
          tabs: const ['Гонка', 'Мои отсечки', 'Аналитика'],
          icons: const [Icons.leaderboard, Icons.timer, Icons.analytics],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRaceTab(theme, cs),
          _buildMarksTab(theme, cs),
          _buildAnalyticsTab(theme, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Настройки
  // ═══════════════════════════════════════
  void _showSettings(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Настройки тренера',
      initialHeight: 0.4,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Количество кругов на трассе:', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children: [
          for (final n in [1, 2, 3, 4, 5])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$n'),
                selected: (ref.read(raceSessionProvider)?.config.laps ?? 3) == n,
                onSelected: (_) {},  // TODO: Laps come from session config
              ),
            ),
        ]),
        const SizedBox(height: 16),
        AppInfoBanner.info(title: 'Разрывы рассчитываются с учётом времени старта каждого спортсмена (интервальный старт).'),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Таб 1: Гонка (Read-only live)
  // ═══════════════════════════════════════
  Widget _buildRaceTab(ThemeData theme, ColorScheme cs) {
    return Column(children: [
      // Заголовок
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${ref.watch(raceSessionProvider)?.config.name ?? 'Sprint'} · ${ref.watch(raceSessionProvider)?.config.laps ?? 0} кр.', style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(fontSize: 10, color: cs.error, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),

      // Заголовок таблицы
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          SizedBox(width: 40, child: Text('BIB', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Имя', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          SizedBox(width: 55, child: Text('КП1', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 60, child: Text('Финиш', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 55, child: Text('Δ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ]),
      ),
      const Divider(height: 1),

      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _raceResults.length,
          itemBuilder: (context, i) {
            final r = _raceResults[i];
            final status = r['status'] as String;
            final isFinished = status == 'finished';
            final isDns = status == 'dns';
            final isOnCourse = status == 'on_course' || status == 'started';
            final statusColor = isFinished ? cs.primary : isDns ? cs.error : cs.tertiary;
            final statusIcon = isFinished ? Icons.check_circle : isDns ? Icons.block : Icons.directions_run;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1)))),
              child: Row(children: [
                SizedBox(width: 32, child: Row(children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text('${r['pos']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ])),
                SizedBox(width: 40, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                  child: Text('${r['bib']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                )),
                const SizedBox(width: 4),
                Expanded(child: Text('${r['name']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDns ? cs.outline : cs.onSurface, decoration: isDns ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 55, child: Text(r['split1'] ?? '—', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: r['split1'] != null ? cs.onSurface : cs.outline), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text(r['finish'] ?? (isOnCourse ? '...' : '—'), style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: isFinished ? FontWeight.bold : FontWeight.normal, color: isFinished ? cs.primary : cs.outline), textAlign: TextAlign.center)),
                SizedBox(width: 55, child: Text(r['gap'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r['gap'] == '—' ? cs.primary : cs.error), textAlign: TextAlign.center)),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Таб 2: Мои отсечки
  // ═══════════════════════════════════════
  Widget _buildMarksTab(ThemeData theme, ColorScheme cs) {
    final session = ref.watch(raceSessionProvider);
    if (session == null) return const Center(child: Text('Нет сессии'));
    final marks = session.marking.marks;
    final assignedMarks = marks.where((m) => m.isAssigned).toList();

    return Column(children: [
      // ── Переключатель: Сетка / Секундомер ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(4),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              children: [
                SizedBox(
                  height: 38,
                  child: Row(children: [
                    _modeButton('Сетка BIB', Icons.grid_view, !_isStopwatchMode, cs, () => setState(() => _isStopwatchMode = false)),
                    _modeButton('Секундомер', Icons.timer, _isStopwatchMode, cs, () => setState(() => _isStopwatchMode = true)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            children: [
              Row(children: [
                Icon(Icons.bookmark, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('${assignedMarks.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
              ]),
            ],
          ),
        ]),
      ),

      // ── Основной контент ──
      Expanded(
        child: _isStopwatchMode
            ? _buildStopwatchMode(theme, cs)
            : _buildGridMode(theme, cs),
      ),

      // ── Таблица разрывов (внизу) ──
      if (assignedMarks.isNotEmpty) _buildGapTable(theme, cs),
    ]);
  }

  Widget _modeButton(String label, IconData icon, bool active, ColorScheme cs, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: active ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? cs.onSurface : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? cs.onSurface : cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  // ── Режим Сетка BIB ──
  Widget _buildGridMode(ThemeData theme, ColorScheme cs) {
    final session = ref.watch(raceSessionProvider);
    if (session == null) return const Center(child: Text('Нет сессии'));
    final totalLaps = session.config.laps;
    return GridView.extent(
      maxCrossAxisExtent: 130,
      childAspectRatio: 0.85,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: session.startList.all.map((a) {
        final bibMarks = session.marking.marksForBib(a.bib);
        final lapCount = bibMarks.length;
        final hasMarks = lapCount > 0;

        // Последний сплит
        String? splitInfo;
        if (hasMarks) {
          final elapsed = _elapsedCalc.netTime(a, bibMarks.last.correctedTime);
          splitInfo = _fmtDur(elapsed);
        }

        final lapInfo = hasMarks
            ? 'Круг $lapCount/$totalLaps${splitInfo != null ? '\n⏱$splitInfo' : ''}'
            : 'Старт: ${_fmtTime(a.effectiveStartTime)}';

        return AppBibTile(
          bib: a.bib,
          name: a.name,
          lapInfo: lapInfo,
          state: hasMarks
              ? (lapCount >= totalLaps ? BibState.finished : BibState.current)
              : BibState.available,
          onTap: () => _markFromGrid(a.bib),
        );
      }).toList(),
    );
  }

  // ── Режим Секундомер ──
  Widget _buildStopwatchMode(ThemeData theme, ColorScheme cs) {
    final session = ref.watch(raceSessionProvider);
    if (session == null) return const Center(child: Text('Нет сессии'));
    final unassignedMarks = session.marking.unassigned;

    return Column(children: [
      if (unassignedMarks.isNotEmpty)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: unassignedMarks.length,
            itemBuilder: (context, i) {
              final mark = unassignedMarks[i];
              final raceTime = mark.correctedTime.difference(session.clock.zeroTime!);
              return Dismissible(
                key: ValueKey('mark-${mark.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeMark(mark.id),
                background: Container(
                  color: cs.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: cs.onError),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.1),
                    borderColor: cs.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    children: [
                      InkWell(
                        onTap: () => _showBibPicker(mark.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.tertiary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_fmtDurMs(raceTime), style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                              Text('🕐 ${_fmtTime(mark.correctedTime)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Назначить BIB', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold, fontSize: 12)),
                              Icon(Icons.touch_app, color: cs.tertiary, size: 20),
                            ]),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      else
        Expanded(
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Нажмите кнопку ОТСЕЧКА', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text('когда спортсмен проходит вашу точку', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
          ])),
        ),

      // Большая кнопка ОТСЕЧКА
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.1),
            borderColor: cs.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addQuickMark,
                  splashColor: cs.primary.withValues(alpha: 0.2),
                  highlightColor: cs.primary.withValues(alpha: 0.1),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.timer_sharp, size: 40, color: cs.primary),
                      const SizedBox(height: 8),
                      Text('ОТСЕЧКА', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 3)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Таблица разрывов (через Timing Engine)
  // ═══════════════════════════════════════
  Widget _buildGapTable(ThemeData theme, ColorScheme cs) {
    final session = ref.watch(raceSessionProvider);
    if (session == null) return const Center(child: Text('Нет сессии'));
    final assignedMarks = session.marking.assigned;
    final lapsWithData = <int>{};
    for (final m in assignedMarks) {
      if (m.lapNumber != null) lapsWithData.add(m.lapNumber!);
    }

    final gapRows = _buildGapRows(_selectedLapFilter);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Заголовок + переключатель кругов
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Icon(Icons.compare_arrows, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text('Разрывы', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [
                  _buildLapChip('Все', 0, cs),
                  for (final lap in lapsWithData.toList()..sort())
                    _buildLapChip('Кр.$lap', lap, cs),
                ],
              ),
            ),
          ]),
        ),

        // Заголовок колонок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            SizedBox(width: 18, child: Text('#', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            SizedBox(width: 28, child: Text('BIB', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Имя', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            SizedBox(width: 50, child: Text('Время', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            SizedBox(width: 45, child: Text('Круг', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            SizedBox(width: 60, child: Text('Разрыв', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ]),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),

        // Таблица
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 170),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            itemCount: gapRows.length,
            itemBuilder: (context, i) {
              final r = gapRows[i];
              final isLeader = i == 0;
              final trendIcon = r.trend == '▲' ? '▲' : r.trend == '▼' ? '▼' : r.trend == '=' ? '=' : '';
              final trendColor = r.trend == '▲' ? Colors.green : r.trend == '▼' ? cs.error : cs.onSurfaceVariant;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  // Позиция
                  SizedBox(width: 18, child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: isLeader ? FontWeight.w900 : FontWeight.w600, color: isLeader ? cs.primary : cs.onSurfaceVariant))),
                  // BIB
                  SizedBox(width: 28, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
                    child: Text(r.bib, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  )),
                  const SizedBox(width: 4),
                  // Имя
                  Expanded(child: Text(r.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
                  // Elapsed от старта
                  SizedBox(width: 50, child: Text(_fmtDur(r.elapsed), style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: cs.onSurface), textAlign: TextAlign.center)),
                  // Сплит круга
                  SizedBox(width: 45, child: Text(r.gapToPrev != null ? _fmtDur(r.gapToPrev!) : '—', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
                  // Разрыв от лидера + тренд
                  SizedBox(width: 60, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (trendIcon.isNotEmpty) Text(trendIcon, style: TextStyle(fontSize: 10, color: trendColor)),
                    const SizedBox(width: 2),
                    Text(
                      isLeader ? '—' : '+${_fmtDur(r.gapToLeader ?? Duration.zero)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLeader ? cs.primary : cs.error),
                    ),
                  ])),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildLapChip(String label, int lap, ColorScheme cs) {
    final selected = _selectedLapFilter == lap;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => setState(() => _selectedLapFilter = lap),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? cs.primary : cs.onSurfaceVariant)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Таб 3: Аналитика
  // ═══════════════════════════════════════
  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme cs) {
    final session = ref.watch(raceSessionProvider);
    if (session == null) return const Center(child: Text('Нет сессии'));
    final marks = session.marking.marks;
    final assignedMarks = marks.where((m) => m.isAssigned).toList();

    if (assignedMarks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.analytics_outlined, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        Text('Пока нет данных', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Поставьте отсечки на табе «Мои отсечки»', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
      ]));
    }

    // Группируем по BIB
    final Map<String, List<TimeMark>> byBib = {};
    for (final m in assignedMarks) {
      byBib.putIfAbsent(m.bib!, () => []).add(m);
    }

    // Сортируем BIB по elapsed (кто быстрее)
    final starts = session.startList.all;
    final sortedBibs = byBib.entries.toList()
      ..sort((a, b) {
        final aAthlete = starts.where((s) => s.bib == a.key).firstOrNull;
        final bAthlete = starts.where((s) => s.bib == b.key).firstOrNull;
        if (aAthlete == null || bAthlete == null) return 0;
        final aElapsed = _elapsedCalc.netTime(aAthlete, a.value.last.correctedTime);
        final bElapsed = _elapsedCalc.netTime(bAthlete, b.value.last.correctedTime);
        return aElapsed.compareTo(bElapsed);
      });

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Сводная статистика
      Row(children: [
        AppStatCard(value: '${byBib.keys.length}', label: 'Спортсменов', icon: Icons.people),
        const SizedBox(width: 8),
        AppStatCard(value: '${assignedMarks.length}', label: 'Отсечек', icon: Icons.timer),
        const SizedBox(width: 8),
        AppStatCard(value: '${session.config.laps}', label: 'Кругов', icon: Icons.loop, color: cs.tertiary),
      ]),
      const SizedBox(height: 16),

      // Заголовок
      Text('ТАБЛИЦА СПЛИТОВ (от старта)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text('Время — elapsed от персонального старта спортсмена', style: TextStyle(fontSize: 10, color: cs.outline)),
      const SizedBox(height: 8),

      // Таблица сплитов по кругам
      AppCard(
        padding: const EdgeInsets.all(12),
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        children: [
          // Заголовок
          Row(children: [
            SizedBox(width: 40, child: Text('BIB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
            Expanded(child: Text('Имя', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
            for (int lap = 1; lap <= session.config.laps; lap++)
              SizedBox(width: 55, child: Text('Кр.$lap', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
            SizedBox(width: 55, child: Text('Δ лидер', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
          ]),
          const Divider(height: 16),

          ...sortedBibs.asMap().entries.map((entry) {
            final i = entry.key;
            final bib = entry.value.key;
            final bibMarks = entry.value.value..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
            final isLeader = i == 0;
            final athlete = starts.where((s) => s.bib == bib).firstOrNull;

            // Splits через ElapsedCalculator
            final splits = athlete != null
                ? _elapsedCalc.splitTimes(bib, marks, athlete)
                : <Duration>[];

            // Разрыв от лидера
            String gapText = '—';
            if (!isLeader && athlete != null && bibMarks.isNotEmpty) {
              final leaderBib = sortedBibs.first.key;
              final leaderAthlete = starts.where((s) => s.bib == leaderBib).firstOrNull;
              if (leaderAthlete != null) {
                final leaderBibMarks = sortedBibs.first.value;
                final myElapsed = _elapsedCalc.netTime(athlete, bibMarks.last.correctedTime);
                final leaderElapsed = _elapsedCalc.netTime(leaderAthlete, leaderBibMarks.last.correctedTime);
                final gap = myElapsed - leaderElapsed;
                gapText = '+${_fmtDur(gap)}';
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 40, child: Text(bib, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isLeader ? cs.primary : cs.onSurface))),
                Expanded(child: Text(athlete?.name ?? '?', style: TextStyle(fontSize: 12, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
                for (int lap = 1; lap <= session.config.laps; lap++)
                  SizedBox(width: 55, child: () {
                    if (lap <= splits.length) {
                      return Text(_fmtDur(splits[lap - 1]), style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.onSurface), textAlign: TextAlign.center);
                    }
                    return Text('—', style: TextStyle(fontSize: 11, color: cs.outline), textAlign: TextAlign.center);
                  }()),
                SizedBox(width: 55, child: Text(gapText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gapText == '—' ? cs.primary : cs.error), textAlign: TextAlign.center)),
              ]),
            );
          }),
        ],
      ),
      const SizedBox(height: 16),

      // Кнопки экспорта
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => AppSnackBar.info(context, 'Экспорт PDF → скоро'),
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('PDF'),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => AppSnackBar.info(context, 'Экспорт Excel → скоро'),
          icon: const Icon(Icons.table_chart, size: 16),
          label: const Text('Excel'),
        )),
      ]),
    ]);
  }
}

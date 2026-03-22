import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';
import '../../domain/timing/result_table.dart';

/// QT3 — Live хронометраж быстрой сессии.
///
/// Масс-старт: 2 закладки (Финиш + Таблица)
/// Интервальный / Ручной: 3 закладки (Старт + Финиш + Таблица)
///
/// Использует существующие компоненты:
/// - [AppResultTable] + [ResultTable] — таблица результатов
/// - [AppInfoBanner] — подсказки и баннеры
/// - [AppQueueItem] — элементы очереди
/// - [AppBibTile] — плитки на вкладке Финиш
/// - [AppStatCard] — статистика
/// - [AppBottomSheet] — модальное окно деталей
class QuickTimerScreen extends ConsumerStatefulWidget {
  const QuickTimerScreen({super.key});

  @override
  ConsumerState<QuickTimerScreen> createState() => _QuickTimerScreenState();
}

class _QuickTimerScreenState extends ConsumerState<QuickTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;
  late TabController _tabCtrl;
  bool _showCards = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(quickSessionProvider);
    final hasTabs3 = session?.mode != QuickStartMode.mass;
    _tabCtrl = TabController(length: hasTabs3 ? 3 : 2, vsync: this);

    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final s = ref.read(quickSessionProvider);
      if (s == null || s.status != QuickSessionStatus.running || !mounted) return;
      final start = s.globalStartTime;
      if (start != null) {
        setState(() => _elapsed = DateTime.now().difference(start));
      }

      // Авто-старт для интервального режима
      if (s.mode == QuickStartMode.interval) {
        _autoStartCheck(s);
      }
    });
  }

  void _autoStartCheck(QuickSession session) {
    if (session.globalStartTime == null) return;
    final now = DateTime.now();
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    for (final a in sorted) {
      if (a.startTime != null) continue;
      final planned = session.plannedStartTime(a);
      if (planned == null) continue;
      if (now.isAfter(planned) || now.isAtSameMomentAs(planned)) {
        ref.read(quickSessionProvider.notifier).startIndividualAt(a.id, planned);
      } else {
        break;
      }
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════

  void _startMass() {
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).startMass();
  }

  void _startIndividual(String athleteId) {
    HapticFeedback.mediumImpact();
    ref.read(quickSessionProvider.notifier).startIndividual(athleteId);
  }

  void _recordSplit(String athleteId) {
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).recordSplit(athleteId);
    final session = ref.read(quickSessionProvider);
    if (session != null && session.allFinished) {
      ref.read(quickSessionProvider.notifier).finishSession();
      ref.read(quickSessionProvider.notifier).saveToHistory();
      ref.read(quickHistoryProvider.notifier).refresh();
      if (mounted) {
        _tabCtrl.animateTo(_tabCtrl.length - 1);
        AppSnackBar.success(context, 'Все финишировали! Результаты сохранены.');
      }
    }
  }

  void _finishManually() {
    ref.read(quickSessionProvider.notifier).finishSession();
    ref.read(quickSessionProvider.notifier).saveToHistory();
    ref.read(quickHistoryProvider.notifier).refresh();
    if (mounted) {
      _tabCtrl.animateTo(_tabCtrl.length - 1);
      AppSnackBar.success(context, 'Сессия завершена. Результаты сохранены.');
    }
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtCountdown(Duration d) {
    if (d.isNegative) {
      final abs = d.abs();
      final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '+$m:$s';
    }
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = ref.watch(quickSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Секундомер')),
        body: const Center(child: Text('Нет активной сессии.')),
      );
    }

    final mode = session.mode;
    final isRunning = session.status == QuickSessionStatus.running;
    final hasTabs3 = mode != QuickStartMode.mass;

    final tabs = hasTabs3
        ? const [Tab(text: 'Старт'), Tab(text: 'Финиш'), Tab(text: 'Таблица')]
        : const [Tab(text: 'Финиш'), Tab(text: 'Таблица')];

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Секундомер'),
        actions: [
          // Общий таймер
          if (isRunning) Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              TimeFormatter.full(_elapsed),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: cs.error),
            ),
          ),
          // Счётчик финиша
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flag, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text('${session.finishedCount}/${session.athletes.length}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
            ]),
          ),
          if (isRunning)
            IconButton(
              icon: Icon(Icons.stop_circle, color: cs.error),
              tooltip: 'Завершить',
              onPressed: () async {
                final confirm = await AppDialog.confirm(
                  context,
                  title: 'Завершить сессию?',
                  message: 'Результаты будут сохранены.',
                );
                if (confirm == true) _finishManually();
              },
            ),
        ],
        bottom: TabBar(controller: _tabCtrl, tabs: tabs),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: hasTabs3
            ? [
                _buildStartTab(session, cs, isRunning),
                _buildFinishTab(session, cs, isRunning),
                _buildTableTab(session, cs),
              ]
            : [
                _buildFinishTab(session, cs, isRunning),
                _buildTableTab(session, cs),
              ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Tab 1: СТАРТ (интервальный + ручной)
  // ═══════════════════════════════════════
  Widget _buildStartTab(QuickSession session, ColorScheme cs, bool isRunning) {
    final isInterval = session.mode == QuickStartMode.interval;
    final current = session.currentStarter;
    final startedCount = session.startedCount;
    final totalCount = session.athletes.length;
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    // Обратный отсчёт (для интервального)
    Duration? countdown;
    if (isInterval && current != null && session.globalStartTime != null) {
      final planned = session.plannedStartTime(current);
      if (planned != null) {
        countdown = planned.difference(DateTime.now());
      }
    }
    final isUrgent = countdown != null && countdown.inSeconds <= 5 && countdown.inSeconds >= 0;
    final isOverdue = countdown != null && countdown.isNegative;

    return Column(children: [
      // ── AppInfoBanner: подсказка до старта ──
      if (!isRunning)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.info(
            title: isInterval ? 'Интервальный старт' : 'Ручной старт',
            subtitle: isInterval
                ? 'Нажмите «Старт» — первый спортсмен уйдёт. '
                  'Далее остальные стартуют автоматически каждые ${session.intervalSeconds} сек.'
                : 'Нажимайте на каждого спортсмена, когда он готов к старту.',
          ),
        ),

      // ── Первый атлет (до старта) ──
      if (!isRunning && current != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: AppInfoBanner(
            title: 'Первый: ${current.bib} — ${current.name}',
            subtitle: isInterval ? 'Интервал: ${session.intervalSeconds} сек' : null,
            type: BannerType.success,
            icon: Icons.person,
          ),
        ),

      // ── Обратный отсчёт (интервальный, гонка идёт) ──
      if (isInterval && isRunning && current != null && countdown != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: isOverdue
                ? cs.error.withValues(alpha: 0.15)
                : isUrgent
                    ? cs.errorContainer.withValues(alpha: 0.15)
                    : cs.primaryContainer.withValues(alpha: 0.1),
            borderColor: isOverdue
                ? cs.error.withValues(alpha: 0.4)
                : isUrgent
                    ? cs.error.withValues(alpha: 0.3)
                    : cs.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isOverdue ? 'ОПОЗДАНИЕ!' : isUrgent ? 'ВНИМАНИЕ' : 'ДО СТАРТА',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue || isUrgent ? cs.error : cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _fmtCountdown(countdown),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: isOverdue || isUrgent ? cs.error : cs.primary,
                      height: 1.1,
                    ),
                  ),
                ]),
                Icon(
                  isOverdue ? Icons.error : isUrgent ? Icons.volume_up : Icons.schedule,
                  size: 36,
                  color: (isOverdue || isUrgent ? cs.error : cs.primary).withValues(alpha: 0.8),
                ),
              ]),
              const SizedBox(height: 8),
              AppQueueItem(
                leading: Icon(Icons.person, color: cs.primary, size: 22),
                title: Text('${current.bib} — ${current.name}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.primary)),
                subtitle: const Text('Следующий'),
                dense: true,
                backgroundColor: cs.surface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

      // ── Все стартовали ──
      if (current == null && startedCount == totalCount && isRunning)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.success(
            title: 'Все стартовали!',
            subtitle: 'Переключитесь на вкладку «Финиш».',
          ),
        ),

      // ── Заголовок списка ──
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('СТАРТ-ЛИСТ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
          Text('$startedCount/$totalCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
        ]),
      ),

      // ── Очередь (AppQueueItem) ──
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 4, bottom: 8),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final a = sorted[i];
            final hasStarted = a.startTime != null;
            final isCurrent = current?.id == a.id;

            final color = hasStarted ? cs.primary : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
            final icon = hasStarted ? Icons.check_circle : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
            final statusText = hasStarted ? 'Ушёл' : isCurrent ? 'Текущий' : 'Ожидает';

            return AppQueueItem(
              leading: Icon(icon, color: color, size: 24),
              title: Text('${a.bib} — ${a.name}',
                style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: cs.onSurface)),
              subtitle: Text(statusText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              trailing: !isInterval && !hasStarted
                  ? Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4))
                  : null,
              backgroundColor: isCurrent
                  ? cs.tertiaryContainer.withValues(alpha: 0.1)
                  : hasStarted
                      ? cs.primaryContainer.withValues(alpha: 0.05)
                      : null,
              onTap: !isInterval && !hasStarted ? () => _startIndividual(a.id) : null,
            );
          },
        ),
      ),

      // ── Кнопка СТАРТ (интервальный: только первый) ──
      if (!isRunning && current != null && isInterval)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.danger(
              text: 'СТАРТ',
              icon: Icons.play_arrow,
              onPressed: () => _startIndividual(current.id),
            ),
          ),
        ),

      // ── Ручной режим: подсказка ──
      if (!isRunning && !isInterval)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: AppInfoBanner.info(
              title: 'Нажмите на спортсмена для старта',
            ),
          ),
        ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 2: ФИНИШ (все режимы)
  // ═══════════════════════════════════════
  Widget _buildFinishTab(QuickSession session, ColorScheme cs, bool isRunning) {
    final isMass = session.mode == QuickStartMode.mass;

    return Column(children: [
      // ── Таймер для масс-старта ──
      if (isMass) _buildMassTimer(cs, isRunning),

      // ── Сетка BibTile ──
      Expanded(
        child: GridView.extent(
          maxCrossAxisExtent: 140,
          childAspectRatio: 0.85,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: session.athletes.map((a) {
            final finished = a.isFinished(session.totalLaps);
            final laps = a.completedLaps;
            final hasStarted = isMass ? isRunning : a.startTime != null;

            String? timeStr;
            if (finished && a.finishTime != null) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.finishTime!.difference(start));
            } else if (hasStarted && laps > 0 && a.splits.isNotEmpty) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.splits.last.difference(start));
            }

            final String lapInfo;
            if (finished) {
              lapInfo = timeStr ?? 'Финиш';
            } else if (!hasStarted) {
              lapInfo = 'Ожидает';
            } else if (laps > 0) {
              lapInfo = 'Круг $laps/${session.totalLaps}${timeStr != null ? '\n⏱$timeStr' : ''}';
            } else {
              lapInfo = 'На трассе';
            }

            final BibState state;
            if (finished) {
              state = BibState.finished;
            } else if (!hasStarted) {
              state = BibState.disabled;
            } else if (laps > 0) {
              state = BibState.current;
            } else {
              state = BibState.available;
            }

            return AppBibTile(
              bib: a.bib,
              name: a.name.isNotEmpty ? a.name : null,
              lapInfo: lapInfo,
              state: state,
              onTap: () {
                if (finished || !hasStarted) return;
                _recordSplit(a.id);
              },
            );
          }).toList(),
        ),
      ),

      // ── Кнопка Масс-Старт (AppButton) ──
      if (isMass && !isRunning)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.danger(
              text: 'СТАРТ',
              icon: Icons.play_arrow,
              onPressed: _startMass,
            ),
          ),
        ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 3: ТАБЛИЦА — AppResultTable
  // ═══════════════════════════════════════
  Widget _buildTableTab(QuickSession session, ColorScheme cs) {
    final table = _buildResultTable(session);

    if (table.rows.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Результаты появятся после старта', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return Column(children: [
      // ── Toolbar: статистика + переключатель ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1))),
        ),
        child: Row(children: [
          AppStatCard(value: '${session.finishedCount}', label: 'Финиш', color: cs.primary, expanded: false),
          const SizedBox(width: 6),
          AppStatCard(value: '${session.athletes.length - session.finishedCount}', label: 'На трассе', color: cs.tertiary, expanded: false),
          const Spacer(),
          // Переключатель вид
          GestureDetector(
            onTap: () => setState(() => _showCards = !_showCards),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showCards ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _showCards ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Icon(
                _showCards ? Icons.view_agenda_outlined : Icons.table_rows_outlined,
                size: 16,
                color: _showCards ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ]),
      ),

      // ── AppResultTable ──
      Expanded(
        child: AppResultTable(
          table: table,
          showCards: _showCards,
          onRowTap: (row) => _showAthleteDetailFromRow(session, row, cs),
        ),
      ),
    ]);
  }

  /// Построить [ResultTable] из [QuickSession] для [AppResultTable].
  ResultTable _buildResultTable(QuickSession session) {
    // Сортировка: больше кругов → меньше времени
    final athletes = [...session.athletes];
    athletes.sort((a, b) {
      final lapsCompare = b.completedLaps.compareTo(a.completedLaps);
      if (lapsCompare != 0) return lapsCompare;
      if (a.splits.isNotEmpty && b.splits.isNotEmpty) {
        final aTime = a.splits.last.difference(session.effectiveStart(a));
        final bTime = b.splits.last.difference(session.effectiveStart(b));
        return aTime.compareTo(bTime);
      }
      return 0;
    });

    // Лидер
    final leaderLapDurations = athletes.isNotEmpty
        ? athletes.first.lapDurations(session.effectiveStart(athletes.first))
        : <Duration>[];
    Duration? leaderTotalTime;
    if (athletes.isNotEmpty && athletes.first.splits.isNotEmpty) {
      leaderTotalTime = athletes.first.splits.last.difference(session.effectiveStart(athletes.first));
    }

    // Колонки
    final columns = <ColumnDef>[
      const ColumnDef(id: 'place', label: '#', type: ColumnType.number, align: ColumnAlign.center, flex: 0.4, minWidth: 36),
      const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.text, align: ColumnAlign.center, flex: 0.5, minWidth: 40),
      const ColumnDef(id: 'name', label: 'Имя', type: ColumnType.text, flex: 1.5, minWidth: 80),
      // Лап-колонки
      for (var lap = 1; lap <= session.totalLaps; lap++)
        ColumnDef(id: 'lap${lap}_time', label: 'L$lap', type: ColumnType.time, align: ColumnAlign.right, flex: 0.8, minWidth: 60),
      const ColumnDef(id: 'result_time', label: 'Время', type: ColumnType.time, align: ColumnAlign.right, flex: 1.0, minWidth: 70),
      const ColumnDef(id: 'gap_leader', label: 'Δ', type: ColumnType.gap, align: ColumnAlign.right, flex: 0.7, minWidth: 55),
    ];

    // Строки
    final rows = <ResultRow>[];
    for (var i = 0; i < athletes.length; i++) {
      final a = athletes[i];
      final finished = a.isFinished(session.totalLaps);
      final hasStarted = a.startTime != null || session.mode == QuickStartMode.mass;
      final laps = a.completedLaps;
      final place = i + 1;
      final lapDurations = a.lapDurations(session.effectiveStart(a));
      final displayName = a.name.isNotEmpty ? a.name : 'BIB ${a.bib}';

      // Общее время
      Duration? athleteTime;
      if (a.splits.isNotEmpty) {
        athleteTime = a.splits.last.difference(session.effectiveStart(a));
      }

      // RowType
      final RowType rowType;
      if (finished) {
        rowType = RowType.finished;
      } else if (!hasStarted) {
        rowType = RowType.waiting;
      } else {
        rowType = RowType.onTrack;
      }

      // Cells
      final cells = <String, CellValue>{};

      // Place
      if (finished) {
        cells['place'] = CellValue(raw: place, display: '$place', style: place <= 3 ? CellStyle.highlight : CellStyle.normal);
      } else if (hasStarted) {
        final statusLabel = laps > 0 ? 'К$laps' : 'LIVE';
        cells['place'] = CellValue(display: statusLabel, style: CellStyle.highlight);
      } else {
        cells['place'] = const CellValue(display: '—', style: CellStyle.muted);
      }

      // BIB
      cells['bib'] = CellValue(raw: a.bib, display: a.bib);

      // Name
      cells['name'] = CellValue(raw: displayName, display: displayName,
        style: finished ? CellStyle.bold : hasStarted ? CellStyle.normal : CellStyle.muted);

      // Lap times
      for (var lap = 1; lap <= session.totalLaps; lap++) {
        final lapIdx = lap - 1;
        if (lapIdx < lapDurations.length) {
          final lapTime = lapDurations[lapIdx];
          // Лучший круг?
          var lapStyle = CellStyle.normal;
          if (i == 0 && finished) lapStyle = CellStyle.highlight;
          // Per-lap gap
          String lapDisplay = TimeFormatter.compact(lapTime);
          if (i > 0 && lapIdx < leaderLapDurations.length) {
            final diff = lapTime - leaderLapDurations[lapIdx];
            if (diff.inMilliseconds > 0) {
              lapDisplay = TimeFormatter.compact(lapTime);
              lapStyle = CellStyle.normal;
            }
          }
          cells['lap${lap}_time'] = CellValue(raw: lapTime, display: lapDisplay, style: lapStyle);
        } else {
          cells['lap${lap}_time'] = CellValue.na;
        }
      }

      // Result time
      if (athleteTime != null) {
        cells['result_time'] = CellValue(
          raw: athleteTime,
          display: TimeFormatter.compact(athleteTime),
          style: finished ? CellStyle.bold : CellStyle.normal,
        );
      } else {
        cells['result_time'] = CellValue.empty;
      }

      // Gap
      if (leaderTotalTime != null && athleteTime != null && i > 0) {
        final gap = athleteTime - leaderTotalTime;
        if (gap.inMilliseconds > 0) {
          cells['gap_leader'] = CellValue(raw: gap, display: '+${TimeFormatter.compact(gap)}', style: CellStyle.error);
        } else {
          cells['gap_leader'] = CellValue.na;
        }
      } else {
        cells['gap_leader'] = CellValue.na;
      }

      rows.add(ResultRow(entryId: a.id, cells: cells, type: rowType));
    }

    return ResultTable(columns: columns, rows: rows);
  }

  // ── Модальное окно по тапу на строку таблицы ──
  void _showAthleteDetailFromRow(QuickSession session, ResultRow row, ColorScheme cs) {
    final a = session.athletes.firstWhere((x) => x.id == row.entryId, orElse: () => session.athletes.first);
    // Вычислить позицию
    final sorted = [...session.athletes]..sort((x, y) {
      final lc = y.completedLaps.compareTo(x.completedLaps);
      if (lc != 0) return lc;
      if (x.splits.isNotEmpty && y.splits.isNotEmpty) {
        return x.splits.last.difference(session.effectiveStart(x)).compareTo(y.splits.last.difference(session.effectiveStart(y)));
      }
      return 0;
    });
    final place = sorted.indexOf(a) + 1;
    _showAthleteDetail(session, a, place, cs);
  }

  void _showAthleteDetail(QuickSession session, QuickAthlete a, int place, ColorScheme cs) {
    final finished = a.isFinished(session.totalLaps);
    final hasStarted = a.startTime != null || session.mode == QuickStartMode.mass;
    final displayName = a.name.isNotEmpty ? a.name : 'BIB ${a.bib}';
    final lapDurations = a.lapDurations(session.effectiveStart(a));

    String totalTime = '—';
    if (a.splits.isNotEmpty) {
      totalTime = TimeFormatter.compact(a.splits.last.difference(session.effectiveStart(a)));
    }

    AppBottomSheet.show(
      context,
      title: '$displayName (BIB ${a.bib})',
      initialHeight: 0.55,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Шапка: позиция + статус + время ──
        Row(children: [
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Text('#$place', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: cs.primary)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              finished ? 'Финишировал' : !hasStarted ? 'Ожидает старта' : 'На трассе',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: finished ? cs.primary : cs.tertiary),
            ),
            Text('Круг ${a.completedLaps}/${session.totalLaps}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const Spacer(),
          Text(totalTime, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: finished ? cs.primary : cs.onSurface)),
        ]),
        const SizedBox(height: 16),

        // ── Детализация по кругам ──
        if (lapDurations.isNotEmpty) ...[
          Text('КРУГИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...lapDurations.asMap().entries.map((e) {
            final lapIdx = e.key;
            final lapTime = e.value;
            final isLast = lapIdx == lapDurations.length - 1 && finished;

            Duration cumulative = Duration.zero;
            for (var j = 0; j <= lapIdx; j++) {
              cumulative += lapDurations[j];
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppQueueItem(
                leading: Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isLast ? cs.primary.withValues(alpha: 0.1) : cs.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('L${lapIdx + 1}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isLast ? cs.primary : cs.onSurfaceVariant)),
                ),
                title: Text(
                  TimeFormatter.compact(lapTime),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: cs.onSurface),
                ),
                subtitle: Text('Общее: ${TimeFormatter.compact(cumulative)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                trailing: isLast ? Icon(Icons.flag, size: 18, color: cs.primary) : null,
              ),
            );
          }),
        ] else if (hasStarted)
          AppInfoBanner.info(title: 'На трассе', subtitle: 'Ожидаем первую отсечку')
        else
          AppInfoBanner.warning(title: 'Ожидает старта'),
      ]),
    );
  }

  Widget _buildMassTimer(ColorScheme cs, bool isRunning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Column(children: [
        if (isRunning) ...[
          Text(
            TimeFormatter.full(_elapsed),
            style: TextStyle(
              fontSize: 42,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: cs.error,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.error)),
          ]),
        ] else
          Text(
            '00:00.0',
            style: TextStyle(
              fontSize: 42,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              letterSpacing: 2,
            ),
          ),
      ]),
    );
  }
}

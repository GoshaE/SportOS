import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';

/// QT2 — Live хронометраж быстрой сессии.
///
/// Масс-старт: 2 закладки (Финиш + Таблица)
/// Интервальный / Ручной: 3 закладки (Старт + Финиш + Таблица)
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

  /// Авто-старт: если время пришло → отметить атлета как стартовавшего.
  void _autoStartCheck(QuickSession session) {
    if (session.globalStartTime == null) return;
    final now = DateTime.now();
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    for (final a in sorted) {
      if (a.startTime != null) continue; // уже стартовал
      final planned = session.plannedStartTime(a);
      if (planned == null) continue;
      if (now.isAfter(planned) || now.isAtSameMomentAs(planned)) {
        // Авто-запуск — используем плановое время, а не текущее
        ref.read(quickSessionProvider.notifier).startIndividualAt(a.id, planned);
      } else {
        break; // следующие ещё не пришло время
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

  /// Запуск первого спортсмена (интервальный) или конкретного (ручной).
  void _startIndividual(String athleteId) {
    HapticFeedback.mediumImpact();
    ref.read(quickSessionProvider.notifier).startIndividual(athleteId);
  }

  void _recordSplit(String athleteId) {
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).recordSplit(athleteId);
    final session = ref.read(quickSessionProvider);
    if (session != null && session.allFinished) {
      _finishAndGoResults();
    }
  }

  void _finishAndGoResults() {
    ref.read(quickSessionProvider.notifier).finishSession();
    ref.read(quickSessionProvider.notifier).saveToHistory();
    ref.read(quickHistoryProvider.notifier).refresh();
    context.pushReplacement('/quick-timer/results');
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(quickSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Секундомер')),
        body: const Center(child: Text('Нет активной сессии.')),
      );
    }

    final mode = session.mode;
    final isRunning = session.status == QuickSessionStatus.running;
    final finishedCount = session.finishedCount;
    final totalCount = session.athletes.length;
    final hasTabs3 = mode != QuickStartMode.mass;

    // Tab labels
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
              Text('$finishedCount/$totalCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
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
                if (confirm == true) _finishAndGoResults();
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
      // ── Не начали: подсказка ──
      if (!isRunning) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            borderColor: cs.primary.withValues(alpha: 0.15),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInterval ? 'Интервальный старт' : 'Ручной старт',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isInterval
                          ? 'Нажмите кнопку «Старт» — первый спортсмен уйдёт немедленно. '
                            'Далее остальные стартуют автоматически каждые ${session.intervalSeconds} сек. '
                            'Вам нужно только контролировать процесс.'
                          : 'Нажимайте на каждого спортсмена, когда он готов к старту. '
                            'Время записывается в момент нажатия.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                )),
              ]),
            ],
          ),
        ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person, color: cs.tertiary, size: 22),
                  const SizedBox(width: 8),
                  Text('Первый: ${current.bib} — ${current.name}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.tertiary)),
                ]),
                if (isInterval) ...[
                  const SizedBox(height: 4),
                  Text('Интервал: ${session.intervalSeconds} сек', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
      ],

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Text('СЛЕДУЮЩИЙ:', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const Spacer(),
                  Text('${current.bib} — ${current.name}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary)),
                ]),
              ),
            ],
          ),
        ),

      // ── Все стартовали ──
      if (current == null && startedCount == totalCount && isRunning)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: cs.primary, size: 28),
                const SizedBox(width: 8),
                Text('Все стартовали!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
              ]),
              const SizedBox(height: 8),
              Text('Переключитесь на вкладку «Финиш»', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),

      // ── Инфо ──
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('СТАРТ-ЛИСТ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
          Text('$startedCount/$totalCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
        ]),
      ),

      // ── Очередь ──
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
          itemCount: sorted.length,
          separatorBuilder: (_, a) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final a = sorted[i];
            final hasStarted = a.startTime != null;
            final isCurrent = current?.id == a.id;

            final color = hasStarted ? cs.primary : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
            final icon = hasStarted ? Icons.check_circle : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
            final statusText = hasStarted ? 'Ушёл' : isCurrent ? 'Текущий' : 'Ожидает';

            return AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: isCurrent
                  ? cs.tertiaryContainer.withValues(alpha: 0.1)
                  : hasStarted
                      ? cs.primaryContainer.withValues(alpha: 0.05)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              borderColor: isCurrent ? cs.tertiary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.1),
              children: [
                InkWell(
                  // Ручной режим: тап по ожидающему → старт
                  onTap: !isInterval && !hasStarted
                      ? () => _startIndividual(a.id)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6)),
                        child: Text(a.bib, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: cs.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.name, style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(statusText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      // Ручной режим: стрелка для тапа
                      if (!isInterval && !hasStarted)
                        Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // ── Кнопка СТАРТ (интервальный: только первый; ручной: нет) ──
      if (!isRunning && current != null && isInterval)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: cs.errorContainer.withValues(alpha: 0.1),
              borderColor: cs.error.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _startIndividual(current.id),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      alignment: Alignment.center,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_arrow, size: 32, color: cs.error),
                        const SizedBox(height: 4),
                        Text('СТАРТ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.error, letterSpacing: 2)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

      // ── Ручной режим: подсказка ──
      if (!isRunning && !isInterval)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.touch_app, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text('Нажмите на спортсмена для старта', style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
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

      // ── Сетка атлетов ──
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

            // Elapsed time
            String? timeStr;
            if (finished && a.finishTime != null) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.finishTime!.difference(start));
            } else if (hasStarted && laps > 0 && a.splits.isNotEmpty) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.splits.last.difference(start));
            }

            // Lap info
            final String lapInfo;
            if (finished) {
              lapInfo = timeStr ?? 'Финиш';
            } else if (!hasStarted) {
              lapInfo = 'Ожидает старта';
            } else if (laps > 0) {
              lapInfo = 'Круг $laps/${session.totalLaps}${timeStr != null ? '\n⏱$timeStr' : ''}';
            } else {
              lapInfo = 'На трассе';
            }

            // BibState
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
              name: a.name,
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

      // ── Кнопка Масс-Старт ──
      if (isMass && !isRunning)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: cs.errorContainer.withValues(alpha: 0.1),
              borderColor: cs.error.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _startMass,
                    splashColor: cs.error.withValues(alpha: 0.2),
                    highlightColor: cs.error.withValues(alpha: 0.1),
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      alignment: Alignment.center,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_arrow, size: 40, color: cs.error),
                        const SizedBox(height: 4),
                        Text('СТАРТ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cs.error, letterSpacing: 3)),
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
  // Tab 3: ТАБЛИЦА (live-результаты)
  // ═══════════════════════════════════════
  Widget _buildTableTab(QuickSession session, ColorScheme cs) {
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

    // Лидер для расчёта отставаний
    Duration? leaderTime;
    if (athletes.isNotEmpty && athletes.first.splits.isNotEmpty) {
      leaderTime = athletes.first.splits.last.difference(session.effectiveStart(athletes.first));
    }

    if (athletes.every((a) => a.splits.isEmpty)) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Результаты появятся после первых отсечек', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: athletes.length,
      separatorBuilder: (_, a) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final a = athletes[i];
        final laps = a.completedLaps;
        final finished = a.isFinished(session.totalLaps);
        final hasTime = a.splits.isNotEmpty;
        final place = i + 1;

        String timeStr = '—';
        Duration? athleteTime;
        if (hasTime) {
          athleteTime = a.splits.last.difference(session.effectiveStart(a));
          timeStr = TimeFormatter.compact(athleteTime);
        }

        String gapStr = '';
        if (leaderTime != null && athleteTime != null && i > 0) {
          final gap = athleteTime - leaderTime;
          if (gap.inMilliseconds > 0) {
            gapStr = '+${TimeFormatter.compact(gap)}';
          }
        }

        final Color? medalColor = place == 1
            ? const Color(0xFFFFD700)
            : place == 2
                ? const Color(0xFFC0C0C0)
                : place == 3
                    ? const Color(0xFFCD7F32)
                    : null;

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: finished
              ? cs.primaryContainer.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          borderColor: medalColor?.withValues(alpha: 0.4) ?? cs.outlineVariant.withValues(alpha: 0.1),
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medalColor?.withValues(alpha: 0.15) ?? cs.surface.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: medalColor?.withValues(alpha: 0.5) ?? cs.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Text('$place', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: medalColor ?? cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                child: Text(a.bib, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: cs.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text(
                    finished ? 'Финиш' : laps > 0 ? 'Круг $laps/${session.totalLaps}' : 'На трассе',
                    style: TextStyle(fontSize: 11, color: finished ? cs.primary : cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              if (gapStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(gapStr, style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                ),
              Text(timeStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: finished ? cs.primary : cs.onSurface)),
            ]),
            if (a.splits.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  children: a.lapDurations(session.effectiveStart(a)).asMap().entries.map((e) {
                    return Text(
                      'L${e.key + 1}: ${TimeFormatter.compact(e.value)}',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontFamily: 'monospace'),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
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

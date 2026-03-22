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
/// 3 закладки:
/// - Старт (разделка): обратный отсчёт + очередь
/// - Финиш: сетка AppBibTile для записи сплитов
/// - Таблица: live-результаты с отставаниями
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
    final isMass = session?.mode == QuickStartMode.mass;
    _tabCtrl = TabController(length: isMass ? 2 : 3, vsync: this);
    // Масс-старт начинает на Финише (index 0), разделка на Старте (index 0)

    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final s = ref.read(quickSessionProvider);
      if (s == null || s.status != QuickSessionStatus.running || !mounted) return;
      final start = s.globalStartTime;
      if (start != null) {
        setState(() => _elapsed = DateTime.now().difference(start));
      }
    });
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

    final isMass = session.mode == QuickStartMode.mass;
    final isRunning = session.status == QuickSessionStatus.running;
    final finishedCount = session.finishedCount;
    final totalCount = session.athletes.length;

    // Tab labels
    final tabs = isMass
        ? const [Tab(text: 'Финиш'), Tab(text: 'Таблица')]
        : const [Tab(text: 'Старт'), Tab(text: 'Финиш'), Tab(text: 'Таблица')];

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
        children: isMass
            ? [
                _buildFinishTab(session, cs, isRunning),
                _buildTableTab(session, cs),
              ]
            : [
                _buildStartTab(session, cs, isRunning),
                _buildFinishTab(session, cs, isRunning),
                _buildTableTab(session, cs),
              ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Tab 1: СТАРТ (разделка)
  // ═══════════════════════════════════════
  Widget _buildStartTab(QuickSession session, ColorScheme cs, bool isRunning) {
    final current = session.currentStarter;
    final startedCount = session.startedCount;
    final totalCount = session.athletes.length;
    final sorted = [...session.athletes]..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    // Обратный отсчёт
    Duration? countdown;
    if (current != null && session.globalStartTime != null) {
      final planned = session.plannedStartTime(current);
      if (planned != null) {
        countdown = planned.difference(DateTime.now());
      }
    }
    final isUrgent = countdown != null && countdown.inSeconds <= 5 && countdown.inSeconds >= 0;
    final isOverdue = countdown != null && countdown.isNegative;

    return Column(children: [
      // ── Обратный отсчёт (если гонка идёт) ──
      if (isRunning && current != null && countdown != null)
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
                  Text('${current.bib} — ${current.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary)),
                ]),
              ),
            ],
          ),
        ),

      // ── Ещё не начали ──
      if (!isRunning && current != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person, color: cs.tertiary, size: 24),
                const SizedBox(width: 8),
                Text('Первый на старте: ${current.bib} — ${current.name}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.tertiary)),
              ]),
              const SizedBox(height: 4),
              Text('Интервал: ${session.intervalSeconds} сек', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),

      // ── Все стартовали ──
      if (current == null && startedCount == totalCount)
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
                Padding(
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
                  ]),
                ),
              ],
            );
          },
        ),
      ),

      // ── Кнопка УШЁЛ ──
      if (current != null)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: AppButton.primary(
                text: 'УШЁЛ ✅  (${current.bib})',
                onPressed: () => _startIndividual(current.id),
              ),
            ),
          ),
        ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 2: ФИНИШ (масс + разделка)
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
              final start = isMass ? session.globalStartTime! : a.startTime!;
              timeStr = TimeFormatter.compact(a.finishTime!.difference(start));
            } else if (hasStarted && laps > 0 && a.splits.isNotEmpty) {
              final start = isMass ? session.globalStartTime! : a.startTime!;
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
              lapInfo = isMass ? 'На трассе' : 'Стартовал';
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
                if (finished) return;
                if (!hasStarted) return; // нельзя записать сплит без старта
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
      // По кругам desc
      final lapsCompare = b.completedLaps.compareTo(a.completedLaps);
      if (lapsCompare != 0) return lapsCompare;
      // По времени последнего сплита asc
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

        // Позиция
        final place = i + 1;

        // Время
        String timeStr = '—';
        Duration? athleteTime;
        if (hasTime) {
          athleteTime = a.splits.last.difference(session.effectiveStart(a));
          timeStr = TimeFormatter.compact(athleteTime);
        }

        // Отставание
        String gapStr = '';
        if (leaderTime != null && athleteTime != null && i > 0) {
          final gap = athleteTime - leaderTime;
          if (gap.inMilliseconds > 0) {
            gapStr = '+${TimeFormatter.compact(gap)}';
          }
        }

        // Медаль
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
              // Place
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
              // BIB
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                child: Text(a.bib, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: cs.primary)),
              ),
              const SizedBox(width: 10),
              // Name + laps
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text(
                    finished ? 'Финиш' : laps > 0 ? 'Круг $laps/${session.totalLaps}' : 'На трассе',
                    style: TextStyle(fontSize: 11, color: finished ? cs.primary : cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              // Gap
              if (gapStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(gapStr, style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                ),
              // Time
              Text(timeStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: finished ? cs.primary : cs.onSurface)),
            ]),
            // ── Splits row ──
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

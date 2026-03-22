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
class QuickTimerScreen extends ConsumerStatefulWidget {
  const QuickTimerScreen({super.key});

  @override
  ConsumerState<QuickTimerScreen> createState() => _QuickTimerScreenState();
}

class _QuickTimerScreenState extends ConsumerState<QuickTimerScreen> {
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final session = ref.read(quickSessionProvider);
      if (session == null || session.status != QuickSessionStatus.running) return;
      final start = session.globalStartTime;
      if (start != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(start));
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Секундомер'),
        actions: [
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
      ),
      body: Column(children: [
        // ── Таймер ──
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
                  // Масс: записать сплит
                  if (isMass && isRunning) {
                    _recordSplit(a.id);
                    return;
                  }
                  // Разделка: сначала старт, потом сплит
                  if (!isMass) {
                    if (a.startTime == null) {
                      _startIndividual(a.id);
                    } else {
                      _recordSplit(a.id);
                    }
                  }
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

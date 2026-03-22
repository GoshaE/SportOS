import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_models.dart';
import '../../../domain/timing/time_formatter.dart';
import '../../../domain/quick_timer/quick_timer_providers.dart';

class QtFinishTab extends ConsumerWidget {
  final QuickSession session;
  final bool isRunning;
  final Duration elapsed;

  const QtFinishTab({
    super.key,
    required this.session,
    required this.isRunning,
    required this.elapsed,
  });

  void _recordSplit(BuildContext context, WidgetRef ref, String athleteId) {
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).recordSplit(athleteId);
    
    // После отсечки получаем обновленную сессию
    final updatedSession = ref.read(quickSessionProvider);
    if (updatedSession == null) return;

    final athlete = updatedSession.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';

    if (updatedSession.allFinished) {
      ref.read(quickSessionProvider.notifier).finishSession();
      ref.read(quickSessionProvider.notifier).saveToHistory();
      ref.read(quickHistoryProvider.notifier).refresh();
      if (context.mounted) {
        AppSnackBar.success(context, 'Все финишировали! Результаты сохранены.');
        // Переключение табов делегировано экрану, мы просто показываем снек. 
        // Экран (QuickTimerScreen) слушает состояние allFinished.
      }
    } else if (context.mounted) {
      AppSnackBar.withUndo(
        context,
        '⏱ Отсечка: $displayName',
        onUndo: () {
          ref.read(quickSessionProvider.notifier).undoLastSplit(athleteId);
          HapticFeedback.mediumImpact();
        },
      );
    }
  }

  void _undoSplitWithConfirm(BuildContext context, WidgetRef ref, String athleteId) async {
    final athlete = session.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';
    final laps = athlete.completedLaps;

    final confirm = await AppDialog.confirm(
      context,
      title: 'Отменить отсечку?',
      message: '$displayName — круг $laps/${session.totalLaps}\nПоследняя отсечка будет удалена.',
    );
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      ref.read(quickSessionProvider.notifier).undoLastSplit(athleteId);
      if (context.mounted) AppSnackBar.info(context, 'Отсечка $displayName отменена');
    }
  }

  int _athleteStatusPriority(QuickAthlete a, bool isMass) {
    final finished = a.isFinished(session.totalLaps);
    final hasStarted = isMass ? isRunning : a.startTime != null;
    
    if (finished) return 3; // Самый низкий приоритет (внизу)
    if (!hasStarted) return 2; // Средний приоритет
    return 1; // Самый высокий (На трассе)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isMass = session.mode == QuickStartMode.mass;

    if (session.athletes.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_off_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Добавьте участников на вкладке «Старт»', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    // Умная сортировка: На трассе -> Ожидают -> Финишировали
    final sortedAthletes = [...session.athletes]..sort((a, b) {
      final pA = _athleteStatusPriority(a, isMass);
      final pB = _athleteStatusPriority(b, isMass);
      if (pA != pB) return pA.compareTo(pB);
      return a.startOrder.compareTo(b.startOrder); // Внутри группы по стартовому номеру
    });

    return Column(children: [
      if (isMass) _buildMassTimer(cs),
      Expanded(
        child: GridView.extent(
          maxCrossAxisExtent: 140,
          childAspectRatio: 0.85,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: sortedAthletes.map((a) {
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

            // Имя крупно, BIB мелко (тренеры знают всех в лицо)
            String displayName;
            if (a.name.isNotEmpty) {
              final parts = a.name.trim().split(RegExp(r'\s+'));
              displayName = parts.join('\n');
            } else {
              displayName = a.bib;
            }

            return AppBibTile(
              bib: displayName,
              name: a.name.isNotEmpty ? '#${a.bib}' : null,
              lapInfo: lapInfo,
              state: state,
              onTap: () {
                if (finished || !hasStarted) return;
                _recordSplit(context, ref, a.id);
              },
              onLongPress: (finished || laps > 0)
                  ? () => _undoSplitWithConfirm(context, ref, a.id)
                  : null,
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildMassTimer(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Column(children: [
        if (isRunning) ...[
          Text(TimeFormatter.full(elapsed),
            style: TextStyle(fontSize: 42, fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w900, color: cs.error, letterSpacing: 2)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.error)),
          ]),
        ] else
          Text('00:00.0', style: TextStyle(fontSize: 42, fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w900, color: cs.onSurfaceVariant.withValues(alpha: 0.3), letterSpacing: 2)),
      ]),
    );
  }
}

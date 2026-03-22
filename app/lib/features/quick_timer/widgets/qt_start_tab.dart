import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_models.dart';
import '../../../domain/quick_timer/quick_timer_providers.dart';
import 'qt_add_athlete_sheet.dart';

class QtStartTab extends ConsumerWidget {
  final QuickSession session;
  final bool isRunning;
  final bool isFinished;

  const QtStartTab({
    super.key,
    required this.session,
    required this.isRunning,
    required this.isFinished,
  });

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

  void _startMass(BuildContext context, WidgetRef ref) {
    if (session.athletes.isEmpty) {
      AppSnackBar.info(context, 'Добавьте участников');
      return;
    }
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).startMass();
  }

  void _startIndividual(WidgetRef ref, String athleteId) {
    HapticFeedback.mediumImpact();
    ref.read(quickSessionProvider.notifier).startIndividual(athleteId);
  }

  void _removeAthleteWithConfirm(BuildContext context, WidgetRef ref, String athleteId) async {
    final athlete = session.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';

    final confirm = await AppDialog.confirm(
      context,
      title: 'Удалить участника?',
      message: '$displayName будет удалён из сессии.',
    );
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      ref.read(quickSessionProvider.notifier).removeAthlete(athleteId);
      if (context.mounted) AppSnackBar.info(context, '$displayName удалён');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isMass = session.mode == QuickStartMode.mass;
    final isInterval = session.mode == QuickStartMode.interval;
    final current = session.currentStarter;
    final startedCount = session.startedCount;
    final totalCount = session.athletes.length;
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    // Обратный отсчёт
    Duration? countdown;
    if (isInterval && current != null && session.globalStartTime != null) {
      final planned = session.plannedStartTime(current);
      if (planned != null) countdown = planned.difference(DateTime.now());
    }
    final isUrgent = countdown != null && countdown.inSeconds <= 5 && countdown.inSeconds >= 0;
    final isOverdue = countdown != null && countdown.isNegative;

    return Column(children: [
      // ── Подсказка до старта ──
      if (totalCount > 0 && !isRunning && !isFinished)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.info(
            title: isMass ? 'Масс-старт' : isInterval ? 'Интервальный старт' : 'Ручной старт',
            subtitle: isMass
                ? 'Все стартуют одновременно. Нажмите кнопку СТАРТ.'
                : isInterval
                    ? 'Нажмите «Старт» — первый спортсмен уйдёт. Далее автоматически каждые ${session.intervalSeconds} сек.'
                    : 'Нажимайте на спортсмена, когда он готов к старту.',
          ),
        ),

      // ── Карточка интервала (Сделали более компактной по фидбеку) ──
      if (isInterval && isRunning && current != null && countdown != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOverdue ? cs.error.withValues(alpha: 0.15) : isUrgent ? cs.errorContainer.withValues(alpha: 0.15) : cs.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOverdue ? cs.error.withValues(alpha: 0.4) : isUrgent ? cs.error.withValues(alpha: 0.3) : cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isOverdue ? 'ОПОЗДАНИЕ!' : isUrgent ? 'ВНИМАНИЕ' : 'ДО СТАРТА', style: TextStyle(fontSize: 10, color: isOverdue || isUrgent ? cs.error : cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      Text('${current.bib} — ${current.name.isNotEmpty ? current.name : "..."}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(_fmtCountdown(countdown), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], color: isOverdue || isUrgent ? cs.error : cs.primary)),
              ],
            ),
          ),
        ),

      // ── Все стартовали ──
      if (totalCount > 0 && current == null && startedCount == totalCount && isRunning)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.success(title: 'Все стартовали!', subtitle: 'Переключитесь на «Финиш».'),
        ),

      // ── Заголовок ──
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('СТАРТ-ЛИСТ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
          if (totalCount > 0) Text('$startedCount/$totalCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
        ]),
      ),

      // ── Список участников ──
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: totalCount == 0 ? 1 : sorted.length,
          itemBuilder: (context, i) {
            if (totalCount == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: AppInfoBanner.info(
                  title: 'Добавьте участников',
                  subtitle: 'Нажмите иконку 👤+ в верхнем меню.',
                ),
              );
            }

            final a = sorted[i];
            final hasStarted = isMass ? (isRunning || isFinished) : a.startTime != null;
            final isCurrent = !isMass && current?.id == a.id;
            final finished = a.isFinished(session.totalLaps);

            final color = finished ? cs.primary : hasStarted ? cs.tertiary : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
            final icon = finished ? Icons.flag : hasStarted ? Icons.check_circle : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
            final statusText = finished ? 'Финиш' : hasStarted ? 'На трассе' : isCurrent ? 'Текущий' : 'Ожидает';

            return AppQueueItem(
              leading: Icon(icon, color: color, size: 24),
              title: Text('${a.bib} — ${a.name.isNotEmpty ? a.name : "BIB ${a.bib}"}', style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: cs.onSurface)),
              subtitle: Text('#${i + 1} · $statusText', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              trailing: !isMass && !isInterval && !hasStarted && !isFinished ? Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)) : null,
              backgroundColor: isCurrent ? cs.tertiaryContainer.withValues(alpha: 0.1) : finished ? cs.primaryContainer.withValues(alpha: 0.05) : hasStarted ? cs.tertiaryContainer.withValues(alpha: 0.05) : null,
              onTap: !isMass && !isInterval && !hasStarted && !finished && !isFinished ? () => _startIndividual(ref, a.id) : null,
              onLongPress: !hasStarted && !finished && !isFinished ? () => _removeAthleteWithConfirm(context, ref, a.id) : null,
            );
          },
        ),
      ),

      // ── Кнопка СТАРТ ──
      if (totalCount > 0 && !isRunning && !isFinished) ...[
        if (isMass)
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: AppButton.danger(text: 'СТАРТ', icon: Icons.play_arrow, onPressed: () => _startMass(context, ref)))),
        if (isInterval && current != null)
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: AppButton.danger(text: 'СТАРТ', icon: Icons.play_arrow, onPressed: () => _startIndividual(ref, current.id)))),
        if (!isMass && !isInterval)
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: AppInfoBanner.info(title: 'Нажмите на спортсмена для старта'))),
      ],
      
      // ── Добавить первого (если пусто) ──
      if (totalCount == 0 && !isFinished)
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: AppButton.primary(text: '+ Добавить участника', icon: Icons.person_add, onPressed: () => showQtAddAthleteSheet(context, ref)))),
    ]);
  }
}

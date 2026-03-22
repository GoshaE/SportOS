import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_models.dart';
import '../../../domain/quick_timer/quick_timer_providers.dart';
import '../../../domain/quick_timer/quick_result_calculator.dart';
import '../../../domain/timing/result_table.dart';
import '../../../domain/timing/time_formatter.dart';

class QtTableTab extends ConsumerStatefulWidget {
  final QuickSession session;

  const QtTableTab({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<QtTableTab> createState() => _QtTableTabState();
}

class _QtTableTabState extends ConsumerState<QtTableTab> {
  bool _showCards = false;

  void _showAthleteDetail(BuildContext context, QuickSession session, ResultRow row, ColorScheme cs) {
    final a = session.athletes.firstWhere(
      (x) => x.id == row.entryId, 
      orElse: () => session.athletes.first,
    );
    
    // Сортировка аналогично калькулятору, чтобы найти место (place)
    final sorted = [...session.athletes]..sort((x, y) {
      final lc = y.completedLaps.compareTo(x.completedLaps);
      if (lc != 0) return lc;
      if (x.splits.isNotEmpty && y.splits.isNotEmpty) {
        return x.splits.last.difference(session.effectiveStart(x)).compareTo(y.splits.last.difference(session.effectiveStart(y)));
      }
      return 0;
    });
    
    final place = sorted.indexOf(a) + 1;
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
        Row(children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: cs.primary.withValues(alpha: 0.3))),
            child: Text('#$place', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: cs.primary)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(finished ? 'Финишировал' : !hasStarted ? 'Ожидает старта' : 'На трассе',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: finished ? cs.primary : cs.tertiary)),
            Text('Круг ${a.completedLaps}/${session.totalLaps}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const Spacer(),
          Text(totalTime, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()], color: finished ? cs.primary : cs.onSurface)),
        ]),
        const SizedBox(height: 16),
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
                  width: 28, height: 28, alignment: Alignment.center,
                  decoration: BoxDecoration(color: isLast ? cs.primary.withValues(alpha: 0.1) : cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: Text('L${lapIdx + 1}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isLast ? cs.primary : cs.onSurfaceVariant)),
                ),
                title: Text(TimeFormatter.compact(lapTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], color: cs.onSurface)),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // ДЕЛЕГИРУЕМ логику доменному калькулятору
    final displaySettings = ref.watch(qtDisplaySettingsProvider);
    final table = QuickResultCalculator.buildTable(widget.session, displaySettings);

    if (table.rows.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Результаты появятся после старта', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    final finished = widget.session.finishedCount;
    final total = widget.session.athletes.length;
    final started = widget.session.startedCount;
    final onTrack = started - finished;
    final waiting = total - started;

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1))),
        ),
        child: Row(children: [
          AppStatCard(value: '$finished', label: 'Финиш', color: cs.primary, expanded: false),
          const SizedBox(width: 6),
          AppStatCard(value: '$onTrack', label: 'На трассе', color: cs.tertiary, expanded: false),
          const SizedBox(width: 6),
          AppStatCard(value: '$waiting', label: 'Ожидают', color: cs.onSurfaceVariant, expanded: false),
          const Spacer(),
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
      Expanded(
        child: AppResultTable(
          table: table,
          showCards: _showCards,
          onRowTap: (row) => _showAthleteDetail(context, widget.session, row, cs),
        ),
      ),
      if (widget.session.status == QuickSessionStatus.finished)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.primary(
              text: 'Новый забег',
              icon: Icons.replay,
              onPressed: () {
                AppDialog.confirm(
                  context,
                  title: 'Начать новый забег?',
                  message: 'Текущие результаты сохранены.',
                ).then((confirm) {
                  if (confirm == true) {
                    ref.read(quickSessionProvider.notifier).reset();
                  }
                });
              },
            ),
          ),
        ),
    ]);
  }
}

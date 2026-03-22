import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/quick_timer/quick_result_calculator.dart';
import '../../domain/timing/result_table.dart';
import '../../domain/timing/time_formatter.dart';

/// QT3 — Результаты (протокол) быстрой сессии из Истории.
class QuickTimerResultsScreen extends ConsumerStatefulWidget {
  const QuickTimerResultsScreen({super.key});

  @override
  ConsumerState<QuickTimerResultsScreen> createState() => _QuickTimerResultsScreenState();
}

class _QuickTimerResultsScreenState extends ConsumerState<QuickTimerResultsScreen> {
  bool _showCards = false;

  void _showAthleteDetail(BuildContext context, QuickSession session, ResultRow row, ColorScheme cs) {
    final a = session.athletes.firstWhere(
      (x) => x.id == row.entryId, 
      orElse: () => session.athletes.first,
    );
    
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(quickSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Результаты')),
        body: const Center(child: Text('Нет данных.')),
      );
    }

    final isMass = session.mode == QuickStartMode.mass;
    final displaySettings = ref.watch(qtDisplaySettingsProvider);
    final table = QuickResultCalculator.buildTable(session, displaySettings);

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Протокол'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Новый забег',
            onPressed: () {
              ref.read(quickSessionProvider.notifier).reset();
              context.go('/quick-timer');
            },
          ),
        ],
      ),
      body: Column(children: [
        // ── Инфо-панель сверху ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1))),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                session.title ?? _formatDate(session.date),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${isMass ? 'Масс-старт' : 'Разделка'} · ${session.totalLaps} кр. · ${session.athletes.length} чел.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ]),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${session.finishedCount}/${session.athletes.length}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
              ),
              const SizedBox(width: 12),
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
                    size: 20,
                    color: _showCards ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ]),
          ]),
        ),

        // ── Таблица результатов ──
        Expanded(
          child: table.rows.isEmpty 
          ? Center(child: Text('Нет результатов', style: TextStyle(color: cs.onSurfaceVariant)))
          : AppResultTable(
              table: table,
              showCards: _showCards,
              onRowTap: (row) => _showAthleteDetail(context, session, row, cs),
            ),
        ),

        // ── Кнопки управления ──
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Expanded(child: AppButton.primary(
                text: 'Новый забег',
                icon: Icons.replay,
                onPressed: () {
                  ref.read(quickSessionProvider.notifier).reset();
                  context.go('/quick-timer');
                },
              )),
              const SizedBox(width: 8),
              Expanded(child: AppButton.secondary(
                text: 'История',
                icon: Icons.history,
                onPressed: () => context.pushReplacement('/quick-timer/history'),
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

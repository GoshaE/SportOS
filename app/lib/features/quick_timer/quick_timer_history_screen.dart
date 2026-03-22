import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';

/// QT4 — История тренировок.
class QuickTimerHistoryScreen extends ConsumerWidget {
  const QuickTimerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final history = ref.watch(quickHistoryProvider);

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('История тренировок'),
      ),
      body: history.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, size: 48, color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('Нет сохранённых тренировок', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            AppButton.primary(
              text: 'Начать тренировку',
              icon: Icons.play_arrow,
              onPressed: () => context.go('/quick-timer'),
            ),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: history.length,
            itemBuilder: (context, i) {
              final s = history[i];
              final isMass = s.mode == QuickStartMode.mass;
              final globalStart = s.globalStartTime ?? s.date;

              // Лучшее время
              Duration? best;
              for (final a in s.athletes) {
                if (a.finishTime == null) continue;
                final start = isMass ? globalStart : (a.startTime ?? globalStart);
                final elapsed = a.finishTime!.difference(start);
                if (best == null || elapsed < best) best = elapsed;
              }

              return Dismissible(
                key: ValueKey('history-${s.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: cs.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: cs.onError),
                ),
                confirmDismiss: (_) => AppDialog.confirm(context, title: 'Удалить?', message: 'Тренировка будет удалена.'),
                onDismissed: (_) => ref.read(quickHistoryProvider.notifier).delete(s.id),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Загрузить сессию для просмотра через reset + set
                          final notifier = ref.read(quickSessionProvider.notifier);
                          notifier.reset();
                          notifier.loadSession(s);
                          context.push('/quick-timer/results');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            // Дата
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('${s.date.day}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.primary)),
                                Text(_monthShort(s.date.month), style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            const SizedBox(width: 12),

                            // Детали
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                s.title ?? _formatTime(s.date),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isMass ? 'Масс-старт' : 'Разделка'} · ${s.totalLaps} кр. · ${s.athletes.length} чел.',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            ])),

                            // Лучшее время
                            if (best != null) ...[
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(TimeFormatter.compact(best), style: TextStyle(fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w900, fontSize: 14, color: cs.primary)),
                                Text('лучший', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                              ]),
                            ],
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  String _monthShort(int m) => const ['янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'][m - 1];

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

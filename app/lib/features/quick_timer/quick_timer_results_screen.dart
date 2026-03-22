import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';

/// QT3 — Результаты быстрой сессии.
class QuickTimerResultsScreen extends ConsumerWidget {
  const QuickTimerResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final globalStart = session.globalStartTime ?? session.date;

    // Сортируем по финишному времени
    final sorted = [...session.athletes];
    sorted.sort((a, b) {
      if (a.finishTime == null && b.finishTime == null) return 0;
      if (a.finishTime == null) return 1;
      if (b.finishTime == null) return -1;
      final aStart = isMass ? globalStart : (a.startTime ?? globalStart);
      final bStart = isMass ? globalStart : (b.startTime ?? globalStart);
      return a.finishTime!.difference(aStart).compareTo(b.finishTime!.difference(bStart));
    });

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Результаты'),
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
        // ── Инфо-панель ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${session.finishedCount}/${session.athletes.length}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
                ),
              ]),
            ],
          ),
        ),

        // ── Таблица результатов ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final a = sorted[i];
              final start = isMass ? globalStart : (a.startTime ?? globalStart);
              final finished = a.finishTime != null;
              final result = finished ? a.finishTime!.difference(start) : null;
              final laps = a.lapDurations(globalStart);

              // Место
              final place = finished ? '${i + 1}' : '—';
              final isTop3 = finished && i < 3;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  backgroundColor: isTop3
                    ? [cs.primary, cs.secondary, cs.tertiary][i].withValues(alpha: 0.06)
                    : null,
                  borderColor: isTop3
                    ? [cs.primary, cs.secondary, cs.tertiary][i].withValues(alpha: 0.2)
                    : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        // Место
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: (isTop3 ? [cs.primary, cs.secondary, cs.tertiary][i] : cs.surfaceContainerHighest).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            place,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14,
                              color: isTop3 ? [cs.primary, cs.secondary, cs.tertiary][i] : cs.onSurfaceVariant),
                          )),
                        ),
                        const SizedBox(width: 12),

                        // BIB
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(a.bib, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: cs.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 10),

                        // Имя + сплиты
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
                          if (laps.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              laps.asMap().entries.map((e) => 'L${e.key + 1}: ${TimeFormatter.compact(e.value)}').join(' · '),
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ])),

                        // Финишное время
                        Text(
                          result != null ? TimeFormatter.full(result) : 'DNF',
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: result != null ? cs.onSurface : cs.error,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Кнопки ──
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                onPressed: () => context.push('/quick-timer/history'),
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

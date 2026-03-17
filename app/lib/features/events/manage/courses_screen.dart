import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen: Управление трассами мероприятия
///
/// CRUD: список трасс → tap → детали (дистанция, чекпоинты, GPX).
/// Данные из `eventConfigProvider.courses`.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Трассы'),
        actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Добавить', onPressed: () {})],
      ),
      body: courses.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.route, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('Нет трасс', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Добавьте трассу для мероприятия', style: TextStyle(fontSize: 13, color: cs.outline)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: courses.length,
              itemBuilder: (ctx, i) {
                final c = courses[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    children: [
                      InkWell(
                        onTap: () => _showCourseDetail(context, ref, c),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Title + distance
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.route, size: 20, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('${c.distanceKm} км', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${c.checkpoints.length} КП',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.secondary)),
                              ),
                            ]),

                            // Elevation
                            if (c.elevationGainM != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.trending_up, size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('D+ ${c.elevationGainM} м', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              ]),
                            ],

                            // Description
                            if (c.description != null) ...[
                              const SizedBox(height: 4),
                              Text(c.description!, style: TextStyle(fontSize: 12, color: cs.outline)),
                            ],

                            // Checkpoints preview
                            if (c.checkpoints.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(spacing: 6, runSpacing: 6, children: c.checkpoints.map((cp) =>
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.location_on, size: 12, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text(cp.name, style: const TextStyle(fontSize: 11)),
                                    if (cp.distanceKm != null) ...[
                                      const SizedBox(width: 4),
                                      Text('${cp.distanceKm} км', style: TextStyle(fontSize: 10, color: cs.outline)),
                                    ],
                                  ]),
                                ),
                              ).toList()),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showCourseDetail(BuildContext context, WidgetRef ref, Course course) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(context, title: course.name, initialHeight: 0.7, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info
        Row(children: [
          _infoChip(cs, Icons.straighten, '${course.distanceKm} км'),
          if (course.elevationGainM != null) ...[
            const SizedBox(width: 8),
            _infoChip(cs, Icons.trending_up, 'D+ ${course.elevationGainM} м'),
          ],
          const SizedBox(width: 8),
          _infoChip(cs, Icons.location_on, '${course.checkpoints.length} КП'),
        ]),
        if (course.description != null) ...[
          const SizedBox(height: 12),
          Text(course.description!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: 16),

        // Checkpoints
        Text('Контрольные точки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface)),
        const SizedBox(height: 8),
        if (course.checkpoints.isEmpty)
          Text('Нет КП', style: TextStyle(fontSize: 13, color: cs.outline))
        else
          ...course.checkpoints.map((cp) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Text('${cp.order}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cp.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                if (cp.distanceKm != null)
                  Text('${cp.distanceKm} км от старта', style: TextStyle(fontSize: 12, color: cs.outline)),
              ])),
            ]),
          )),
      ],
    ));
  }

  Widget _infoChip(ColorScheme cs, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

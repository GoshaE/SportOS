import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen: Управление трассами мероприятия
///
/// CRUD: список трасс → tap → детали, long-press → Edit/Delete.
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить трассу',
            onPressed: () => _showCourseForm(context, ref),
          ),
        ],
      ),
      body: courses.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.route, size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text('Нет трасс', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Добавьте трассу для мероприятия', style: TextStyle(fontSize: 13, color: cs.outline)),
              const SizedBox(height: 16),
              AppButton.primary(
                text: 'Добавить трассу',
                icon: Icons.add,
                onPressed: () => _showCourseForm(context, ref),
              ),
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
                        onLongPress: () => _showCourseActions(context, ref, c),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Title + distance
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.1),
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
                                  color: cs.secondaryContainer.withOpacity(0.3),
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
                                    color: cs.surfaceContainerHighest.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
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

  // ═══════════════════════════════════════
  // CRUD: Add / Edit form
  // ═══════════════════════════════════════

  void _showCourseForm(BuildContext context, WidgetRef ref, {Course? existing}) {
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final distCtrl = TextEditingController(text: existing?.distanceKm.toString() ?? '');
    final elevCtrl = TextEditingController(text: existing?.elevationGainM?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    AppBottomSheet.show(
      context,
      title: isEdit ? 'Редактировать трассу' : 'Новая трасса',
      initialHeight: 0.6,
      actions: [
        AppButton.primary(
          text: isEdit ? 'Сохранить' : 'Добавить',
          icon: isEdit ? Icons.check : Icons.add,
          onPressed: () {
            final name = nameCtrl.text.trim();
            final dist = double.tryParse(distCtrl.text.trim());

            if (name.isEmpty || dist == null || dist <= 0) {
              AppSnackBar.error(context, 'Укажите название и дистанцию');
              return;
            }

            final elev = int.tryParse(elevCtrl.text.trim());
            final desc = descCtrl.text.trim();

            if (isEdit) {
              // Update existing
              ref.read(eventConfigProvider.notifier).update((c) {
                final updated = c.courses.map((course) {
                  if (course.id == existing.id) {
                    return course.copyWith(
                      name: name,
                      distanceKm: dist,
                      elevationGainM: elev,
                      description: desc.isNotEmpty ? desc : null,
                    );
                  }
                  return course;
                }).toList();
                return c.copyWith(courses: updated);
              });
              AppSnackBar.success(context, 'Трасса «$name» обновлена');
            } else {
              // Add new
              final newCourse = Course(
                id: 'course-${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                distanceKm: dist,
                elevationGainM: elev,
                description: desc.isNotEmpty ? desc : null,
              );
              ref.read(eventConfigProvider.notifier).update(
                (c) => c.copyWith(courses: [...c.courses, newCourse]),
              );
              AppSnackBar.success(context, 'Трасса «$name» добавлена');
            }

            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppTextField(
          label: 'Название *',
          hintText: 'Малый круг',
          controller: nameCtrl,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: AppTextField(
              label: 'Дистанция (км) *',
              hintText: '5.0',
              controller: distCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: 'Набор высоты (м)',
              hintText: '120',
              controller: elevCtrl,
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Описание',
          hintText: 'Лесная трасса с двумя подъёмами',
          controller: descCtrl,
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        AppInfoBanner.info(title: 'GPX-файлы и чекпоинты можно добавить после создания'),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Actions: Edit / Delete
  // ═══════════════════════════════════════

  void _showCourseActions(BuildContext context, WidgetRef ref, Course course) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: course.name,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Icon(Icons.edit, color: cs.primary),
          title: const Text('Редактировать'),
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            _showCourseForm(context, ref, existing: course);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: cs.error),
          title: Text('Удалить', style: TextStyle(color: cs.error)),
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
            final ok = await AppDialog.confirm(
              context,
              title: 'Удалить трассу?',
              message: '«${course.name}» будет удалена. Дисциплины, использующие эту трассу, потеряют привязку.',
              confirmText: 'Удалить',
              isDanger: true,
            );
            if (ok == true) {
              ref.read(eventConfigProvider.notifier).update(
                (c) => c.copyWith(courses: c.courses.where((cr) => cr.id != course.id).toList()),
              );
              if (context.mounted) AppSnackBar.info(context, 'Трасса «${course.name}» удалена');
            }
          },
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Detail view
  // ═══════════════════════════════════════

  void _showCourseDetail(BuildContext context, WidgetRef ref, Course course) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(context, title: course.name, initialHeight: 0.7,
      actions: [
        AppButton.secondary(
          text: 'Редактировать',
          icon: Icons.edit,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            _showCourseForm(context, ref, existing: course);
          },
        ),
      ],
      child: Column(
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
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), shape: BoxShape.circle),
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
        color: cs.surfaceContainerHighest.withOpacity(0.5),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';
import '../../../domain/event/discipline_catalog.dart';

/// Screen ID: E2 — Дисциплины и классы
///
/// Карточки дисциплин с summary → tap → секционный редактор:
/// 1. Дистанция (круги), 2. Трасса, 3. Старт, 4. Категории, 5. Цена.
class DisciplinesScreen extends ConsumerWidget {
  const DisciplinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final courses = ref.watch(coursesProvider);
    final eventConfig = ref.watch(eventConfigProvider);

    // Group by sport type
    final grouped = <String, List<DisciplineConfig>>{};
    for (final d in disciplines) {
      final sport = _inferSport(d.name);
      grouped.putIfAbsent(sport, () => []).add(d);
    }

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Дисциплины'),
        actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Добавить дисциплину', onPressed: () => _showAddDiscipline(context, ref, courses, eventConfig))],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        // Summary chips
        Wrap(spacing: 6, runSpacing: 4, children: grouped.entries.map((e) {
          final info = _sportInfo(e.key);
          return Chip(
            avatar: Text(info.icon),
            label: Text('${info.label} (${e.value.length})'),
            backgroundColor: info.color.withValues(alpha: 0.1),
          );
        }).toList()),
        const SizedBox(height: 8),

        // Discipline cards grouped by sport
        ...grouped.entries.expand((entry) {
          final items = entry.value;
          final info = _sportInfo(entry.key);
          return [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Row(children: [
                Text(info.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(info.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: info.color)),
              ]),
            ),
            ...items.map((d) {
              final course = courses.where((c) => c.id == d.courseId).firstOrNull;
              return _DisciplineCard(
                discipline: d,
                course: course,
                eventConfig: eventConfig,
                sportColor: info.color,
                onTap: () => _showEditDiscipline(context, ref, d, courses, eventConfig),
              );
            }),
          ];
        }),
      ]),
    );
  }

  // ─── Edit Discipline Sheet ───

  void _showEditDiscipline(BuildContext context, WidgetRef ref, DisciplineConfig d, List<Course> courses, EventConfig eventConfig) {
    final lapCtrl = TextEditingController(text: '${d.lapLengthM ?? (d.distanceKm * 1000).toInt()}');
    final lapsCtrl = TextEditingController(text: '${d.laps}');
    final cutoffHCtrl = TextEditingController(text: '${d.cutoffTime?.inHours ?? 2}');
    final cutoffMCtrl = TextEditingController(text: (d.cutoffTime?.inMinutes.remainder(60) ?? 0).toString().padLeft(2, '0'));
    final priceCtrl = TextEditingController(text: '${d.priceRub ?? 0}');
    final intervalCtrl = TextEditingController(text: '${d.interval.inSeconds}');
    String startTypeStr = d.startType.name;
    Set<String> cats = Set<String>.from(d.categories);
    String? selectedCourseId = d.courseId;
    final maxPartCtrl = TextEditingController(text: d.maxParticipants != null ? '${d.maxParticipants}' : '');
    TimeOfDay selectedStartTime = TimeOfDay(hour: d.firstStartTime.hour, minute: d.firstStartTime.minute);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: d.name, initialHeight: 0.9, child: StatefulBuilder(
      builder: (ctx, setModal) {
        final lapM = int.tryParse(lapCtrl.text) ?? 0;
        final laps = int.tryParse(lapsCtrl.text) ?? 0;
        final totalKm = (lapM * laps / 1000.0).toStringAsFixed(1);
        final selectedCourse = courses.where((c) => c.id == selectedCourseId).firstOrNull;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── 1. Дистанция ───
          _editSection(cs, 'Дистанция', Icons.straighten),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Круг (м)',
                  controller: lapCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                )),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: AppTextField(
                  label: 'Кругов',
                  controller: lapsCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                )),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('= $totalKm км', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ─── 2. Трасса ───
          _editSection(cs, 'Трасса', Icons.route),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Course chips
              Wrap(spacing: 6, runSpacing: 6, children: courses.map((c) => ChoiceChip(
                label: Text('${c.name} (${c.distanceKm} км)', style: const TextStyle(fontSize: 12)),
                selected: selectedCourseId == c.id,
                onSelected: (_) => setModal(() => selectedCourseId = c.id),
                avatar: Icon(Icons.route, size: 14, color: selectedCourseId == c.id ? cs.onPrimary : cs.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              )).toList()),

              // Course details
              if (selectedCourse != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${selectedCourse.checkpoints.length} КП', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (selectedCourse.elevationGainM != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.trending_up, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('D+ ${selectedCourse.elevationGainM} м', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ]),
                if (selectedCourse.checkpoints.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 4, children: selectedCourse.checkpoints.map((cp) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Text(cp.name, style: const TextStyle(fontSize: 10)),
                    ),
                  ).toList()),
                ],
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // ─── 3. Старт ───
          _editSection(cs, 'Тип старта', Icons.flag),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _startChip('individual', 'Раздельный', Icons.person, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('mass', 'Масс-старт', Icons.groups, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('wave', 'Волна', Icons.waves, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('pursuit', 'Преследование', Icons.trending_up, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('relay', 'Эстафета', Icons.sync_alt, startTypeStr, (v) => setModal(() => startTypeStr = v)),
          ]),
          if (startTypeStr == 'individual' || startTypeStr == 'pursuit') ...[
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(width: 120, child: AppTextField(
                label: 'Интервал (сек)',
                controller: intervalCtrl,
                keyboardType: TextInputType.number,
              )),
              const SizedBox(width: 12),
              Expanded(child: Text(
                startTypeStr == 'pursuit' ? 'Базовый интервал (Гундерсен)' : 'Между стартами участников',
                style: TextStyle(fontSize: 12, color: cs.outline),
              )),
            ]),
          ],
          if (startTypeStr == 'wave') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.waves, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Настройки волн', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  SizedBox(width: 120, child: AppTextField(
                    label: 'Буфер (сек)',
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Пауза между волнами', style: TextStyle(fontSize: 12, color: cs.outline))),
                ]),
                const SizedBox(height: 6),
                Text('Волны назначаются по категориям при жеребьёвке', style: TextStyle(fontSize: 11, color: cs.outline, fontStyle: FontStyle.italic)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          // First start time
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(context: ctx, initialTime: selectedStartTime);
              if (picked != null) setModal(() => selectedStartTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.schedule, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Старт в ', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                Text(
                  '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: cs.outline),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AppTextField(
              label: 'Макс. участников',
              controller: maxPartCtrl,
              prefixIcon: Icons.people_outline,
              keyboardType: TextInputType.number,
            )),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Row(children: [
              SizedBox(width: 60, child: AppTextField(
                label: 'Ч',
                controller: cutoffHCtrl,
                keyboardType: TextInputType.number,
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':')),
              SizedBox(width: 60, child: AppTextField(
                label: 'Мин',
                controller: cutoffMCtrl,
                keyboardType: TextInputType.number,
              )),
              const SizedBox(width: 8),
              Text('Cutoff', style: TextStyle(fontSize: 12, color: cs.outline)),
            ])),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: AppTextField(
              label: 'Цена ₽',
              controller: priceCtrl,
              keyboardType: TextInputType.number,
            )),
          ]),
          const SizedBox(height: 20),

          // ─── 4. Категории ───
          _editSection(cs, 'Допущенные категории', Icons.category),
          Row(children: [
            AppButton.text(text: 'Все', icon: Icons.select_all,
              onPressed: () => setModal(() { cats = {'М', 'Ж', 'Юн', 'Юнк', 'Дети', 'M35', 'M40', 'M45', 'M50', 'M55', 'M60+', 'F35', 'F40', 'F45', 'F50+', 'Вет'}; }),
            ),
            AppButton.text(text: 'Убрать', icon: Icons.deselect,
              onPressed: () => setModal(() => cats.clear()),
            ),
          ]),
          Text('Основные:', style: TextStyle(fontSize: 11, color: cs.outline)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 2, children: ['М', 'Ж', 'Юн', 'Юнк', 'Дети'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          const SizedBox(height: 6),
          Text('Возрастные (мужчины):', style: TextStyle(fontSize: 11, color: cs.outline)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 2, children: ['M35', 'M40', 'M45', 'M50', 'M55', 'M60+'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          const SizedBox(height: 4),
          Text('Возрастные (женщины):', style: TextStyle(fontSize: 11, color: cs.outline)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 2, children: ['F35', 'F40', 'F45', 'F50+', 'Вет'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          const SizedBox(height: 20),

          // ─── Save ───
          AppButton.primary(
            text: 'Сохранить',
            icon: Icons.save,
            onPressed: () {
              final newLapM = int.tryParse(lapCtrl.text) ?? d.lapLengthM ?? (d.distanceKm * 1000).toInt();
              final newLaps = int.tryParse(lapsCtrl.text) ?? d.laps;
              final newInterval = int.tryParse(intervalCtrl.text) ?? d.interval.inSeconds;
              final newPrice = int.tryParse(priceCtrl.text);
              final cutoffH = int.tryParse(cutoffHCtrl.text) ?? 2;
              final cutoffM = int.tryParse(cutoffMCtrl.text) ?? 0;
              final st = StartType.values.firstWhere((e) => e.name == startTypeStr, orElse: () => d.startType);

              ref.read(eventConfigProvider.notifier).updateDiscipline(d.id, (old) => old.copyWith(
                lapLengthM: newLapM,
                distanceKm: newLapM * newLaps / 1000.0,
                laps: newLaps,
                startType: st,
                interval: Duration(seconds: newInterval),
                priceRub: newPrice,
                categories: cats.toList(),
                courseId: selectedCourseId,
                cutoffTime: Duration(hours: cutoffH, minutes: cutoffM),
                maxParticipants: int.tryParse(maxPartCtrl.text),
                firstStartTime: DateTime(
                  d.firstStartTime.year, d.firstStartTime.month, d.firstStartTime.day,
                  selectedStartTime.hour, selectedStartTime.minute,
                ),
              ));

              Navigator.pop(ctx);
              AppSnackBar.success(context, 'Дисциплина обновлена');
            },
          ),
          const SizedBox(height: 12),
          // ─── Delete ───
          AppButton.smallDanger(
            text: 'Удалить дисциплину',
            icon: Icons.delete,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteDiscipline(context, ref, d);
            },
          ),
        ]);
      },
    ));
  }

  // ─── Add New Discipline (2-step: catalog → customize) ───

  void _showAddDiscipline(BuildContext context, WidgetRef ref, List<Course> courses, EventConfig eventConfig) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    AppBottomSheet.show(context, title: 'Выберите дисциплину', initialHeight: 0.85, child: StatefulBuilder(
      builder: (ctx, setModal) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Catalog grouped by sport
          ...disciplineCatalog.expand((sport) => [
            // Sport header
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Row(children: [
                Text(sport.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(sport.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${sport.disciplines.length}', style: TextStyle(fontSize: 12, color: cs.outline)),
              ]),
            ),
            const Divider(height: 1),
            // Discipline items
            ...sport.disciplines.map((tmpl) => InkWell(
              onTap: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                _showCustomizeDiscipline(context, ref, tmpl, courses, eventConfig);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(children: [
                  SizedBox(width: 32, child: Text(tmpl.emoji ?? '🏁', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tmpl.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${tmpl.distanceKm.toStringAsFixed(1)} км · ${tmpl.laps} кр. · ${tmpl.startType == 'mass' ? 'масс-старт' : tmpl.startType == 'wave' ? 'волна' : 'разд. ${tmpl.intervalSec}с'}',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ])),
                  if (tmpl.defaultPriceRub != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('${tmpl.defaultPriceRub}₽', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: cs.outline),
                ]),
              ),
            )),
          ]),
        ]);
      },
    ));
  }

  // ─── Step 2: Customize selected template ───

  void _showCustomizeDiscipline(BuildContext context, WidgetRef ref, DisciplineTemplate tmpl, List<Course> courses, EventConfig eventConfig) {
    final nameCtrl = TextEditingController(text: tmpl.name);
    final lapCtrl = TextEditingController(text: '${tmpl.lapLengthM}');
    final lapsCtrl = TextEditingController(text: '${tmpl.laps}');
    final priceCtrl = TextEditingController(text: '${tmpl.defaultPriceRub ?? 0}');
    final intervalCtrl = TextEditingController(text: '${tmpl.intervalSec}');
    String startTypeStr = tmpl.startType;
    Set<String> cats = Set<String>.from(tmpl.defaultCategories);
    String? selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
    int selectedDay = 1;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'Настроить: ${tmpl.name}', initialHeight: 0.9, child: StatefulBuilder(
      builder: (ctx, setModal) {
        final lapM = int.tryParse(lapCtrl.text) ?? 0;
        final laps = int.tryParse(lapsCtrl.text) ?? 0;
        final totalKm = (lapM * laps / 1000.0).toStringAsFixed(1);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Template badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(tmpl.emoji ?? '🏁', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Шаблон: ${tmpl.name}', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),

          // Name
          AppTextField(
            label: 'Название *',
            controller: nameCtrl,
          ),
          const SizedBox(height: 16),

          // Distance
          _editSection(cs, 'Дистанция', Icons.straighten),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Круг (м)',
                  controller: lapCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                )),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: AppTextField(
                  label: 'Кругов',
                  controller: lapsCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                )),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('= $totalKm км', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Start type
          _editSection(cs, 'Тип старта', Icons.flag),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _startChip('individual', 'Раздельный', Icons.person, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('mass', 'Масс-старт', Icons.groups, startTypeStr, (v) => setModal(() => startTypeStr = v)),
            _startChip('wave', 'Волна', Icons.waves, startTypeStr, (v) => setModal(() => startTypeStr = v)),
          ]),
          if (startTypeStr == 'individual') ...[
            const SizedBox(height: 8),
            SizedBox(width: 140, child: AppTextField(
              label: 'Интервал (сек)',
              controller: intervalCtrl,
              keyboardType: TextInputType.number,
            )),
          ],
          const SizedBox(height: 16),

          // Course + Day
          if (courses.isNotEmpty) ...[
            _editSection(cs, 'Трасса', Icons.route),
            Wrap(spacing: 6, runSpacing: 6, children: courses.map((c) => ChoiceChip(
              label: Text('${c.name} (${c.distanceKm} км)', style: const TextStyle(fontSize: 12)),
              selected: selectedCourseId == c.id,
              onSelected: (_) => setModal(() => selectedCourseId = c.id),
              visualDensity: VisualDensity.compact,
            )).toList()),
          ],
          if (eventConfig.isMultiDay) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: eventConfig.days.map((d) => ChoiceChip(
              label: Text('День ${d.dayNumber}', style: const TextStyle(fontSize: 12)),
              selected: selectedDay == d.dayNumber,
              onSelected: (_) => setModal(() => selectedDay = d.dayNumber),
              visualDensity: VisualDensity.compact,
            )).toList()),
          ],
          const SizedBox(height: 16),

          // Categories
          _editSection(cs, 'Категории', Icons.category),
          Row(children: [
            AppButton.text(text: 'Все', icon: Icons.select_all,
              onPressed: () => setModal(() { cats = {'М', 'Ж', 'Юн', 'Юнк', 'Дети', 'M35', 'M40', 'F35', 'F40', 'Вет'}; }),
            ),
            AppButton.text(text: 'Убрать', icon: Icons.deselect,
              onPressed: () => setModal(() => cats.clear()),
            ),
          ]),
          Wrap(spacing: 4, runSpacing: 2, children: ['М', 'Ж', 'Юн', 'Юнк', 'Дети', 'M35', 'M40', 'M45', 'M50', 'F35', 'F40', 'F45', 'Вет'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          const SizedBox(height: 16),

          // Price
          SizedBox(width: 140, child: AppTextField(
            label: 'Цена ₽',
            controller: priceCtrl,
            keyboardType: TextInputType.number,
          )),
          const SizedBox(height: 20),

          // Create button
          AppButton.primary(
            text: 'Создать дисциплину',
            icon: Icons.add,
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                AppSnackBar.error(context, 'Введите название дисциплины');
                return;
              }
              final newLapM = int.tryParse(lapCtrl.text) ?? tmpl.lapLengthM;
              final newLaps = int.tryParse(lapsCtrl.text) ?? tmpl.laps;
              final interval = int.tryParse(intervalCtrl.text) ?? tmpl.intervalSec;
              final price = int.tryParse(priceCtrl.text);
              final st = StartType.values.firstWhere((e) => e.name == startTypeStr, orElse: () => StartType.individual);
              final dayDate = eventConfig.days.where((d) => d.dayNumber == selectedDay).firstOrNull?.date ?? eventConfig.startDate;

              final newDisc = DisciplineConfig(
                id: 'd-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                distanceKm: newLapM * newLaps / 1000.0,
                lapLengthM: newLapM,
                laps: newLaps,
                startType: st,
                interval: Duration(seconds: interval),
                firstStartTime: DateTime(dayDate.year, dayDate.month, dayDate.day, 10, 0),
                cutoffTime: const Duration(hours: 2),
                categories: cats.toList(),
                priceRub: price,
                courseId: selectedCourseId,
                dayNumber: eventConfig.isMultiDay ? selectedDay : null,
              );

              ref.read(eventConfigProvider.notifier).addDiscipline(newDisc);
              Navigator.of(ctx, rootNavigator: true).pop();
              AppSnackBar.success(context, '${nameCtrl.text.trim()} добавлена');
            },
          ),
        ]);
      },
    ));
  }

  // ─── Delete Discipline ───

  void _confirmDeleteDiscipline(BuildContext context, WidgetRef ref, DisciplineConfig d) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить дисциплину?'),
      content: Text('${d.name} (${d.totalDistanceKm.toStringAsFixed(1)} км) будет удалена.'),
      actions: [
        AppButton.text(text: 'Отмена', onPressed: () => Navigator.pop(ctx)),
        AppButton.small(text: 'Удалить', onPressed: () {
          ref.read(eventConfigProvider.notifier).removeDiscipline(d.id);
          Navigator.pop(ctx);
          AppSnackBar.success(context, '${d.name} удалена');
        }),
      ],
    ));
  }

  Widget _editSection(ColorScheme cs, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
      ]),
    );
  }

  // ─── Helpers ──

  String _inferSport(String name) {
    if (name.contains('Скиджоринг') || name.contains('Нарт') || name.contains('Пулк')) return 'sled';
    if (name.contains('Каникросс')) return 'canicross';
    if (name.contains('Трейл')) return 'trail';
    if (name.contains('Лыж')) return 'ski';
    if (name.contains('MTB') || name.contains('Велос')) return 'cycle';
    return 'other';
  }

  _SportInfo _sportInfo(String sport) {
    return switch (sport) {
      'sled'      => const _SportInfo('🐕', 'Ездовой спорт', Color(0xFF1565C0)),
      'canicross' => const _SportInfo('🏃🐕', 'Каникросс', Color(0xFF2E7D32)),
      'trail'     => const _SportInfo('🏔', 'Трейл', Color(0xFFE65100)),
      'ski'       => const _SportInfo('⛷', 'Лыжные гонки', Color(0xFF0277BD)),
      'cycle'     => const _SportInfo('🚴', 'Велоспорт', Color(0xFF6A1B9A)),
      _           => const _SportInfo('🏁', 'Другое', Color(0xFF616161)),
    };
  }

  Widget _startChip(String value, String label, IconData icon, String current, ValueChanged<String> onSelected) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 14),
      selected: selected,
      onSelected: (_) => onSelected(value),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Discipline Card Widget ───

class _DisciplineCard extends StatelessWidget {
  final DisciplineConfig discipline;
  final Course? course;
  final EventConfig eventConfig;
  final Color sportColor;
  final VoidCallback onTap;

  const _DisciplineCard({
    required this.discipline,
    required this.course,
    required this.eventConfig,
    required this.sportColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = discipline;
    final totalKm = d.totalDistanceKm.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(padding: EdgeInsets.zero, children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Header: Name + Price ───
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Sport icon circle
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: sportColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    d.startType == StartType.individual ? Icons.person : Icons.groups,
                    size: 18, color: sportColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  // Distance line
                  RichText(text: TextSpan(
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    children: [
                      TextSpan(text: '$totalKm км', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
                      if (d.lapLengthM != null) TextSpan(text: '  (${d.lapLengthM}м × ${d.laps})'),
                    ],
                  )),
                ])),
                if (d.priceRub != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: sportColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${d.priceRub}₽', style: TextStyle(fontSize: 13, color: sportColor, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 10),

              // ─── Info Row: Course + Start + Cutoff ───
              Wrap(spacing: 12, runSpacing: 6, children: [
                if (course != null) _infoChip(cs, Icons.route, course!.name, cs.secondary),
                _infoChip(cs, d.startType == StartType.individual ? Icons.person : Icons.groups,
                  _startTypeLabel(d), cs.onSurfaceVariant),
                if (d.cutoffTime != null) _infoChip(cs, Icons.timer, _formatDuration(d.cutoffTime!), cs.onSurfaceVariant),
                if (d.dayNumber != null && eventConfig.isMultiDay)
                  _infoChip(cs, Icons.calendar_today, 'День ${d.dayNumber}', cs.tertiary),
              ]),
              const SizedBox(height: 8),

              // ─── Categories ───
              Wrap(spacing: 4, runSpacing: 4, children: d.categories.map((c) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
              ).toList()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoChip(ColorScheme cs, IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }

  String _startTypeLabel(DisciplineConfig d) {
    return switch (d.startType) {
      StartType.individual => 'Разд. ${d.interval.inSeconds}с',
      StartType.mass       => 'Масс-старт',
      StartType.wave       => 'Волна',
      StartType.pursuit    => 'Преследование',
      StartType.relay      => 'Эстафета',
    };
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hч $mм';
  }
}

class _SportInfo {
  final String icon;
  final String label;
  final Color color;
  const _SportInfo(this.icon, this.label, this.color);
}

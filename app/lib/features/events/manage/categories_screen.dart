import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// Preset: типовые категории ездового спорта.
const _presets = [
  RaceCategory(id: 'cat-cec', name: 'CEC (экзамен)', shortName: 'CEC', dogCount: 1, sortOrder: 0),
  RaceCategory(id: 'cat-open-m', name: 'OPEN мужчины', shortName: 'OPEN М', gender: CategoryGender.male, dogCount: 1, sortOrder: 1),
  RaceCategory(id: 'cat-open-f', name: 'OPEN женщины', shortName: 'OPEN Ж', gender: CategoryGender.female, dogCount: 1, sortOrder: 2),
  RaceCategory(id: 'cat-vet-m', name: 'Ветераны мужчины', shortName: 'ВЕТ М', gender: CategoryGender.male, ageMin: 50, dogCount: 1, sortOrder: 3),
  RaceCategory(id: 'cat-vet-f', name: 'Ветераны женщины', shortName: 'ВЕТ Ж', gender: CategoryGender.female, ageMin: 50, dogCount: 1, sortOrder: 4),
  RaceCategory(id: 'cat-jun', name: 'Юниоры', shortName: 'ЮН', ageMin: 14, ageMax: 17, dogCount: 1, sortOrder: 5),
  RaceCategory(id: 'cat-kids', name: 'Дети', shortName: 'ДЕТИ', ageMax: 13, dogCount: 1, sortOrder: 6),
  RaceCategory(id: 'cat-2dog', name: 'Нарты (2 собаки)', shortName: '2D', dogCount: 2, sortOrder: 7),
  RaceCategory(id: 'cat-4dog', name: 'Нарты (4 собаки)', shortName: '4D', dogCount: 4, sortOrder: 8),
];

/// P1 — Конструктор категорий.
///
/// Управление категориями на уровне мероприятия.
/// Категории затем привязываются к дисциплинам.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final cs = Theme.of(context).colorScheme;
    final cats = config.raceCategories;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Категории'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить',
            onPressed: () => _editCategory(context, ref, null),
          ),
        ],
      ),
      body: cats.isEmpty ? _emptyState(context, ref, cs) : _body(context, ref, cs, cats),
    );
  }

  // ─── Empty state ───
  Widget _emptyState(BuildContext context, WidgetRef ref, ColorScheme cs) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: Icon(Icons.category_outlined, size: 40, color: cs.primary),
        ),
        const SizedBox(height: 20),
        Text('Нет категорий', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Категории разделяют участников по полу, возрасту\nи количеству собак для правильной группировки.',
          style: TextStyle(color: cs.outline, fontSize: 13), textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => _loadPreset(ref, context),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Загрузить типовые категории'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _editCategory(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('Создать вручную'),
        ),
      ]),
    ));
  }

  Widget _body(BuildContext context, WidgetRef ref, ColorScheme cs, List<RaceCategory> cats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Icon(Icons.category, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${cats.length} категорий', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
              Text(_summaryText(cats), style: TextStyle(fontSize: 12, color: cs.outline)),
            ])),
            IconButton(
              icon: const Icon(Icons.auto_fix_high, size: 20),
              tooltip: 'Загрузить типовые',
              onPressed: () => _loadPreset(ref, context),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Category cards
        ...cats.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryCard(
              cat: cat,
              cs: cs,
              onEdit: () => _editCategory(context, ref, cat),
              onDelete: () {
                final updated = List<RaceCategory>.from(cats)..removeAt(i);
                ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: updated));
              },
            ),
          );
        }),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _editCategory(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('Добавить категорию'),
        ),
      ],
    );
  }

  String _summaryText(List<RaceCategory> cats) {
    final genders = <String>{};
    for (final c in cats) {
      if (c.gender == CategoryGender.male) genders.add('М');
      if (c.gender == CategoryGender.female) genders.add('Ж');
      if (c.gender == CategoryGender.any) { genders.add('М'); genders.add('Ж'); }
    }
    final dogs = cats.map((c) => c.dogCount).toSet().toList()..sort();
    return 'Пол: ${genders.join("/")}  ·  Собак: ${dogs.join(", ")}';
  }

  void _loadPreset(WidgetRef ref, BuildContext context) {
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: _presets));
    AppSnackBar.success(context, '${_presets.length} типовых категорий загружено');
  }

  void _editCategory(BuildContext context, WidgetRef ref, RaceCategory? existing) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final shortCtrl = TextEditingController(text: existing?.shortName ?? '');
    final ageMinCtrl = TextEditingController(text: existing?.ageMin?.toString() ?? '');
    final ageMaxCtrl = TextEditingController(text: existing?.ageMax?.toString() ?? '');
    var gender = existing?.gender ?? CategoryGender.any;
    var dogCount = existing?.dogCount ?? 1;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: isNew ? 'Новая категория' : existing!.name, child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        // Name
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Полное название *', border: OutlineInputBorder(), hintText: 'OPEN мужчины'),
        ),
        const SizedBox(height: 12),

        // Short name + Gender
        Row(children: [
          Expanded(child: TextField(
            controller: shortCtrl,
            decoration: const InputDecoration(labelText: 'Код (кратко)', border: OutlineInputBorder(), isDense: true, hintText: 'OPEN М'),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<CategoryGender>(
            value: gender,
            decoration: const InputDecoration(labelText: 'Пол', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: CategoryGender.any, child: Text('Любой')),
              DropdownMenuItem(value: CategoryGender.male, child: Text('Мужской')),
              DropdownMenuItem(value: CategoryGender.female, child: Text('Женский')),
            ],
            onChanged: (v) => setModal(() => gender = v!),
          )),
        ]),
        const SizedBox(height: 12),

        // Age
        Row(children: [
          Expanded(child: TextField(
            controller: ageMinCtrl,
            decoration: const InputDecoration(labelText: 'Возраст от', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('–', style: TextStyle(fontSize: 18, color: cs.outline)),
          ),
          Expanded(child: TextField(
            controller: ageMaxCtrl,
            decoration: const InputDecoration(labelText: 'до', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 12),

        // Dog count
        Row(children: [
          Text('Количество собак:', style: TextStyle(fontSize: 13, color: cs.onSurface)),
          const Spacer(),
          SegmentedButton<int>(
            selected: {dogCount},
            onSelectionChanged: (v) => setModal(() => dogCount = v.first),
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 6, label: Text('6')),
            ],
          ),
        ]),
        const SizedBox(height: 16),

        // Save
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) {
              AppSnackBar.error(context, 'Введите название');
              return;
            }
            final cat = RaceCategory(
              id: existing?.id ?? 'cat-${DateTime.now().millisecondsSinceEpoch}',
              name: nameCtrl.text.trim(),
              shortName: shortCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : shortCtrl.text.trim(),
              gender: gender,
              ageMin: int.tryParse(ageMinCtrl.text),
              ageMax: int.tryParse(ageMaxCtrl.text),
              dogCount: dogCount,
              sortOrder: existing?.sortOrder ?? 99,
            );
            final config = ref.read(eventConfigProvider);
            final list = List<RaceCategory>.from(config.raceCategories);
            if (isNew) {
              list.add(cat);
            } else {
              final idx = list.indexWhere((c) => c.id == existing!.id);
              if (idx >= 0) list[idx] = cat;
            }
            ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: list));
            Navigator.pop(ctx);
            AppSnackBar.success(context, isNew ? '«${cat.name}» добавлена' : '«${cat.name}» обновлена');
          },
          icon: const Icon(Icons.save),
          label: Text(isNew ? 'Создать' : 'Сохранить'),
        )),
        const SizedBox(height: 8),
      ]),
    ));
  }
}

// ─── Category Card ───

class _CategoryCard extends StatelessWidget {
  final RaceCategory cat;
  final ColorScheme cs;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({required this.cat, required this.cs, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final genderIcon = switch (cat.gender) {
      CategoryGender.male => Icons.male,
      CategoryGender.female => Icons.female,
      CategoryGender.any => Icons.people,
    };
    final genderColor = switch (cat.gender) {
      CategoryGender.male => Colors.blue,
      CategoryGender.female => Colors.pink,
      CategoryGender.any => cs.primary,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: genderColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            // Gender icon
            CircleAvatar(
              radius: 18,
              backgroundColor: genderColor.withValues(alpha: 0.1),
              child: Icon(genderIcon, color: genderColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(cat.shortName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary)),
                ),
              ]),
              const SizedBox(height: 4),
              Wrap(spacing: 12, children: [
                _chipLabel(Icons.cake, cat.ageLabel, cs),
                _chipLabel(Icons.pets, '${cat.dogCount} соб.', cs),
                _chipLabel(genderIcon, cat.genderLabel, cs),
              ]),
            ])),
            // Actions
            IconButton(icon: Icon(Icons.edit, size: 18, color: cs.outline), onPressed: onEdit, visualDensity: VisualDensity.compact),
            IconButton(icon: Icon(Icons.delete_outline, size: 18, color: cs.error), onPressed: onDelete, visualDensity: VisualDensity.compact),
          ]),
        ),
      ),
    );
  }

  Widget _chipLabel(IconData icon, String text, ColorScheme cs) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: cs.outline),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: cs.outline)),
    ]);
  }
}

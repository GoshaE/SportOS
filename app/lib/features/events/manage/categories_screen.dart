import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

// ─────────────────────────────────────────────────────────────────
// PRESET TEMPLATES — выбираются при первой настройке
// ─────────────────────────────────────────────────────────────────

class _PresetGroup {
  final String name;
  final IconData icon;
  final List<RaceCategory> categories;
  const _PresetGroup({required this.name, required this.icon, required this.categories});
}

final _presetGroups = [
  _PresetGroup(
    name: 'Стандарт (М/Ж)',
    icon: Icons.people,
    categories: [
      const RaceCategory(id: 'cat-m', name: 'Мужчины', shortName: 'М', gender: CategoryGender.male, sortOrder: 0),
      const RaceCategory(id: 'cat-f', name: 'Женщины', shortName: 'Ж', gender: CategoryGender.female, sortOrder: 1),
    ],
  ),
  _PresetGroup(
    name: 'Возрастные группы',
    icon: Icons.cake,
    categories: [
      const RaceCategory(id: 'cat-m', name: 'Мужчины', shortName: 'М', gender: CategoryGender.male, sortOrder: 0),
      const RaceCategory(id: 'cat-f', name: 'Женщины', shortName: 'Ж', gender: CategoryGender.female, sortOrder: 1),
      const RaceCategory(id: 'cat-jun', name: 'Юниоры', shortName: 'ЮН', ageMin: 14, ageMax: 17, sortOrder: 2),
      const RaceCategory(id: 'cat-kids', name: 'Дети', shortName: 'ДЕТИ', ageMax: 13, sortOrder: 3),
      const RaceCategory(id: 'cat-vet-m', name: 'Ветераны М', shortName: 'ВЕТ М', gender: CategoryGender.male, ageMin: 50, sortOrder: 4),
      const RaceCategory(id: 'cat-vet-f', name: 'Ветераны Ж', shortName: 'ВЕТ Ж', gender: CategoryGender.female, ageMin: 50, sortOrder: 5),
    ],
  ),
  _PresetGroup(
    name: 'Мастерс (5-летие)',
    icon: Icons.military_tech,
    categories: [
      const RaceCategory(id: 'cat-m', name: 'Мужчины OPEN', shortName: 'М', gender: CategoryGender.male, sortOrder: 0),
      const RaceCategory(id: 'cat-f', name: 'Женщины OPEN', shortName: 'Ж', gender: CategoryGender.female, sortOrder: 1),
      const RaceCategory(id: 'cat-m35', name: 'M35', shortName: 'M35', gender: CategoryGender.male, ageMin: 35, ageMax: 39, sortOrder: 2),
      const RaceCategory(id: 'cat-m40', name: 'M40', shortName: 'M40', gender: CategoryGender.male, ageMin: 40, ageMax: 44, sortOrder: 3),
      const RaceCategory(id: 'cat-m45', name: 'M45', shortName: 'M45', gender: CategoryGender.male, ageMin: 45, ageMax: 49, sortOrder: 4),
      const RaceCategory(id: 'cat-m50', name: 'M50', shortName: 'M50', gender: CategoryGender.male, ageMin: 50, ageMax: 54, sortOrder: 5),
      const RaceCategory(id: 'cat-f35', name: 'Ж35', shortName: 'Ж35', gender: CategoryGender.female, ageMin: 35, ageMax: 39, sortOrder: 6),
      const RaceCategory(id: 'cat-f40', name: 'Ж40', shortName: 'Ж40', gender: CategoryGender.female, ageMin: 40, ageMax: 44, sortOrder: 7),
      const RaceCategory(id: 'cat-f45', name: 'Ж45', shortName: 'Ж45', gender: CategoryGender.female, ageMin: 45, ageMax: 49, sortOrder: 8),
      const RaceCategory(id: 'cat-f50', name: 'Ж50', shortName: 'Ж50', gender: CategoryGender.female, ageMin: 50, ageMax: 54, sortOrder: 9),
    ],
  ),
  _PresetGroup(
    name: 'Без категорий (абсолют)',
    icon: Icons.emoji_events,
    categories: [
      const RaceCategory(id: 'cat-abs', name: 'Абсолют', shortName: 'ABS', sortOrder: 0),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

/// P1 — Конструктор категорий (универсальный, мультиспорт).
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
          IconButton(icon: const Icon(Icons.add), tooltip: 'Добавить', onPressed: () => _editCategory(context, ref, null)),
        ],
      ),
      body: cats.isEmpty ? _emptyState(context, ref, cs) : _body(context, ref, cs, cats),
    );
  }

  // ─── Empty: выбор шаблона ───
  Widget _emptyState(BuildContext context, WidgetRef ref, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Center(child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(Icons.category_outlined, size: 36, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text('Выберите шаблон', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('или создайте категории вручную', style: TextStyle(fontSize: 13, color: cs.outline)),
        ])),
        const SizedBox(height: 24),

        // Preset cards
        ..._presetGroups.map((group) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: group.categories));
                AppSnackBar.success(context, '«${group.name}» — ${group.categories.length} категорий');
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(group.icon, color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: group.categories.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _genderColor(c.gender, cs).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(c.shortName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _genderColor(c.gender, cs))),
                    )).toList()),
                  ])),
                  Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
                ]),
              ),
            ),
          ),
        )),

        const SizedBox(height: 8),
        Center(child: TextButton.icon(
          onPressed: () => _editCategory(context, ref, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Создать вручную'),
        )),
      ],
    );
  }

  // ─── Body: список категорий ───
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
              const SizedBox(height: 2),
              Wrap(spacing: 6, runSpacing: 4, children: cats.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _genderColor(c.gender, cs).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c.shortName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _genderColor(c.gender, cs))),
              )).toList()),
            ])),
            TextButton(
              onPressed: () {
                ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: []));
              },
              child: Text('Сбросить', style: TextStyle(fontSize: 11, color: cs.error)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ReorderableListView replacement
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

  // ─── Edit / Create ───
  void _editCategory(BuildContext context, WidgetRef ref, RaceCategory? existing) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final shortCtrl = TextEditingController(text: existing?.shortName ?? '');
    final ageMinCtrl = TextEditingController(text: existing?.ageMin?.toString() ?? '');
    final ageMaxCtrl = TextEditingController(text: existing?.ageMax?.toString() ?? '');
    var gender = existing?.gender ?? CategoryGender.any;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: isNew ? 'Новая категория' : existing!.name, child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        // Name
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder(), hintText: 'Мужчины, Юниоры, M35…'),
        ),
        const SizedBox(height: 12),

        // Short name + Gender
        Row(children: [
          Expanded(child: TextField(
            controller: shortCtrl,
            decoration: const InputDecoration(labelText: 'Код', border: OutlineInputBorder(), isDense: true, hintText: 'М, Ж, ЮН…'),
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

        // Age range
        Row(children: [
          Text('Возраст:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: ageMinCtrl,
            decoration: const InputDecoration(labelText: 'от', border: OutlineInputBorder(), isDense: true),
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
        const SizedBox(height: 8),
        Text('Оставьте пустым для любого возраста', style: TextStyle(fontSize: 11, color: cs.outline)),
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
          },
          icon: const Icon(Icons.save),
          label: Text(isNew ? 'Создать' : 'Сохранить'),
        )),
        const SizedBox(height: 8),
      ]),
    ));
  }

  static Color _genderColor(CategoryGender g, ColorScheme cs) => switch (g) {
    CategoryGender.male => Colors.blue,
    CategoryGender.female => Colors.pink,
    CategoryGender.any => cs.primary,
  };
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
    final color = CategoriesScreen._genderColor(cat.gender, cs);
    final genderIcon = switch (cat.gender) {
      CategoryGender.male => Icons.male,
      CategoryGender.female => Icons.female,
      CategoryGender.any => Icons.people,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            // Color circle
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(genderIcon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(cat.shortName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(cat.subtitle, style: TextStyle(fontSize: 12, color: cs.outline)),
            ])),
            // Actions
            IconButton(icon: Icon(Icons.edit, size: 18, color: cs.outline), onPressed: onEdit, visualDensity: VisualDensity.compact),
            IconButton(icon: Icon(Icons.delete_outline, size: 18, color: cs.error), onPressed: onDelete, visualDensity: VisualDensity.compact),
          ]),
        ),
      ),
    );
  }
}

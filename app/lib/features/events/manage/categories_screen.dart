import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

// ─────────────────────────────────────────────────────────────────
// БИБЛИОТЕКА КАТЕГОРИЙ — все доступные варианты
// ─────────────────────────────────────────────────────────────────

const _library = [
  // ─── Базовые ───
  RaceCategory(id: 'lib-m', name: 'Мужчины', shortName: 'М', gender: CategoryGender.male, sortOrder: 0),
  RaceCategory(id: 'lib-f', name: 'Женщины', shortName: 'Ж', gender: CategoryGender.female, sortOrder: 1),
  RaceCategory(id: 'lib-abs', name: 'Абсолют', shortName: 'ABS', sortOrder: 2),

  // ─── Молодёжь ───
  RaceCategory(id: 'lib-jun', name: 'Юниоры', shortName: 'ЮН', ageMin: 14, ageMax: 17, sortOrder: 10),
  RaceCategory(id: 'lib-jun-m', name: 'Юниоры М', shortName: 'ЮН М', gender: CategoryGender.male, ageMin: 14, ageMax: 17, sortOrder: 11),
  RaceCategory(id: 'lib-jun-f', name: 'Юниоры Ж', shortName: 'ЮН Ж', gender: CategoryGender.female, ageMin: 14, ageMax: 17, sortOrder: 12),
  RaceCategory(id: 'lib-kids', name: 'Дети', shortName: 'ДЕТИ', ageMax: 13, sortOrder: 13),

  // ─── Ветераны ───
  RaceCategory(id: 'lib-vet-m', name: 'Ветераны М', shortName: 'ВЕТ М', gender: CategoryGender.male, ageMin: 50, sortOrder: 20),
  RaceCategory(id: 'lib-vet-f', name: 'Ветераны Ж', shortName: 'ВЕТ Ж', gender: CategoryGender.female, ageMin: 50, sortOrder: 21),

  // ─── Мастерс (5-летие) ───
  RaceCategory(id: 'lib-m35', name: 'M35', shortName: 'M35', gender: CategoryGender.male, ageMin: 35, ageMax: 39, sortOrder: 30),
  RaceCategory(id: 'lib-m40', name: 'M40', shortName: 'M40', gender: CategoryGender.male, ageMin: 40, ageMax: 44, sortOrder: 31),
  RaceCategory(id: 'lib-m45', name: 'M45', shortName: 'M45', gender: CategoryGender.male, ageMin: 45, ageMax: 49, sortOrder: 32),
  RaceCategory(id: 'lib-m50', name: 'M50', shortName: 'M50', gender: CategoryGender.male, ageMin: 50, ageMax: 54, sortOrder: 33),
  RaceCategory(id: 'lib-m55', name: 'M55', shortName: 'M55', gender: CategoryGender.male, ageMin: 55, ageMax: 59, sortOrder: 34),
  RaceCategory(id: 'lib-m60', name: 'M60+', shortName: 'M60+', gender: CategoryGender.male, ageMin: 60, sortOrder: 35),
  RaceCategory(id: 'lib-f35', name: 'Ж35', shortName: 'Ж35', gender: CategoryGender.female, ageMin: 35, ageMax: 39, sortOrder: 36),
  RaceCategory(id: 'lib-f40', name: 'Ж40', shortName: 'Ж40', gender: CategoryGender.female, ageMin: 40, ageMax: 44, sortOrder: 37),
  RaceCategory(id: 'lib-f45', name: 'Ж45', shortName: 'Ж45', gender: CategoryGender.female, ageMin: 45, ageMax: 49, sortOrder: 38),
  RaceCategory(id: 'lib-f50', name: 'Ж50', shortName: 'Ж50', gender: CategoryGender.female, ageMin: 50, ageMax: 54, sortOrder: 39),
  RaceCategory(id: 'lib-f55', name: 'Ж55', shortName: 'Ж55', gender: CategoryGender.female, ageMin: 55, ageMax: 59, sortOrder: 40),
  RaceCategory(id: 'lib-f60', name: 'Ж60+', shortName: 'Ж60+', gender: CategoryGender.female, ageMin: 60, sortOrder: 41),
];

// Groups for visual sections
const _sections = [
  ('Базовые', [0, 1, 2]),
  ('Молодёжь', [3, 4, 5, 6]),
  ('Ветераны', [7, 8]),
  ('Мастерс мужчины', [9, 10, 11, 12, 13, 14]),
  ('Мастерс женщины', [15, 16, 17, 18, 19, 20]),
];

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

/// Категории — библиотека с чекбоксами.
/// Отметил = добавил к мероприятию.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final cs = Theme.of(context).colorScheme;
    final selected = config.raceCategories.map((c) => c.id).toSet();
    final count = selected.length;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Категории'),
        actions: [
          if (count > 0)
            TextButton(
              onPressed: () => ref.read(eventConfigProvider.notifier).update(
                  (c) => c.copyWith(raceCategories: [])),
              child: Text('Очистить', style: TextStyle(color: cs.error, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Своя категория',
            onPressed: () => _createCustom(context, ref),
          ),
        ],
      ),
      body: Column(children: [
        // ─── Selected summary ───
        if (count > 0) Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.primaryContainer.withValues(alpha: 0.2),
          child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('Выбрано $count:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            ...config.raceCategories.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _genderColor(c.gender, cs).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(c.shortName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _genderColor(c.gender, cs))),
            )),
          ]),
        ),

        // ─── Library list ───
        Expanded(child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Отметьте категории, которые нужны вашему мероприятию',
                style: TextStyle(fontSize: 12, color: cs.outline)),
            ),

            // Sections from library
            ..._sections.map((section) {
              final (title, indices) = section;
              return _buildSection(context, ref, cs, title, indices, selected);
            }),

            // Custom categories (not from library)
            ..._buildCustomSection(context, ref, cs, config, selected),
          ],
        )),
      ]),
    );
  }

  Widget _buildSection(BuildContext context, WidgetRef ref, ColorScheme cs, String title, List<int> indices, Set<String> selected) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 0.5)),
      ),
      ...indices.map((i) {
        final cat = _library[i];
        final isSelected = selected.contains(cat.id);
        return _CategoryTile(
          cat: cat,
          isSelected: isSelected,
          cs: cs,
          onToggle: () => _toggle(ref, cat, isSelected),
        );
      }),
    ]);
  }

  List<Widget> _buildCustomSection(BuildContext context, WidgetRef ref, ColorScheme cs, EventConfig config, Set<String> selected) {
    final customCats = config.raceCategories.where(
        (c) => !_library.any((lib) => lib.id == c.id)).toList();
    if (customCats.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text('Свои категории', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.tertiary, letterSpacing: 0.5)),
      ),
      ...customCats.map((cat) => _CategoryTile(
        cat: cat,
        isSelected: true,
        cs: cs,
        isCustom: true,
        onToggle: () => _toggle(ref, cat, true),
        onEdit: () => _editCustom(context, ref, cat),
      )),
    ];
  }

  void _toggle(WidgetRef ref, RaceCategory cat, bool isSelected) {
    final config = ref.read(eventConfigProvider);
    final list = List<RaceCategory>.from(config.raceCategories);
    if (isSelected) {
      list.removeWhere((c) => c.id == cat.id);
    } else {
      list.add(cat);
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: list));
  }

  void _createCustom(BuildContext context, WidgetRef ref) {
    _showEditor(context, ref, null);
  }

  void _editCustom(BuildContext context, WidgetRef ref, RaceCategory existing) {
    _showEditor(context, ref, existing);
  }

  void _showEditor(BuildContext context, WidgetRef ref, RaceCategory? existing) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final shortCtrl = TextEditingController(text: existing?.shortName ?? '');
    final ageMinCtrl = TextEditingController(text: existing?.ageMin?.toString() ?? '');
    final ageMaxCtrl = TextEditingController(text: existing?.ageMax?.toString() ?? '');
    var gender = existing?.gender ?? CategoryGender.any;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: isNew ? 'Своя категория' : existing.name, child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder(), hintText: 'Например: Элита'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: shortCtrl,
            decoration: const InputDecoration(labelText: 'Код', border: OutlineInputBorder(), isDense: true, hintText: 'ЭЛ'),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<CategoryGender>(
            initialValue: gender,
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
        Row(children: [
          Text('Возраст:', style: TextStyle(fontSize: 13, color: cs.onSurface)),
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
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) { AppSnackBar.error(context, 'Введите название'); return; }
            final cat = RaceCategory(
              id: existing?.id ?? 'custom-${DateTime.now().millisecondsSinceEpoch}',
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
              final idx = list.indexWhere((c) => c.id == existing.id);
              if (idx >= 0) list[idx] = cat;
            }
            ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(raceCategories: list));
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.save),
          label: Text(isNew ? 'Добавить' : 'Сохранить'),
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

// ─── Category Tile — чекбокс из библиотеки ───

class _CategoryTile extends StatelessWidget {
  final RaceCategory cat;
  final bool isSelected;
  final ColorScheme cs;
  final bool isCustom;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;

  const _CategoryTile({
    required this.cat,
    required this.isSelected,
    required this.cs,
    this.isCustom = false,
    required this.onToggle,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoriesScreen._genderColor(cat.gender, cs);

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: isSelected,
        onChanged: (_) => onToggle(),
        activeColor: color,
      ),
      title: Row(children: [
        Text(cat.name, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(cat.shortName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withValues(alpha: isSelected ? 1.0 : 0.5))),
        ),
      ]),
      subtitle: Text(cat.subtitle, style: TextStyle(fontSize: 11, color: cs.outline)),
      trailing: isCustom && onEdit != null
          ? IconButton(icon: Icon(Icons.edit, size: 16, color: cs.outline), onPressed: onEdit)
          : null,
      onTap: onToggle,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// Предстартовый чек-лист — настройка обязательных пунктов.
///
/// Организатор определяет что нужно сделать перед стартом,
/// назначает ответственные роли, отмечает обязательность.
class PreStartChecklistScreen extends ConsumerWidget {
  const PreStartChecklistScreen({super.key});

  static const _roleLabels = {
    'secretary': 'Секретарь',
    'referee': 'Гл. судья',
    'vet': 'Ветеринар',
    'marshal': 'Маршал',
    'timing': 'Хронометрист',
  };

  static const _roleIcons = {
    'secretary': Icons.description,
    'referee': Icons.gavel,
    'vet': Icons.pets,
    'marshal': Icons.sports,
    'timing': Icons.timer,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(eventConfigProvider);
    final items = config.checklistItems;

    final requiredCount = items.where((i) => i.required).length;
    final optionalCount = items.length - requiredCount;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Предстартовый чек-лист')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Статистика ───
        Row(children: [
          Expanded(child: AppStatCard(value: '$requiredCount', label: 'Обязательных', icon: Icons.check_circle, color: cs.primary)),
          const SizedBox(width: 8),
          Expanded(child: AppStatCard(value: '$optionalCount', label: 'Опциональных', icon: Icons.radio_button_unchecked, color: cs.outline)),
          const SizedBox(width: 8),
          Expanded(child: AppStatCard(value: '${items.length}', label: 'Всего пунктов', icon: Icons.list, color: cs.secondary)),
        ]),
        const SizedBox(height: 16),

        // ─── Список пунктов ───
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final roleLabel = _roleLabels[item.assignedRole] ?? item.assignedRole ?? '—';
          final roleIcon = _roleIcons[item.assignedRole] ?? Icons.person;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              padding: EdgeInsets.zero,
              borderColor: item.required ? cs.primary.withValues(alpha: 0.2) : null,
              children: [
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.required
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14,
                      color: item.required ? cs.primary : cs.outline,
                    )),
                  ),
                  title: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (item.description != null)
                      Text(item.description!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(roleIcon, size: 12, color: cs.outline),
                      const SizedBox(width: 4),
                      Text(roleLabel, style: TextStyle(fontSize: 10, color: cs.outline, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.required ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.required ? 'Обязательно' : 'Опционально',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold,
                            color: item.required ? cs.primary : cs.outline,
                          ),
                        ),
                      ),
                    ]),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (i > 0)
                      IconButton(
                        icon: Icon(Icons.arrow_upward, size: 16, color: cs.outline),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _reorder(ref, items, i, i - 1),
                      ),
                    if (i < items.length - 1)
                      IconButton(
                        icon: Icon(Icons.arrow_downward, size: 16, color: cs.outline),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _reorder(ref, items, i, i + 1),
                      ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final updated = List<ChecklistItemConfig>.from(items)..removeAt(i);
                        ref.read(eventConfigProvider.notifier).update(
                          (c) => c.copyWith(checklistItems: updated),
                        );
                      },
                    ),
                  ]),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _addItem(context, ref, items),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Добавить пункт'),
          )),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              ref.read(eventConfigProvider.notifier).update(
                (c) => c.copyWith(checklistItems: defaultChecklistItems),
              );
              AppSnackBar.info(context, 'Чек-лист сброшен к стандарту');
            },
            child: const Text('Сброс'),
          ),
        ]),
        const SizedBox(height: 32),
      ]),
    );
  }

  void _reorder(WidgetRef ref, List<ChecklistItemConfig> items, int from, int to) {
    final updated = List<ChecklistItemConfig>.from(items);
    final item = updated.removeAt(from);
    updated.insert(to, item);
    ref.read(eventConfigProvider.notifier).update(
      (c) => c.copyWith(checklistItems: updated),
    );
  }

  void _addItem(BuildContext context, WidgetRef ref, List<ChecklistItemConfig> items) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var isRequired = true;
    var selectedRole = 'secretary';

    AppBottomSheet.show(context, title: 'Новый пункт чек-листа', child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder()),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descCtrl,
          decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Роль', border: OutlineInputBorder(), isDense: true),
            items: _roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setModal(() => selectedRole = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: const Text('Обязательно', style: TextStyle(fontSize: 13)),
            value: isRequired,
            onChanged: (v) => setModal(() => isRequired = v!),
          )),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) {
              AppSnackBar.error(ctx, 'Введите название');
              return;
            }
            final item = ChecklistItemConfig(
              id: 'cl-${DateTime.now().millisecondsSinceEpoch}',
              title: titleCtrl.text.trim(),
              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              required: isRequired,
              assignedRole: selectedRole,
              sortOrder: items.length + 1,
            );
            ref.read(eventConfigProvider.notifier).update(
              (c) => c.copyWith(checklistItems: [...c.checklistItems, item]),
            );
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        )),
      ]),
    ));
  }
}

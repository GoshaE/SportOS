import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

/// Настройка пулов стартовых номеров (BIB).
class BibPoolScreen extends ConsumerWidget {
  const BibPoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;
    final pools = config.bibPools;

    // Total capacity
    final totalCapacity = pools.fold<int>(0, (sum, p) => sum + p.capacity);

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Стартовые номера (BIB)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPool(context, ref, disciplines, pools.length),
          ),
        ],
      ),
      body: pools.isEmpty
          ? _emptyState(context, ref, cs, disciplines)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.confirmation_number, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${pools.length} пулов · $totalCapacity номеров',
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                      Text(_rangeOverview(pools), style: TextStyle(fontSize: 12, color: cs.outline)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 16),

                // Pool cards
                ...pools.asMap().entries.map((entry) {
                  final i = entry.key;
                  final pool = entry.value;
                  final disc = disciplines.where((d) => d.id == pool.disciplineId).firstOrNull;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PoolCard(
                      pool: pool,
                      discipline: disc,
                      cs: cs,
                      onEdit: () => _editPool(context, ref, pool, disciplines),
                      onDelete: () {
                        final updated = List<BibPool>.from(pools)..removeAt(i);
                        ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: updated));
                      },
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Add button
                OutlinedButton.icon(
                  onPressed: () => _addPool(context, ref, disciplines, pools.length),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить пул'),
                ),

                const SizedBox(height: 16),

                // Quick setup
                if (pools.isEmpty || pools.length < disciplines.length)
                  FilledButton.tonal(
                    onPressed: () => _autoSetup(ref, disciplines),
                    child: const Text('⚡ Автонастройка по дисциплинам'),
                  ),
              ],
            ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, ColorScheme cs, List<DisciplineConfig> disciplines) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.confirmation_number_outlined, size: 64, color: cs.outline),
        const SizedBox(height: 16),
        Text('Стартовые номера не настроены', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text('Создайте пулы номеров для каждой дисциплины или один общий пул.',
          style: TextStyle(color: cs.outline), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _autoSetup(ref, disciplines),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Автонастройка'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _addPool(context, ref, disciplines, 0),
          icon: const Icon(Icons.add),
          label: const Text('Добавить вручную'),
        ),
      ]),
    ));
  }

  void _autoSetup(WidgetRef ref, List<DisciplineConfig> disciplines) {
    final pools = <BibPool>[];
    for (var i = 0; i < disciplines.length; i++) {
      final d = disciplines[i];
      final start = i * 100 + 1;
      final end = (i + 1) * 100;
      pools.add(BibPool(
        id: 'bib-${d.id}',
        label: d.name,
        rangeStart: start,
        rangeEnd: end,
        disciplineId: d.id,
      ));
    }
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: pools));
  }

  void _addPool(BuildContext context, WidgetRef ref, List<DisciplineConfig> disciplines, int index) {
    final nextStart = index * 100 + 1;
    final pool = BibPool(
      id: 'bib-new-${DateTime.now().millisecondsSinceEpoch}',
      label: 'Пул ${index + 1}',
      rangeStart: nextStart,
      rangeEnd: nextStart + 99,
    );
    _editPool(context, ref, pool, disciplines, isNew: true);
  }

  void _editPool(BuildContext context, WidgetRef ref, BibPool pool, List<DisciplineConfig> disciplines, {bool isNew = false}) {
    final labelCtrl = TextEditingController(text: pool.label);
    final startCtrl = TextEditingController(text: '${pool.rangeStart}');
    final endCtrl = TextEditingController(text: '${pool.rangeEnd}');
    String? selectedDisciplineId = pool.disciplineId;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: isNew ? 'Новый пул' : pool.label, child: StatefulBuilder(
      builder: (ctx, setModal) {
        final start = int.tryParse(startCtrl.text) ?? 1;
        final end = int.tryParse(endCtrl.text) ?? 100;
        final capacity = (end - start + 1).clamp(0, 9999);

        return Column(mainAxisSize: MainAxisSize.min, children: [
          // Label
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
          ),
          const SizedBox(height: 12),

          // Range
          Row(children: [
            Expanded(child: TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'От', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (_) => setModal(() {}),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: TextStyle(fontSize: 20, color: cs.outline)),
            ),
            Expanded(child: TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'До', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (_) => setModal(() {}),
            )),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$capacity шт', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
            ),
          ]),
          const SizedBox(height: 12),

          // Discipline link
          DropdownButtonFormField<String?>(
            value: selectedDisciplineId,
            decoration: const InputDecoration(
              labelText: 'Привязка к дисциплине',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Общий пул')),
              ...disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
            ],
            onChanged: (v) => setModal(() => selectedDisciplineId = v),
          ),
          const SizedBox(height: 16),

          // Save
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () {
              final updated = BibPool(
                id: pool.id,
                label: labelCtrl.text.trim(),
                rangeStart: int.tryParse(startCtrl.text) ?? 1,
                rangeEnd: int.tryParse(endCtrl.text) ?? 100,
                disciplineId: selectedDisciplineId,
              );
              final config = ref.read(eventConfigProvider);
              final pools = List<BibPool>.from(config.bibPools);
              if (isNew) {
                pools.add(updated);
              } else {
                final idx = pools.indexWhere((p) => p.id == pool.id);
                if (idx >= 0) pools[idx] = updated;
              }
              ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: pools));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
          )),
          const SizedBox(height: 8),
        ]);
      },
    ));
  }

  String _rangeOverview(List<BibPool> pools) {
    if (pools.isEmpty) return '';
    return pools.map((p) => '${p.rangeStart}–${p.rangeEnd}').join(', ');
  }
}

// ─── Pool Card ───

class _PoolCard extends StatelessWidget {
  final BibPool pool;
  final DisciplineConfig? discipline;
  final ColorScheme cs;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PoolCard({
    required this.pool,
    this.discipline,
    required this.cs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: EdgeInsets.zero, children: [
      ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            '${pool.rangeStart}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onPrimaryContainer),
          )),
        ),
        title: Text(pool.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(children: [
          Text('${pool.rangeStart} – ${pool.rangeEnd}', style: TextStyle(fontSize: 12, color: cs.outline)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${pool.capacity} шт',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onTertiaryContainer)),
          ),
          if (discipline != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.sports, size: 12, color: cs.outline),
            const SizedBox(width: 2),
            Flexible(child: Text(discipline!.name,
              style: TextStyle(fontSize: 10, color: cs.outline),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.edit, size: 18, color: cs.outline), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline, size: 18, color: cs.error), onPressed: onDelete),
        ]),
        onTap: onEdit,
      ),
    ]);
  }
}

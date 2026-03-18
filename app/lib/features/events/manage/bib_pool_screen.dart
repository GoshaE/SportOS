import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

// Sport colors for pools
const _poolColors = [
  Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFE65100),
  Color(0xFF6A1B9A), Color(0xFFC62828), Color(0xFF00838F), Color(0xFF4E342E),
];

/// Настройка пулов стартовых номеров (BIB) — redesigned.
///
/// Визуальная шкала номеров, умная автонастройка, inline-редактирование,
/// цветовое кодирование, проверка пересечений.
class BibPoolScreen extends ConsumerWidget {
  const BibPoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;
    final pools = config.bibPools;
    final totalCapacity = pools.fold<int>(0, (sum, p) => sum + p.capacity);
    final overlaps = _findOverlaps(pools);

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Стартовые номера (BIB)'),
        actions: [
          if (pools.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Авто по дисциплинам',
              onPressed: () => _smartAutoSetup(ref, disciplines, context),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить пул',
            onPressed: () => _addPool(context, ref, disciplines, pools),
          ),
        ],
      ),
      body: pools.isEmpty
          ? _emptyState(context, ref, cs, disciplines)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Visual Range Bar ───
                _BibRangeBar(pools: pools, cs: cs, overlaps: overlaps),
                const SizedBox(height: 16),

                // ─── Overlap warning ───
                if (overlaps.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber, color: cs.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Пересечение номеров: ${overlaps.map((o) => '${o.$1} ∩ ${o.$2}').join(', ')}',
                        style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── Summary ───
                Row(children: [
                  _summaryChip(cs, Icons.confirmation_number, '${pools.length} пулов'),
                  const SizedBox(width: 8),
                  _summaryChip(cs, Icons.tag, '$totalCapacity номеров'),
                  const SizedBox(width: 8),
                  if (overlaps.isEmpty)
                    _summaryChip(cs, Icons.check_circle, 'Нет пересечений', isGood: true),
                ]),
                const SizedBox(height: 16),

                // ─── Pool cards ───
                ...pools.asMap().entries.map((entry) {
                  final i = entry.key;
                  final pool = entry.value;
                  final disc = disciplines.where((d) => d.id == pool.disciplineId).firstOrNull;
                  final color = _poolColors[i % _poolColors.length];
                  final hasOverlap = overlaps.any((o) => o.$1 == pool.label || o.$2 == pool.label);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PoolCard(
                      pool: pool,
                      discipline: disc,
                      color: color,
                      cs: cs,
                      hasOverlap: hasOverlap,
                      onRangeChanged: (start, end) {
                        final updated = List<BibPool>.from(pools);
                        updated[i] = pool.copyWith(rangeStart: start, rangeEnd: end);
                        ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: updated));
                      },
                      onEdit: () => _editPool(context, ref, pool, disciplines),
                      onDelete: () {
                        final updated = List<BibPool>.from(pools)..removeAt(i);
                        ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: updated));
                      },
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // ─── Add button ───
                OutlinedButton.icon(
                  onPressed: () => _addPool(context, ref, disciplines, pools),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить пул'),
                ),
              ],
            ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, ColorScheme cs, List<DisciplineConfig> disciplines) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.confirmation_number_outlined, size: 40, color: cs.primary),
        ),
        const SizedBox(height: 20),
        Text('Стартовые номера', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Создайте пулы номеров для каждой дисциплины.\n'
          'Автонастройка подберёт диапазоны по кол-ву участников.',
          style: TextStyle(color: cs.outline, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => _smartAutoSetup(ref, disciplines, context),
          icon: const Icon(Icons.auto_fix_high),
          label: Text('Авто для ${disciplines.length} дисциплин'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _addPool(context, ref, disciplines, []),
          icon: const Icon(Icons.add),
          label: const Text('Вручную'),
        ),
      ]),
    ));
  }

  Widget _summaryChip(ColorScheme cs, IconData icon, String text, {bool isGood = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFF2E7D32).withValues(alpha: 0.08) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: isGood ? const Color(0xFF2E7D32) : cs.outline),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: isGood ? const Color(0xFF2E7D32) : cs.onSurface)),
      ]),
    );
  }

  // ─── Smart auto-setup ───
  void _smartAutoSetup(WidgetRef ref, List<DisciplineConfig> disciplines, BuildContext context) {
    final pools = <BibPool>[];
    var nextStart = 1;
    for (final d in disciplines) {
      // Base on maxParticipants or 30 default, +20% buffer, round to nearest 10
      final base = d.maxParticipants ?? 30;
      final withBuffer = (base * 1.2).ceil();
      final rounded = ((withBuffer + 9) ~/ 10) * 10; // round up to 10
      final end = nextStart + rounded - 1;

      pools.add(BibPool(
        id: 'bib-${d.id}',
        label: d.name,
        rangeStart: nextStart,
        rangeEnd: end,
        disciplineId: d.id,
      ));
      nextStart = end + 1;
    }
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibPools: pools));
    AppSnackBar.success(context, '${pools.length} пулов создано (${pools.fold<int>(0, (s, p) => s + p.capacity)} номеров)');
  }

  void _addPool(BuildContext context, WidgetRef ref, List<DisciplineConfig> disciplines, List<BibPool> existing) {
    final nextStart = existing.isEmpty ? 1 : existing.map((p) => p.rangeEnd).reduce(max) + 1;
    final pool = BibPool(
      id: 'bib-new-${DateTime.now().millisecondsSinceEpoch}',
      label: 'Пул ${existing.length + 1}',
      rangeStart: nextStart,
      rangeEnd: nextStart + 29,
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
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)),
          ),
          const SizedBox(height: 12),
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
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text('$capacity', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: selectedDisciplineId,
            decoration: const InputDecoration(labelText: 'Дисциплина', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sports)),
            items: [
              const DropdownMenuItem(value: null, child: Text('Общий пул')),
              ...disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
            ],
            onChanged: (v) => setModal(() => selectedDisciplineId = v),
          ),
          const SizedBox(height: 16),
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

  List<(String, String)> _findOverlaps(List<BibPool> pools) {
    final overlaps = <(String, String)>[];
    for (var i = 0; i < pools.length; i++) {
      for (var j = i + 1; j < pools.length; j++) {
        final a = pools[i], b = pools[j];
        if (a.rangeStart <= b.rangeEnd && b.rangeStart <= a.rangeEnd) {
          overlaps.add((a.label, b.label));
        }
      }
    }
    return overlaps;
  }
}

// ─── Visual Range Bar ───

class _BibRangeBar extends StatelessWidget {
  final List<BibPool> pools;
  final ColorScheme cs;
  final List<(String, String)> overlaps;

  const _BibRangeBar({required this.pools, required this.cs, required this.overlaps});

  @override
  Widget build(BuildContext context) {
    if (pools.isEmpty) return const SizedBox();

    final globalMin = pools.map((p) => p.rangeStart).reduce(min);
    final globalMax = pools.map((p) => p.rangeEnd).reduce(max);
    final totalRange = (globalMax - globalMin + 1).clamp(1, 99999);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Title
      Row(children: [
        Icon(Icons.linear_scale, size: 14, color: cs.primary),
        const SizedBox(width: 6),
        Text('Шкала номеров', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
        const Spacer(),
        Text('$globalMin – $globalMax', style: TextStyle(fontSize: 11, color: cs.outline)),
      ]),
      const SizedBox(height: 8),

      // Bar
      Container(
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(children: [
            ...pools.asMap().entries.map((entry) {
              final i = entry.key;
              final pool = entry.value;
              final color = _poolColors[i % _poolColors.length];
              final left = ((pool.rangeStart - globalMin) / totalRange) * width;
              final barWidth = ((pool.capacity) / totalRange * width).clamp(2.0, width);

              return Positioned(
                left: left,
                top: 4,
                bottom: 4,
                width: barWidth,
                child: Tooltip(
                  message: '${pool.label}: ${pool.rangeStart}–${pool.rangeEnd} (${pool.capacity} шт)',
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: overlaps.any((o) => o.$1 == pool.label || o.$2 == pool.label)
                          ? Border.all(color: cs.error, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: barWidth > 30
                        ? Text(
                            '${pool.rangeStart}–${pool.rangeEnd}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          )
                        : null,
                  ),
                ),
              );
            }),
          ]);
        }),
      ),
    ]);
  }
}

// ─── Pool Card ───

class _PoolCard extends StatelessWidget {
  final BibPool pool;
  final DisciplineConfig? discipline;
  final Color color;
  final ColorScheme cs;
  final bool hasOverlap;
  final void Function(int start, int end) onRangeChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PoolCard({
    required this.pool,
    this.discipline,
    required this.color,
    required this.cs,
    required this.hasOverlap,
    required this.onRangeChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasOverlap ? cs.error.withValues(alpha: 0.5) : color.withValues(alpha: 0.3),
          width: hasOverlap ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        // Header with color accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(children: [
            // Color dot
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            // Label
            Expanded(child: Text(pool.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface))),
            // Discipline badge
            if (discipline != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sports, size: 11, color: color),
                  const SizedBox(width: 3),
                  Text(discipline!.name, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            if (hasOverlap) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber, size: 16, color: cs.error),
            ],
          ]),
        ),

        // Range with inline steppers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            // Start range
            _RangeStepper(
              label: 'От',
              value: pool.rangeStart,
              color: color,
              cs: cs,
              onChanged: (v) => onRangeChanged(v, pool.rangeEnd),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16, color: cs.outline),
            ),
            // End range
            _RangeStepper(
              label: 'До',
              value: pool.rangeEnd,
              color: color,
              cs: cs,
              onChanged: (v) => onRangeChanged(pool.rangeStart, v),
            ),
            const Spacer(),
            // Capacity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pool.capacity} шт',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: cs.outline),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Range Stepper ───

class _RangeStepper extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ColorScheme cs;
  final ValueChanged<int> onChanged;

  const _RangeStepper({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 9, color: cs.outline)),
      const SizedBox(height: 2),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _stepBtn(Icons.remove, () => onChanged((value - 1).clamp(1, 9999))),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
        _stepBtn(Icons.add, () => onChanged((value + 1).clamp(1, 9999))),
      ]),
    ]);
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

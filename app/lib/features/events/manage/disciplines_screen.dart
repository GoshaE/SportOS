import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/timing/models.dart';

/// Screen ID: E2 — Дисциплины (typed models from Config Engine)
class DisciplinesScreen extends ConsumerWidget {
  const DisciplinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final courses = ref.watch(coursesProvider);
    final cs = Theme.of(context).colorScheme;

    // Group disciplines by sport type (inferred from template name)
    final grouped = <String, List<DisciplineConfig>>{};
    for (final d in disciplines) {
      final sport = _inferSport(d.name);
      grouped.putIfAbsent(sport, () => []).add(d);
    }

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Дисциплины'),
        actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Добавить', onPressed: () {})],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        // Sport chips summary
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
                Text(info.label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: info.color)),
              ]),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              children: [
                Column(
                  children: items.map((d) {
                    final totalKm = d.totalDistanceKm.toStringAsFixed(3);
                    final startLabel = _startTypeLabel(d);
                    final course = courses.where((c) => c.id == d.courseId).firstOrNull;

                    return Column(children: [
                      InkWell(
                        onTap: () => _showEditDiscipline(context, ref, d),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + Price
                              Row(children: [
                                Expanded(child: Text(
                                  '${d.name} $totalKm км',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                )),
                                if (d.priceRub != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: info.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${d.priceRub}₽',
                                      style: TextStyle(fontSize: 13, color: info.color, fontWeight: FontWeight.bold)),
                                  ),
                              ]),
                              const SizedBox(height: 8),

                              // Distance formula
                              Text(
                                d.lapLengthM != null
                                    ? 'Круг ${d.lapLengthM}м × ${d.laps} = $totalKm км'
                                    : '$totalKm км',
                                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),

                              // Start type + cutoff + course
                              Row(children: [
                                Icon(
                                  d.startType == StartType.individual ? Icons.person : Icons.groups,
                                  size: 16, color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(startLabel, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                if (d.cutoffTime != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.timer, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('Cutoff: ${_formatDuration(d.cutoffTime!)}',
                                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                ],
                              ]),

                              // Course info
                              if (course != null) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.route, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('Трасса: ${course.name}',
                                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                  if (course.checkpoints.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text('(${course.checkpoints.length} КП)',
                                      style: TextStyle(fontSize: 12, color: cs.primary)),
                                  ],
                                ]),
                              ],

                              // Day badge
                              if (d.dayNumber != null) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('День ${d.dayNumber}',
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                ]),
                              ],

                              const SizedBox(height: 12),

                              // Categories
                              Wrap(spacing: 6, runSpacing: 6, children: d.categories.map((c) =>
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(c, style: const TextStyle(fontSize: 11)),
                                ),
                              ).toList()),
                            ],
                          ),
                        ),
                      ),
                      if (d != items.last) const Divider(height: 1, indent: 16),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          ];
        }),
      ]),
    );
  }

  // ── Edit discipline bottom sheet ──

  void _showEditDiscipline(BuildContext context, WidgetRef ref, DisciplineConfig d) {
    final lapCtrl = TextEditingController(text: '${d.lapLengthM ?? (d.distanceKm * 1000).toInt()}');
    final lapsCtrl = TextEditingController(text: '${d.laps}');
    final cutoffCtrl = TextEditingController(text: d.cutoffTime != null ? _formatDuration(d.cutoffTime!) : '');
    final priceCtrl = TextEditingController(text: '${d.priceRub ?? 0}');
    final intervalCtrl = TextEditingController(text: '${d.interval.inSeconds}');
    String startTypeStr = d.startType.name;
    Set<String> cats = Set<String>.from(d.categories);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: d.name, initialHeight: 0.85, child: StatefulBuilder(
      builder: (ctx, setModal) {
        final lapM = int.tryParse(lapCtrl.text) ?? 0;
        final laps = int.tryParse(lapsCtrl.text) ?? 0;
        final totalKm = (lapM * laps / 1000.0).toStringAsFixed(3);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Distance calculator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: lapCtrl,
                  decoration: const InputDecoration(labelText: 'Круг (м)', border: OutlineInputBorder(), isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                )),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                Expanded(child: TextField(
                  controller: lapsCtrl,
                  decoration: const InputDecoration(labelText: 'Кругов', border: OutlineInputBorder(), isDense: true),
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
          const SizedBox(height: 12),

          // Start type
          const Text('Тип старта:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'individual', label: Text('Раздельный'), icon: Icon(Icons.person, size: 16)),
              ButtonSegment(value: 'mass', label: Text('Масс-старт'), icon: Icon(Icons.groups, size: 16)),
              ButtonSegment(value: 'wave', label: Text('Волна'), icon: Icon(Icons.waves, size: 16)),
            ],
            selected: {startTypeStr},
            onSelectionChanged: (s) => setModal(() => startTypeStr = s.first),
          ),
          if (startTypeStr == 'individual') ...[
            const SizedBox(height: 8),
            TextField(
              controller: intervalCtrl,
              decoration: const InputDecoration(labelText: 'Интервал (сек)', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 12),

          // Cutoff + Price
          Row(children: [
            Expanded(child: TextField(controller: cutoffCtrl, decoration: const InputDecoration(labelText: 'Cutoff', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Цена ₽', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),

          // Categories
          const Text('Категории:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Гендерные:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Wrap(spacing: 4, children: ['М', 'Ж', 'Юн', 'Юнк', 'Дети'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          Text('Возрастные:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Wrap(spacing: 4, children: ['M35', 'M40', 'M45', 'M50', 'M55', 'M60+', 'F35', 'F40', 'F45', 'F50+', 'Вет'].map((c) => FilterChip(
            label: Text(c, style: const TextStyle(fontSize: 12)),
            selected: cats.contains(c),
            onSelected: (v) => setModal(() { if (v) { cats.add(c); } else { cats.remove(c); } }),
            visualDensity: VisualDensity.compact,
          )).toList()),
          const SizedBox(height: 16),

          // Save button
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () {
              final newLapM = int.tryParse(lapCtrl.text) ?? d.lapLengthM ?? (d.distanceKm * 1000).toInt();
              final newLaps = int.tryParse(lapsCtrl.text) ?? d.laps;
              final newInterval = int.tryParse(intervalCtrl.text) ?? d.interval.inSeconds;
              final newPrice = int.tryParse(priceCtrl.text);
              final st = StartType.values.firstWhere((e) => e.name == startTypeStr, orElse: () => d.startType);

              ref.read(eventConfigProvider.notifier).updateDiscipline(d.id, (old) => old.copyWith(
                lapLengthM: newLapM,
                distanceKm: newLapM * newLaps / 1000.0,
                laps: newLaps,
                startType: st,
                interval: Duration(seconds: newInterval),
                priceRub: newPrice,
                categories: cats.toList(),
              ));

              Navigator.pop(ctx);
              AppSnackBar.success(context, 'Дисциплина обновлена');
            },
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
          )),
        ]);
      },
    ));
  }

  // ── Helpers ──

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
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _SportInfo {
  final String icon;
  final String label;
  final Color color;
  const _SportInfo(this.icon, this.label, this.color);
}

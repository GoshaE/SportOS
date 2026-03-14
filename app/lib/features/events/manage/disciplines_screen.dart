import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E2 — Дисциплины (с системой шаблонов, круг × кругов = дистанция)
class DisciplinesScreen extends StatefulWidget {
  const DisciplinesScreen({super.key});

  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  final List<Map<String, dynamic>> _disciplines = [
    {'template': 'Скиджоринг (1 соб.)', 'sport': 'sled', 'sportIcon': '🐕', 'sportColor': 0xFF1565C0, 'lapM': 3000, 'laps': 2, 'startType': 'individual', 'interval': 30, 'cutoff': '2:00:00', 'price': 2500, 'categories': {'М', 'Ж', 'Юн', 'Юнк', 'M35', 'M40'}},
    {'template': 'Скиджоринг (1 соб.)', 'sport': 'sled', 'sportIcon': '🐕', 'sportColor': 0xFF1565C0, 'lapM': 5000, 'laps': 4, 'startType': 'individual', 'interval': 60, 'cutoff': '4:00:00', 'price': 3500, 'categories': {'М', 'Ж', 'M35', 'F35'}},
    {'template': 'Скиджоринг (2 соб.)', 'sport': 'sled', 'sportIcon': '🐕', 'sportColor': 0xFF1565C0, 'lapM': 5000, 'laps': 8, 'startType': 'individual', 'interval': 90, 'cutoff': '6:00:00', 'price': 4000, 'categories': {'М', 'Ж'}},
    {'template': 'Нарты (2 соб.)', 'sport': 'sled', 'sportIcon': '🐕', 'sportColor': 0xFF1565C0, 'lapM': 5000, 'laps': 3, 'startType': 'individual', 'interval': 90, 'cutoff': '4:00:00', 'price': 3000, 'categories': {'М', 'Ж', 'Юн', 'Юнк'}},
    {'template': 'Каникросс', 'sport': 'canicross', 'sportIcon': '🏃🐕', 'sportColor': 0xFF2E7D32, 'lapM': 3000, 'laps': 1, 'startType': 'mass', 'interval': 0, 'cutoff': '1:00:00', 'price': 1500, 'categories': {'М', 'Ж', 'Дети', 'M40', 'F40'}},
    {'template': 'Трейл (до 21 км)', 'sport': 'trail', 'sportIcon': '🏔', 'sportColor': 0xFFE65100, 'lapM': 10000, 'laps': 1, 'startType': 'mass', 'interval': 0, 'cutoff': '3:00:00', 'price': 2000, 'categories': {'М', 'Ж', 'M35', 'F35'}},
  ];

  void _showEditDiscipline(int index) {
    final d = _disciplines[index];
    final lapCtrl = TextEditingController(text: '${d['lapM']}');
    final lapsCtrl = TextEditingController(text: '${d['laps']}');
    final cutoffCtrl = TextEditingController(text: d['cutoff']);
    final priceCtrl = TextEditingController(text: '${d['price']}');
    final intervalCtrl = TextEditingController(text: '${d['interval']}');
    String startType = d['startType'];
    Set<String> cats = Set<String>.from(d['categories']);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: d['template'], initialHeight: 0.85, child: StatefulBuilder(builder: (ctx, setModal) {
      final lapM = int.tryParse(lapCtrl.text) ?? 0;
      final laps = int.tryParse(lapsCtrl.text) ?? 0;
      final totalKm = (lapM * laps / 1000.0).toStringAsFixed(3);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: lapCtrl, decoration: const InputDecoration(labelText: 'Круг (м)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setModal(() {}))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Expanded(child: TextField(controller: lapsCtrl, decoration: const InputDecoration(labelText: 'Кругов', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setModal(() {}))),
            ]),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('= $totalKm км', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Тип старта:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'individual', label: Text('Раздельный'), icon: Icon(Icons.person, size: 16)),
            ButtonSegment(value: 'mass', label: Text('Масс-старт'), icon: Icon(Icons.groups, size: 16)),
            ButtonSegment(value: 'wave', label: Text('Волна'), icon: Icon(Icons.waves, size: 16)),
          ],
          selected: {startType}, onSelectionChanged: (s) => setModal(() => startType = s.first),
        ),
        if (startType == 'individual') ...[
          const SizedBox(height: 8),
          TextField(controller: intervalCtrl, decoration: const InputDecoration(labelText: 'Интервал (сек)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: cutoffCtrl, decoration: const InputDecoration(labelText: 'Cutoff', border: OutlineInputBorder(), isDense: true))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Цена ₽', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        const Text('Категории:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Гендерные:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Wrap(spacing: 4, children: ['М', 'Ж', 'Юн', 'Юнк', 'Дети'].map((c) => FilterChip(
          label: Text(c, style: const TextStyle(fontSize: 12)), selected: cats.contains(c),
          onSelected: (v) => setModal(() { if (v) {
            cats.add(c);
          } else {
            cats.remove(c);
          } }), visualDensity: VisualDensity.compact,
        )).toList()),
        Text('Возрастные:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Wrap(spacing: 4, children: ['M35', 'M40', 'M45', 'M50', 'M55', 'M60+', 'F35', 'F40', 'F45', 'F50+', 'Вет'].map((c) => FilterChip(
          label: Text(c, style: const TextStyle(fontSize: 12)), selected: cats.contains(c),
          onSelected: (v) => setModal(() { if (v) {
            cats.add(c);
          } else {
            cats.remove(c);
          } }), visualDensity: VisualDensity.compact,
        )).toList()),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            setState(() {
              d['lapM'] = int.tryParse(lapCtrl.text) ?? d['lapM'];
              d['laps'] = int.tryParse(lapsCtrl.text) ?? d['laps'];
              d['startType'] = startType;
              d['interval'] = int.tryParse(intervalCtrl.text) ?? d['interval'];
              d['cutoff'] = cutoffCtrl.text;
              d['price'] = int.tryParse(priceCtrl.text) ?? d['price'];
              d['categories'] = cats;
            });
            Navigator.pop(ctx);
            AppSnackBar.success(context, 'Дисциплина обновлена');
          },
          icon: const Icon(Icons.save), label: const Text('Сохранить'),
        )),
      ]);
    }));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final grouped = <String, List<MapEntry<int, Map<String, dynamic>>>>{};
    for (int i = 0; i < _disciplines.length; i++) {
      final sport = _disciplines[i]['sport'] as String;
      grouped.putIfAbsent(sport, () => []).add(MapEntry(i, _disciplines[i]));
    }

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Дисциплины'),
        actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Добавить', onPressed: () {})],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Wrap(spacing: 6, runSpacing: 4, children: grouped.entries.map((e) {
          final first = e.value.first.value;
          final color = Color(first['sportColor'] as int);
          return Chip(
            avatar: Text(first['sportIcon']),
            label: Text('${e.key == 'sled' ? 'Ездовой' : e.key == 'canicross' ? 'Каникросс' : 'Трейл'} (${e.value.length})'),
            backgroundColor: color.withValues(alpha: 0.1),
          );
        }).toList()),
        const SizedBox(height: 8),
        ...grouped.entries.expand((entry) {
          final items = entry.value;
          final first = items.first.value;
          final sportColor = Color(first['sportColor'] as int);
          return [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Row(children: [
                Text(first['sportIcon'], style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(first['sport'] == 'sled' ? 'Ездовой спорт' : first['sport'] == 'canicross' ? 'Каникросс' : 'Трейл',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sportColor)),
              ]),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              children: [
                Column(
                  children: items.map((me) {
                    final d = me.value;
                    final idx = me.key;
                    final lapM = d['lapM'] as int;
                    final laps = d['laps'] as int;
                    final totalKm = (lapM * laps / 1000.0).toStringAsFixed(3);
                    final startLabel = d['startType'] == 'individual' ? 'Разд. ${d['interval']}с' : d['startType'] == 'mass' ? 'Масс-старт' : 'Волна';
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _showEditDiscipline(idx),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text('${d['template']} $totalKm км', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: sportColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${d['price']}₽', style: TextStyle(fontSize: 13, color: sportColor, fontWeight: FontWeight.bold)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Text('Круг $lapMм × $laps = $totalKm км', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(d['startType'] == 'individual' ? Icons.person : Icons.groups, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(startLabel, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.timer, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('Cutoff: ${d['cutoff']}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                ]),
                                const SizedBox(height: 12),
                                Wrap(spacing: 6, runSpacing: 6, children: (d['categories'] as Set<String>).map((c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6)),
                                  child: Text(c, style: const TextStyle(fontSize: 11)),
                                )).toList()),
                              ],
                            ),
                          ),
                        ),
                        if (me.key != items.last.key) const Divider(height: 1, indent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ];
        }),
      ]),
    );
  }
}

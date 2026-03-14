import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P2 — Стартовый лист
class StartListScreen extends StatefulWidget {
  const StartListScreen({super.key});

  @override
  State<StartListScreen> createState() => _StartListScreenState();
}

class _StartListScreenState extends State<StartListScreen> {
  String _disc = 'Скидж. 5км';
  String _interval = '30с';
  String _firstStart = '10:00:00';
  bool _isTableView = false;
  bool _initialized = false;

  final List<Map<String, dynamic>> _startList = [
    {'pos': 1, 'bib': '07', 'name': 'Петров А.А.', 'dog': 'Rex', 'time': '10:00:00', 'status': 'confirmed'},
    {'pos': 2, 'bib': '24', 'name': 'Иванов В.В.', 'dog': 'Storm', 'time': '10:00:30', 'status': 'confirmed'},
    {'pos': 3, 'bib': '55', 'name': 'Волкова Е.Е.', 'dog': 'Alaska', 'time': '10:01:00', 'status': 'confirmed'},
    {'pos': 4, 'bib': '12', 'name': 'Сидоров Б.Б.', 'dog': 'Luna', 'time': '10:01:30', 'status': 'confirmed'},
    {'pos': 5, 'bib': '31', 'name': 'Козлов Г.Г.', 'dog': 'Wolf', 'time': '10:02:00', 'status': 'confirmed'},
    {'pos': 6, 'bib': '77', 'name': 'Новикова З.З.', 'dog': 'Rocky', 'time': '10:02:30', 'status': 'confirmed'},
    {'pos': 7, 'bib': '42', 'name': 'Морозов Д.Д.', 'dog': 'Buddy', 'time': '10:03:00', 'status': 'confirmed'},
    {'pos': 8, 'bib': '63', 'name': 'Лебедев Ж.Ж.', 'dog': 'Max', 'time': '10:03:30', 'status': 'confirmed'},
  ];

  final List<String> _usedBibs = ['07', '12', '24', '31', '42', '55', '63', '77'];
  final List<String> _freeBibs = ['01', '02', '03', '04', '05', '06', '08', '09', '10', '11', '13', '14'];

  void _showAddLateAthlete() {
    final nameCtrl = TextEditingController();
    final dogCtrl = TextEditingController();
    String? selectedBib;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'Добавить спортсмена в день старта', child: StatefulBuilder(builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Спортсмен будет добавлен в конец стартового списка', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      const SizedBox(height: 12),
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: dogCtrl, decoration: const InputDecoration(labelText: 'Кличка собаки *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      const Align(alignment: Alignment.centerLeft, child: Text('Свободные номера:', style: TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(height: 4),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: _freeBibs.map((bib) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(label: Text(bib, style: TextStyle(fontWeight: FontWeight.bold, color: selectedBib == bib ? cs.onPrimary : cs.primary)),
          selected: selectedBib == bib, onSelected: (s) => setModal(() => selectedBib = s ? bib : null)),
      )).toList())),
      const SizedBox(height: 4),
      Text('Занято: ${_usedBibs.join(", ")}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
      const SizedBox(height: 12),
      AppInfoBanner.info(title: 'Позиция: ${_startList.length + 1} (в конец списка). Время старта: рассчитается от последнего + интервал'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () {
          if (nameCtrl.text.isEmpty || selectedBib == null) { AppSnackBar.error(context, 'Заполните ФИО и выберите BIB'); return; }
          final lastTime = _startList.last['time'] as String;
          final parts = lastTime.split(':');
          final newSec = int.parse(parts[2]) + 30;
          final newMin = int.parse(parts[1]) + newSec ~/ 60;
          final newTime = '${parts[0]}:${(newMin % 60).toString().padLeft(2, '0')}:${(newSec % 60).toString().padLeft(2, '0')}';
          setState(() {
            _startList.add({'pos': _startList.length + 1, 'bib': selectedBib, 'name': nameCtrl.text, 'dog': dogCtrl.text, 'time': newTime, 'status': 'late_add'});
            _usedBibs.add(selectedBib!); _freeBibs.remove(selectedBib);
          });
          Navigator.pop(ctx);
          AppSnackBar.success(context, '${nameCtrl.text} (BIB $selectedBib) добавлен');
        },
        icon: const Icon(Icons.add), label: const Text('Добавить в конец списка'),
      )),
    ])));
  }

  void _showEditRow(int index) {
    final a = _startList[index];
    final posCtrl = TextEditingController(text: '${a['pos']}');
    final timeCtrl = TextEditingController(text: a['time']);
    final bibCtrl = TextEditingController(text: a['bib']);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: '${a['name']} (BIB ${a['bib']})',
      initialHeight: 0.6,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            setState(() { 
              a['pos'] = int.tryParse(posCtrl.text) ?? a['pos']; 
              a['bib'] = bibCtrl.text; 
              a['time'] = timeCtrl.text; 
              _startList.sort((ca, cb) => (ca['pos'] as int).compareTo(cb['pos'] as int)); 
            });
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Стартовый лист скорректирован');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Позиция', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: bibCtrl, decoration: const InputDecoration(labelText: 'BIB', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Время старта', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Причина коррекции', border: OutlineInputBorder(), hintText: 'Ошибка при жеребьёвке...'), maxLines: 2),
            ]
          ),
          const SizedBox(height: 12),
          Text('Изменение будет записано в Audit Log', style: TextStyle(color: cs.tertiary, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;

    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }


    return Scaffold(
      appBar: AppAppBar(title: const Text('Стартовый лист'), actions: [
        IconButton(icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows), tooltip: 'Вид таблицы', onPressed: () => setState(() => _isTableView = !_isTableView)),
        IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Экспорт PDF', onPressed: () => AppSnackBar.info(context, 'PDF → Печать')),
        IconButton(icon: const Icon(Icons.share), tooltip: 'Поделиться', onPressed: () {}),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showAddLateAthlete, icon: const Icon(Icons.person_add), label: const Text('Добавить')),
      body: Column(children: [
        SizedBox(height: 40, child: AppDisciplineChips(
          items: const ['Скидж. 5км', 'Скидж. 10км', 'Каникросс', 'Нарты'],
          selected: _disc,
          onSelected: (v) => setState(() => _disc = v),
        )),
        Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Icon(Icons.timer, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Интервал:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            DropdownButton<String>(value: _interval, underline: const SizedBox(), isDense: true, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.bold),
              items: ['15с', '30с', '1 мин', '2 мин', '3 мин'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _interval = v!)),
            const SizedBox(width: 16),
            Icon(Icons.schedule, size: 16, color: cs.primary),
            const SizedBox(width: 4),
            const Text('Первый старт:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0)).then((t) { if (t != null) setState(() => _firstStart = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00'); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: cs.primary.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)),
                child: Text(_firstStart, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: AppProtocolTable(
              forceTableView: _isTableView,
              headerRow: AppProtocolRow(
                isHeader: true,
                bib: 'BIB',
                name: 'ФИО',
                cat: '',
                dog: 'Собака',
                time: 'Старт',
                delta: '—',
                penalty: '—',
              ),
              itemCount: _startList.length,
              itemBuilder: (context, index, isCard) {
                final a = _startList[index];
                final isLate = a['status'] == 'late_add';
                
                return AppProtocolRow(
                  isCardView: isCard,
                  place: a['pos'] as int,
                  bib: a['bib'] as String,
                  name: a['name'] as String,
                  cat: isLate ? 'ДОП. ЗАЯВКА' : '',
                  dog: a['dog'] as String,
                  time: a['time'] as String,
                  delta: '—',
                  penalty: '—',
                  onTap: () => _showEditRow(index),
                );
              },
            ),
          ),
        ),
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text('Всего: ${_startList.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Подтв.: ${_startList.where((a) => a['status'] == 'confirmed').length}', style: TextStyle(color: cs.primary)),
            Text('Доп.: ${_startList.where((a) => a['status'] == 'late_add').length}', style: TextStyle(color: cs.tertiary)),
          ]),
        ),
      ]),
    );
  }
}

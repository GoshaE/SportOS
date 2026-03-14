import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P6 — Чек-ин
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _filter = 'all';

  final List<Map<String, dynamic>> _checkins = [
    {'bib': '07', 'name': 'Петров А.А.', 'dog': 'Rex', 'checked': true, 'time': '09:15', 'paid': true, 'mandate': 'passed', 'vet': true, 'bib_assigned': true},
    {'bib': '12', 'name': 'Сидоров Б.Б.', 'dog': 'Luna', 'checked': true, 'time': '09:22', 'paid': true, 'mandate': 'passed', 'vet': true, 'bib_assigned': true},
    {'bib': '24', 'name': 'Иванов В.В.', 'dog': 'Storm', 'checked': true, 'time': '09:30', 'paid': true, 'mandate': 'passed', 'vet': false, 'bib_assigned': true},
    {'bib': '31', 'name': 'Козлов Г.Г.', 'dog': 'Wolf', 'checked': false, 'time': '—', 'paid': false, 'mandate': 'pending', 'vet': false, 'bib_assigned': true},
    {'bib': '42', 'name': 'Морозов Д.Д.', 'dog': 'Buddy', 'checked': false, 'time': '—', 'paid': true, 'mandate': 'failed', 'vet': true, 'bib_assigned': false},
    {'bib': '55', 'name': 'Волков Е.Е.', 'dog': 'Alaska', 'checked': true, 'time': '09:45', 'paid': true, 'mandate': 'passed', 'vet': true, 'bib_assigned': true},
    {'bib': '63', 'name': 'Лебедев Ж.Ж.', 'dog': 'Max', 'checked': false, 'time': '—', 'paid': true, 'mandate': 'pending', 'vet': true, 'bib_assigned': false},
    {'bib': '77', 'name': 'Новиков З.З.', 'dog': 'Rocky', 'checked': true, 'time': '09:50', 'paid': false, 'mandate': 'passed', 'vet': true, 'bib_assigned': true},
  ];

  int get _arrivedCount => _checkins.where((c) => c['checked'] == true).length;
  int get _waitingCount => _checkins.where((c) => c['checked'] == false).length;
  int get _unpaidCount => _checkins.where((c) => c['paid'] == false).length;
  int get _mandateIssues => _checkins.where((c) => c['mandate'] != 'passed').length;

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'arrived') return _checkins.where((c) => c['checked'] == true).toList();
    if (_filter == 'waiting') return _checkins.where((c) => c['checked'] == false).toList();
    return _checkins;
  }

  void _toggleCheckIn(int globalIndex) {
    setState(() {
      _checkins[globalIndex]['checked'] = !_checkins[globalIndex]['checked'];
      if (_checkins[globalIndex]['checked']) {
        _checkins[globalIndex]['time'] = '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';
      } else {
        _checkins[globalIndex]['time'] = '—';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Чек-ин'), actions: [
        if (_unpaidCount > 0) Badge(label: Text('$_unpaidCount'), backgroundColor: cs.error, child: IconButton(icon: Icon(Icons.payment, color: cs.error), tooltip: 'Неоплаченные', onPressed: () => setState(() => _filter = 'all'))),
        IconButton(icon: const Icon(Icons.nfc), tooltip: 'NFC Сканер', onPressed: () => AppSnackBar.info(context, 'NFC чек-ин — Фаза 2')),
      ]),
      body: Column(children: [
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Прибыли', '$_arrivedCount', cs.primary),
            _stat('Ожидаем', '$_waitingCount', cs.tertiary),
            _stat('Не оплач.', '$_unpaidCount', cs.error),
            _stat('Мандат', '$_mandateIssues', cs.secondary),
            _stat('Всего', '${_checkins.length}', cs.onSurface),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
          _filterChip(cs, 'Все', 'all'), const SizedBox(width: 6),
          _filterChip(cs, 'Прибыли', 'arrived'), const SizedBox(width: 6),
          _filterChip(cs, 'Ожидаем', 'waiting'), const Spacer(),
          Text('${_filtered.length} записей', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: TextField(decoration: InputDecoration(
          hintText: 'Поиск по BIB, ФИО, кличке...', prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true,
        ))),
        const SizedBox(height: 4),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: _filtered.length,
          itemBuilder: (ctx, i) {
            final c = _filtered[i];
            final globalIdx = _checkins.indexOf(c);
            final checked = c['checked'] as bool;
            final paid = c['paid'] as bool;
            final mandate = c['mandate'] as String;
            final vet = c['vet'] as bool;
            final bibAssigned = c['bib_assigned'] as bool;

            return Card(
              color: !paid ? cs.error.withValues(alpha: 0.03) : mandate == 'failed' ? cs.secondary.withValues(alpha: 0.03) : null,
              child: ListTile(
                leading: GestureDetector(
                  onTap: () => _toggleCheckIn(globalIdx),
                  child: Icon(checked ? Icons.check_circle : Icons.radio_button_unchecked, color: checked ? cs.primary : cs.onSurfaceVariant, size: 32),
                ),
                title: Row(children: [
                  Text(bibAssigned ? 'BIB ${c['bib']}' : 'No BIB', style: TextStyle(fontWeight: FontWeight.bold, color: bibAssigned ? null : cs.tertiary)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${c['name']} (${c['dog']})', style: const TextStyle(fontSize: 13))),
                ]),
                subtitle: Row(children: [
                  if (checked) Text(c['time'], style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  if (checked) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(paid ? Icons.payments : Icons.money_off, size: 16, color: paid ? cs.primary : cs.error),
                      const SizedBox(width: 6),
                      Icon(mandate == 'passed' ? Icons.health_and_safety : Icons.health_and_safety_outlined, size: 16, color: mandate == 'passed' ? cs.primary : mandate == 'failed' ? cs.error : cs.tertiary),
                      const SizedBox(width: 6),
                      Icon(vet ? Icons.pets : Icons.pets_outlined, size: 16, color: vet ? cs.primary : cs.tertiary),
                      const SizedBox(width: 6),
                      Icon(bibAssigned ? Icons.numbers : Icons.numbers_outlined, size: 16, color: bibAssigned ? cs.primary : cs.onSurfaceVariant),
                    ]),
                  ),
                ]),
                trailing: checked
                  ? Icon(Icons.check, color: cs.primary, size: 20)
                  : SizedBox(width: 70, height: 32, child: FilledButton(
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 12)),
                      onPressed: () => _toggleCheckIn(globalIdx), child: const Text('Чек-ин'),
                    )),
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 10, color: color)),
  ]);

  Widget _filterChip(ColorScheme cs, String label, String value) {
    final sel = _filter == value;
    return ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel ? cs.onPrimary : null)), selected: sel, onSelected: (_) => setState(() => _filter = value));
  }
}

import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P3 — Назначение BIB
class BibAssignScreen extends StatefulWidget {
  const BibAssignScreen({super.key});

  @override
  State<BibAssignScreen> createState() => _BibAssignScreenState();
}

class _BibAssignScreenState extends State<BibAssignScreen> {
  int _startBib = 1;
  String _searchQuery = '';
  String _selectedDisc = 'Все';
  String _filter = 'all';

  final List<Map<String, dynamic>> _athletes = [
    {'name': 'Петров А.А.', 'bib': '07', 'assigned': true, 'club': 'UralDogs', 'disc': 'Скиджоринг 5км', 'isLeader': false, 'personal': false},
    {'name': 'Сидоров Б.Б.', 'bib': '12', 'assigned': true, 'club': 'Лично', 'disc': 'Скиджоринг 5км', 'isLeader': true, 'personal': false},
    {'name': 'Иванов В.В.', 'bib': '99', 'assigned': true, 'club': 'HuskyTeam', 'disc': 'Скиджоринг 5км', 'isLeader': false, 'personal': true},
    {'name': 'Козлов Г.Г.', 'bib': '31', 'assigned': true, 'club': 'UralDogs', 'disc': 'Упряжки 2с', 'isLeader': false, 'personal': false},
    {'name': 'Морозов Д.Д.', 'bib': '', 'assigned': false, 'club': 'Лично', 'disc': 'Упряжки 4с', 'isLeader': false, 'personal': false},
    {'name': 'Волкова Е.Е.', 'bib': '', 'assigned': false, 'club': 'SnowTails', 'disc': 'Скиджоринг 5км', 'isLeader': false, 'personal': false},
    {'name': 'Лебедев Ж.Ж.', 'bib': '', 'assigned': false, 'club': 'HuskyTeam', 'disc': 'Скиджоринг 2.5км', 'isLeader': false, 'personal': false},
    {'name': 'Новикова З.З.', 'bib': '77', 'assigned': true, 'club': 'Лично', 'disc': 'Упряжки 2с', 'isLeader': false, 'personal': true},
  ];

  List<String> get _disciplines {
    final discs = _athletes.map((a) => a['disc'] as String).toSet().toList()..sort();
    return ['Все', ...discs];
  }

  List<String> get _usedBibs => _athletes.where((a) => a['assigned']).map<String>((a) => a['bib']).toList();

  List<int> get _freeBibNumbers {
    final used = _usedBibs.map(int.tryParse).whereType<int>().toSet();
    final free = <int>[]; int current = _startBib;
    while (free.length < 100 && current < 1000) { if (!used.contains(current)) free.add(current); current++; }
    return free;
  }

  List<int> get _availableStartRanges {
    final used = _usedBibs.map(int.tryParse).whereType<int>().toList()..sort();
    final ranges = {1};
    if (used.isNotEmpty) {
      for (int i = 0; i < used.length - 1; i++) { if (used[i+1] - used[i] > 1) ranges.add(used[i] + 1); }
      ranges.add(used.last + 1);
      int nextTen = ((used.last ~/ 10) + 1) * 10 + 1; ranges.add(nextTen);
      int nextHundred = ((used.last ~/ 100) + 1) * 100 + 1; ranges.add(nextHundred);
    }
    final sortedRanges = ranges.toList()..sort();
    if (!sortedRanges.contains(_startBib)) { sortedRanges.add(_startBib); sortedRanges.sort(); }
    return sortedRanges;
  }

  List<Map<String, dynamic>> get _filteredAthletes {
    return _athletes.where((a) {
      if (_searchQuery.isNotEmpty && !a['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) && !a['club'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      if (_selectedDisc != 'Все' && a['disc'] != _selectedDisc) return false;
      if (_filter == 'assigned' && !a['assigned']) return false;
      if (_filter == 'unassigned' && a['assigned']) return false;
      return true;
    }).toList();
  }

  int get _suggestedStartBib {
    final available = _availableStartRanges;
    if (available.length > 1 && available.first == 1 && _usedBibs.isNotEmpty) return available.last;
    return _startBib;
  }

  void _showAssignBib(int realIndex) {
    final free = _freeBibNumbers;
    final athlete = _athletes[realIndex];
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'Назначение BIB: ${athlete['name']}', initialHeight: 0.65, child: Column(children: [
      Text('${athlete['disc']} · ${athlete['club']}', style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Свободных номеров: ${free.length}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
          Text('Начиная с: $_startBib', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
        itemCount: free.length,
        itemBuilder: (ctx, idx) {
          final n = free[idx];
          final strNum = n.toString().padLeft(2, '0');
          return InkWell(
            onTap: () {
              setState(() { _athletes[realIndex]['bib'] = strNum; _athletes[realIndex]['assigned'] = true; });
              Navigator.pop(ctx);
              AppSnackBar.success(context, 'BIB $strNum → ${athlete['name']}');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(strNum, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary))),
            ),
          );
        },
      )),
    ]));
  }

  void _changeBib(int realIndex) {
    final ctrl = TextEditingController(text: _athletes[realIndex]['bib']);
    bool isPersonal = _athletes[realIndex]['personal'] ?? false;
    final cs = Theme.of(context).colorScheme;

    AppDialog.custom(context, title: 'Редактировать BIB — ${_athletes[realIndex]['name']}', child: StatefulBuilder(builder: (context, setDialog) => Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'BIB', border: OutlineInputBorder()), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      CheckboxListTile(
        title: const Text('Это личный номер спортсмена', style: TextStyle(fontSize: 14)),
        subtitle: const Text('Со своим номером', style: TextStyle(fontSize: 12)),
        value: isPersonal, onChanged: (v) => setDialog(() => isPersonal = v ?? false),
        contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 12),
      Text('Свободные: ${_freeBibNumbers.take(10).map((n) => n.toString().padLeft(2, '0')).join(', ')}...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
    ])), actions: [
      TextButton(onPressed: () {
        setState(() { _athletes[realIndex]['bib'] = ''; _athletes[realIndex]['assigned'] = false; _athletes[realIndex]['personal'] = false; });
        Navigator.of(context, rootNavigator: true).pop();
      }, child: Text('Сбросить (Удалить)', style: TextStyle(color: cs.error))),
      TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Отмена')),
      FilledButton(onPressed: () {
        final newBib = ctrl.text.padLeft(2, '0');
        if (_usedBibs.contains(newBib) && newBib != _athletes[realIndex]['bib']) { AppSnackBar.error(context, 'BIB $newBib уже занят!'); return; }
        setState(() { _athletes[realIndex]['bib'] = newBib; _athletes[realIndex]['personal'] = isPersonal; _athletes[realIndex]['assigned'] = true; });
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackBar.success(context, 'BIB сохранён: $newBib');
      }, child: const Text('Сохранить')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assignedCount = _athletes.where((a) => a['assigned']).length;
    final unassignedCount = _athletes.length - assignedCount;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Назначение BIB'), actions: [
        IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'Привязать RFID-чип', onPressed: () => AppSnackBar.info(context, 'В разработке: Чтение RFID-чипов с браслетов')),
      ]),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Icon(Icons.flag, color: cs.primary), const SizedBox(width: 8), Text('Назначено: $assignedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            Row(children: [Icon(Icons.person_off, color: cs.tertiary), const SizedBox(width: 8), Text('Осталось: $unassignedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.primary.withValues(alpha: 0.2))),
            child: Row(children: [
              Icon(Icons.pool, color: cs.primary, size: 20), const SizedBox(width: 8),
              const Text('Начать номера с:', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8),
              SizedBox(width: 100, child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                initialValue: _startBib,
                items: _availableStartRanges.map((val) => DropdownMenuItem(value: val, child: Text(val.toString().padLeft(2, '0')))).toList(),
                onChanged: (v) => setState(() => _startBib = v ?? 1),
              )),
              Expanded(child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                initialValue: _selectedDisc,
                items: _disciplines.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedDisc = v!),
              )),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: Text(_selectedDisc == 'Все' ? 'Авто-всем' : 'Авто-группе'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  final toAssign = _filteredAthletes.where((a) => !a['assigned']).toList();
                  if (toAssign.isEmpty) { AppSnackBar.info(context, 'В выбранной группе нет участников без номеров'); return; }
                  int count = 0;
                  setState(() {
                    for (var athlete in toAssign) {
                      final realIndex = _athletes.indexOf(athlete);
                      final freePool = _freeBibNumbers;
                      int selectedBib = -1;
                      if (freePool.contains(_suggestedStartBib)) { selectedBib = _suggestedStartBib; }
                      else if (freePool.isNotEmpty) { selectedBib = freePool.first; }
                      if (selectedBib != -1) {
                        _athletes[realIndex]['bib'] = selectedBib.toString().padLeft(2, '0');
                        _athletes[realIndex]['assigned'] = true; _athletes[realIndex]['personal'] = false;
                        count++;
                      }
                    }
                  });
                  AppSnackBar.success(context, 'Выдано автоматически $count номеров');
                },
              ),
            ]),
          ),
          if (_filteredAthletes.where((a) => !a['assigned']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Рекомендуется начать с: ${_suggestedStartBib.toString().padLeft(2, '0')}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(children: [
          TextField(decoration: InputDecoration(hintText: 'Поиск участника или клуба...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: EdgeInsets.zero),
            onChanged: (v) => setState(() => _searchQuery = v)),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            ChoiceChip(label: const Text('Все'), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
            const SizedBox(width: 8),
            ChoiceChip(label: Text('Без номера', style: TextStyle(color: cs.tertiary)), selected: _filter == 'unassigned', onSelected: (_) => setState(() => _filter = 'unassigned'), selectedColor: cs.tertiary.withValues(alpha: 0.2)),
            const SizedBox(width: 8),
            ChoiceChip(label: Text('С номером', style: TextStyle(color: cs.primary)), selected: _filter == 'assigned', onSelected: (_) => setState(() => _filter = 'assigned'), selectedColor: cs.primary.withValues(alpha: 0.2)),
          ])),
        ])),
        const Divider(height: 1),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: _filteredAthletes.length,
          itemBuilder: (context, index) {
            final athlete = _filteredAthletes[index];
            final realIndex = _athletes.indexOf(athlete);
            final isAssigned = athlete['assigned'] as bool;
            final isLeader = athlete['isLeader'] as bool;
            final isPersonal = athlete['personal'] as bool? ?? false;
            final borderColor = isPersonal ? cs.secondary : isLeader ? cs.tertiary : isAssigned ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.3);
            final bgColor = isPersonal ? cs.secondary.withValues(alpha: 0.1) : isLeader ? cs.tertiary.withValues(alpha: 0.15) : isAssigned ? cs.primary.withValues(alpha: 0.05) : cs.surface;

            return Card(
              margin: const EdgeInsets.only(bottom: 8), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
              child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                  child: Center(child: isAssigned
                    ? Text(athlete['bib'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isPersonal ? cs.secondary : isLeader ? cs.tertiary : cs.primary))
                    : Icon(Icons.question_mark, color: cs.onSurfaceVariant))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(athlete['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isLeader) ...[const SizedBox(width: 4), Icon(Icons.star, color: cs.tertiary, size: 16)],
                    if (isPersonal) ...[const SizedBox(width: 4), Icon(Icons.verified_user, color: cs.secondary, size: 14)],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.sports, size: 12, color: cs.onSurfaceVariant), const SizedBox(width: 4), Text(athlete['disc'], style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))]),
                  Row(children: [Icon(Icons.shield, size: 12, color: cs.onSurfaceVariant), const SizedBox(width: 4), Text(athlete['club'], style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))]),
                ])),
                isAssigned
                  ? IconButton(icon: Icon(Icons.edit, color: cs.onSurfaceVariant), tooltip: 'Сменить номер', onPressed: () => _changeBib(realIndex))
                  : FilledButton(style: FilledButton.styleFrom(backgroundColor: cs.tertiary, visualDensity: VisualDensity.compact), onPressed: () => _showAssignBib(realIndex), child: const Text('Выдать')),
              ])),
            );
          },
        )),
      ]),
    );
  }
}

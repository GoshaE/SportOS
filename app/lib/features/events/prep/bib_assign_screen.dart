import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen ID: P3 — Назначение BIB
///
/// Читает из [participantsProvider] и [disciplineConfigsProvider].
/// Назначение BIB → [ParticipantsNotifier.update] с `copyWith(bib: ...)`.
class BibAssignScreen extends ConsumerStatefulWidget {
  const BibAssignScreen({super.key});

  @override
  ConsumerState<BibAssignScreen> createState() => _BibAssignScreenState();
}

class _BibAssignScreenState extends ConsumerState<BibAssignScreen> {
  int _startBib = 1;
  String _searchQuery = '';
  String _selectedDisc = 'Все';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final participants = ref.watch(participantsProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);

    // Discipline names for filter
    final discNames = ['Все', ...disciplines.map((d) => d.name)];
    if (!discNames.contains(_selectedDisc)) _selectedDisc = 'Все';

    // Filter
    final filtered = participants.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !(p.club?.toLowerCase().contains(q) ?? false) &&
            !p.bib.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedDisc != 'Все' && p.disciplineName != _selectedDisc) return false;
      if (_filter == 'assigned' && p.bib.isEmpty) return false;
      if (_filter == 'unassigned' && p.bib.isNotEmpty) return false;
      return true;
    }).toList();

    final assignedCount = participants.where((p) => p.bib.isNotEmpty).length;
    final unassignedCount = participants.length - assignedCount;
    final usedBibs = participants.where((p) => p.bib.isNotEmpty).map((p) => p.bib).toSet();

    List<int> freeBibNumbers() {
      final used = usedBibs.map(int.tryParse).whereType<int>().toSet();
      final free = <int>[]; int current = _startBib;
      while (free.length < 100 && current < 1000) { if (!used.contains(current)) free.add(current); current++; }
      return free;
    }

    return Scaffold(
      appBar: AppAppBar(title: const Text('Назначение BIB'), actions: [
        IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'Привязать RFID-чип', onPressed: () => AppSnackBar.info(context, 'В разработке: Чтение RFID-чипов с браслетов')),
      ]),
      body: Column(children: [
        // ─── Статистика + настройки ───
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
              const Text('С номера:', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8),
              SizedBox(width: 60, child: TextFormField(
                initialValue: '$_startBib',
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) { final n = int.tryParse(v); if (n != null && n > 0) setState(() => _startBib = n); },
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                initialValue: _selectedDisc,
                items: discNames.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedDisc = v!),
              )),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: Text(_selectedDisc == 'Все' ? 'Авто-всем' : 'Авто-группе'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  final toAssign = filtered.where((p) => p.bib.isEmpty).toList();
                  if (toAssign.isEmpty) { AppSnackBar.info(context, 'Нет участников без номеров'); return; }
                  final free = freeBibNumbers();
                  int count = 0;
                  for (var i = 0; i < toAssign.length && i < free.length; i++) {
                    final newBib = free[i].toString().padLeft(2, '0');
                    ref.read(participantsProvider.notifier).update(
                      toAssign[i].id, (p) => p.copyWith(bib: newBib),
                    );
                    count++;
                  }
                  AppSnackBar.success(context, 'Выдано автоматически $count номеров');
                },
              ),
            ]),
          ),
        ])),

        // ─── Поиск + фильтры ───
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

        // ─── Список ───
        Expanded(child: filtered.isEmpty
          ? Center(child: Text(participants.isEmpty ? 'Нет участников' : 'Нет совпадений', style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                final isAssigned = p.bib.isNotEmpty;
                final borderColor = isAssigned ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.3);
                final bgColor = isAssigned ? cs.primary.withValues(alpha: 0.05) : cs.surface;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
                  child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                      child: Center(child: isAssigned
                        ? Text(p.bib, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary))
                        : Icon(Icons.question_mark, color: cs.onSurfaceVariant))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.sports, size: 12, color: cs.onSurfaceVariant), const SizedBox(width: 4), Text(p.disciplineName, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))]),
                      if (p.club != null) Row(children: [Icon(Icons.shield, size: 12, color: cs.onSurfaceVariant), const SizedBox(width: 4), Text(p.club!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))]),
                    ])),
                    isAssigned
                      ? IconButton(
                          icon: Icon(Icons.edit, color: cs.onSurfaceVariant), tooltip: 'Сменить номер',
                          onPressed: () => _changeBib(context, cs, p, usedBibs),
                        )
                      : FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: cs.tertiary, visualDensity: VisualDensity.compact),
                          onPressed: () => _showAssignBib(context, cs, p, freeBibNumbers()),
                          child: const Text('Выдать'),
                        ),
                  ])),
                );
              },
            ),
        ),
      ]),
    );
  }

  void _showAssignBib(BuildContext context, ColorScheme cs, Participant p, List<int> free) {
    AppBottomSheet.show(context, title: 'Назначение BIB: ${p.name}', initialHeight: 0.65, child: Column(children: [
      Text('${p.disciplineName}${p.club != null ? " · ${p.club}" : ""}', style: TextStyle(color: cs.onSurfaceVariant)),
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
              ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: strNum));
              Navigator.pop(ctx);
              AppSnackBar.success(context, 'BIB $strNum → ${p.name}');
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

  void _changeBib(BuildContext context, ColorScheme cs, Participant p, Set<String> usedBibs) {
    final ctrl = TextEditingController(text: p.bib);

    AppDialog.custom(context, title: 'Редактировать BIB — ${p.name}', child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'BIB', border: OutlineInputBorder()), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      Text('Свободные: ...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
    ]), actions: [
      TextButton(onPressed: () {
        ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: ''));
        Navigator.of(context, rootNavigator: true).pop();
      }, child: Text('Сбросить', style: TextStyle(color: cs.error))),
      TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Отмена')),
      FilledButton(onPressed: () {
        final newBib = ctrl.text.padLeft(2, '0');
        if (usedBibs.contains(newBib) && newBib != p.bib) { AppSnackBar.error(context, 'BIB $newBib уже занят!'); return; }
        ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: newBib));
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackBar.success(context, 'BIB сохранён: $newBib');
      }, child: const Text('Сохранить')),
    ]);
  }
}

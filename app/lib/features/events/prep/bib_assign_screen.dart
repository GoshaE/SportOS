import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';
import '../../../domain/event/bib_undo_manager.dart';
import '../../../domain/timing/result_table.dart';

/// Screen ID: P3 — Назначение BIB
///
/// Читает из [participantsProvider] и [disciplineConfigsProvider].
/// Назначение BIB → [ParticipantsNotifier.update] с `copyWith(bib: ...)`.
/// Включает механизм отката (Undo/Redo) с помощью [BibUndoManager].
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
  bool _showCards = false;

  // Менеджер отката локален для экрана назначения
  late final BibUndoManager _undoManager;

  @override
  void initState() {
    super.initState();
    _undoManager = BibUndoManager();
  }

  @override
  void dispose() {
    _undoManager.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allParticipants = ref.watch(participantsProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final pools = ref.watch(eventConfigProvider).bibPools;

    // Discipline names for filter
    final discNames = ['Все', ...disciplines.map((d) => d.name)];
    if (!discNames.contains(_selectedDisc)) _selectedDisc = 'Все';

    // ── Filtering ──
    var filtered = allParticipants.where((p) {
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

    // ── Sort by startPosition (draw result) → name ──
    filtered.sort((a, b) {
      final aPos = a.startPosition ?? 999999;
      final bPos = b.startPosition ?? 999999;
      if (aPos != bPos) return aPos.compareTo(bPos);
      return a.name.compareTo(b.name);
    });

    // ── Table Builder ──
    final table = _buildResultTable(context, cs, filtered);

    // ── Stats ──
    final assignedCount = allParticipants.where((p) => p.bib.isNotEmpty).length;
    final unassignedCount = allParticipants.length - assignedCount;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Назначение BIB'),
        actions: [
          // ── Undo / Redo ──
          Tooltip(
            message: _undoManager.canUndo ? 'Отменить: ${_undoManager.lastUndoLabel}' : 'Нет действий для отмены',
            child: IconButton(
              icon: const Icon(Icons.undo),
              color: _undoManager.canUndo ? cs.primary : cs.outlineVariant,
              onPressed: _undoManager.canUndo ? () => _performUndo(allParticipants) : null,
            ),
          ),
          Tooltip(
            message: _undoManager.canRedo ? 'Повторить: ${_undoManager.lastRedoLabel}' : 'Нет действий для повтора',
            child: IconButton(
              icon: const Icon(Icons.redo),
              color: _undoManager.canRedo ? cs.primary : cs.outlineVariant,
              onPressed: _undoManager.canRedo ? () => _performRedo(allParticipants) : null,
            ),
          ),
          const SizedBox(width: 8),
          
          // ── View Toggle ──
          IconButton(
            icon: Icon(_showCards ? Icons.table_rows_outlined : Icons.grid_view_outlined),
            tooltip: _showCards ? 'В виде таблицы' : 'В виде карточек',
            onPressed: () => setState(() => _showCards = !_showCards),
          ),
          
          // ── RFID Scanner (w/info) ──
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Привязать RFID-чип',
            onPressed: () => AppSnackBar.info(context, 'В разработке: Чтение RFID-чипов с браслетов'),
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ─── Stats & Global Controls ───
        Container(
          padding: const EdgeInsets.all(16),
          color: cs.surface,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Icon(Icons.flag, color: cs.primary), const SizedBox(width: 8), Text('Назначено: $assignedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              Row(children: [Icon(Icons.person_off, color: cs.tertiary), const SizedBox(width: 8), Text('Осталось: $unassignedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            ]),
            const SizedBox(height: 16),
            
            // Auto-assign controls
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Пул с номера:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  SizedBox(width: 70, child: TextFormField(
                    initialValue: '$_startBib',
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) { final n = int.tryParse(v); if (n != null && n > 0) setState(() => _startBib = n); },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(6)),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      value: _selectedDisc,
                      items: discNames.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedDisc = v!),
                    ),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: 'Сбросить все',
                      icon: Icons.clear_all,
                      onPressed: () => _showClearAllConfirm(context, allParticipants),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      text: _selectedDisc == 'Все' ? 'Авто-назначение: Всем' : 'Авто-назначение: $_selectedDisc',
                      icon: Icons.auto_fix_high,
                      onPressed: () => _performAutoAssign(allParticipants, pools),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),

        // ─── Search & Layout Filters ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: cs.surface,
          child: Column(children: [
            AppTextField(
              label: 'Поиск участника или клуба...',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              ChoiceChip(label: const Text('Все'), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              ChoiceChip(label: Text('Без номера', style: TextStyle(color: cs.tertiary)), selected: _filter == 'unassigned', onSelected: (_) => setState(() => _filter = 'unassigned'), selectedColor: cs.tertiary.withOpacity(0.2)),
              const SizedBox(width: 8),
              ChoiceChip(label: Text('С номером', style: TextStyle(color: cs.primary)), selected: _filter == 'assigned', onSelected: (_) => setState(() => _filter = 'assigned'), selectedColor: cs.primary.withOpacity(0.2)),
            ])),
          ]),
        ),
        
        // ─── Table ───
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('Нет совпадений', style: TextStyle(color: cs.onSurfaceVariant)))
              : AppResultTable(
                  table: table,
                  showCards: _showCards,
                  onRowTap: (row) {
                    final p = filtered.firstWhere((p) => p.id == row.entryId);
                    if (p.bib.isNotEmpty) {
                      _changeBib(context, cs, p);
                    } else {
                      _showAssignBib(context, cs, p);
                    }
                  },
                ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGIC & ACTIONS
  // ─────────────────────────────────────────────────────────────────

  /// Сгенерировать список доступных номеров с учетом занятых и preferredBib.
  List<int> _freeBibNumbers(List<Participant> all) {
     final used = all.where((p) => p.bib.isNotEmpty).map((p) => p.bib).map(int.tryParse).whereType<int>().toSet();
     // Also exclude preferredBib of other participants (reserved for them)
     final reserved = all.where((p) => p.preferredBib != null).map((p) => int.tryParse(p.preferredBib!)).whereType<int>().toSet();
     final excluded = used.union(reserved);
     final free = <int>[]; 
     int current = _startBib;
     while (free.length < 200 && current < 9999) { 
       if (!excluded.contains(current)) free.add(current); 
       current++; 
     }
     return free;
  }

  void _performUndo(List<Participant> allParticipants) {
    final snap = _undoManager.undo(allParticipants);
    if (snap != null) {
      _applySnapshot(snap);
      AppSnackBar.success(context, 'Отменено: ${snap.label}');
    }
  }

  void _performRedo(List<Participant> allParticipants) {
    final snap = _undoManager.redo(allParticipants);
    if (snap != null) {
      _applySnapshot(snap);
      AppSnackBar.success(context, 'Повторено: ${snap.label}');
    }
  }

  void _applySnapshot(BibSnapshot snap) {
    ref.read(participantsProvider.notifier).bulkUpdate(
      snap.bibs.keys.toSet(),
      (p) => p.copyWith(bib: snap.bibs[p.id] ?? ''),
    );
  }

  void _showClearAllConfirm(BuildContext context, List<Participant> allParticipants) {
    final hasBibs = allParticipants.any((p) => p.bib.isNotEmpty);
    if (!hasBibs) {
      AppSnackBar.info(context, 'Нет выданных номеров для сброса');
      return;
    }

    AppDialog.confirm(
      context,
      title: 'Сбросить все номера?',
      message: 'Все участники останутся без стартовых номеров. Эту операцию можно будет отменить с помощью кнопки "Undo".',
      confirmText: 'Сбросить',
      isDanger: true,
      onConfirm: () {
        _undoManager.saveSnapshot('Сброс всех номеров', allParticipants);
        // Don't reset preferredBib — only clear assigned bib
        final ids = allParticipants.where((p) => p.bib.isNotEmpty).map((p) => p.id).toSet();
        ref.read(participantsProvider.notifier).bulkUpdate(ids, (p) => p.copyWith(bib: ''));
        AppSnackBar.success(context, 'Все номера сброшены. Используйте Undo (↶), чтобы вернуть.');
      },
    );
  }

  void _performAutoAssign(List<Participant> allParticipants, List<BibPool> pools) {
    // Determine scope — sorted by startPosition (draw order) to match visible order
    final toAssignScope = (_selectedDisc == 'Все' 
      ? allParticipants.where((p) => p.bib.isEmpty).toList()
      : allParticipants.where((p) => p.bib.isEmpty && p.disciplineName == _selectedDisc).toList())
      ..sort((a, b) {
        final aPos = a.startPosition ?? 999999;
        final bPos = b.startPosition ?? 999999;
        if (aPos != bPos) return aPos.compareTo(bPos);
        return a.name.compareTo(b.name);
      });
      
    if (toAssignScope.isEmpty) { 
      AppSnackBar.info(context, 'Нет участников без номеров для текущего фильтра'); 
      return; 
    }

    _undoManager.saveSnapshot('Авто: ${_selectedDisc == 'Все' ? 'Всем' : _selectedDisc}', allParticipants);
    int count = 0;

    // Step 1: Assign preferredBib to those who have it (priority)
    for (final p in toAssignScope) {
      if (p.preferredBib != null && p.preferredBib!.isNotEmpty) {
        // Check if preferredBib is not already taken
        final usedBibs = ref.read(participantsProvider).where((pp) => pp.bib.isNotEmpty).map((pp) => pp.bib).toSet();
        final preferredPadded = p.preferredBib!.padLeft(2, '0');
        if (!usedBibs.contains(preferredPadded)) {
          ref.read(participantsProvider.notifier).update(p.id, (pp) => pp.copyWith(bib: preferredPadded));
          count++;
        }
      }
    }

    // Step 2: Assign from pool/range for the rest (those still without bib)
    final remaining = toAssignScope.where((pp) {
      final current = ref.read(participantsProvider).firstWhere((cp) => cp.id == pp.id);
      return current.bib.isEmpty;
    }).toList();

    if (remaining.isNotEmpty) {
      List<int> free = [];
      final discId = remaining.first.disciplineId;
      final hasPool = pools.any((bp) => bp.disciplineId == discId);
      final latestAll = ref.read(participantsProvider);
      
      if (_selectedDisc != 'Все' && hasPool) {
        final pool = pools.firstWhere((bp) => bp.disciplineId == discId);
        final used = latestAll.where((pp) => pp.bib.isNotEmpty).map((pp) => pp.bib).toSet();
        final reserved = latestAll.where((pp) => pp.preferredBib != null).map((pp) => pp.preferredBib!.padLeft(2, '0')).toSet();
        for (int i = pool.rangeStart; i <= pool.rangeEnd; i++) {
          final padded = i.toString().padLeft(2, '0');
          if (!used.contains(padded) && !reserved.contains(padded)) free.add(i);
          if (free.length >= remaining.length) break;
        }
      } else {
         free = _freeBibNumbers(latestAll);
      }

      for (var i = 0; i < remaining.length && i < free.length; i++) {
        final newBib = free[i].toString().padLeft(2, '0');
        ref.read(participantsProvider.notifier).update(
          remaining[i].id, (p) => p.copyWith(bib: newBib),
        );
        count++;
      }
    }
    
    AppSnackBar.success(context, 'Выдано автоматически $count номеров');
  }

  // ─────────────────────────────────────────────────────────────────
  // UI DIALOGS
  // ─────────────────────────────────────────────────────────────────

  void _showAssignBib(BuildContext context, ColorScheme cs, Participant p) {
    final all = ref.read(participantsProvider);
    final free = _freeBibNumbers(all);
    
    AppBottomSheet.show(context, title: 'Назначение BIB: ${p.name}', initialHeight: 0.65, child: Column(children: [
      Text('${p.disciplineName}${p.club != null ? " · ${p.club}" : ""}', style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: cs.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
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
              _undoManager.saveSnapshot('BIB $strNum → ${p.name}', all);
              ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: strNum));
              Navigator.pop(ctx);
              AppSnackBar.success(context, 'BIB $strNum назначен');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, border: Border.all(color: cs.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(strNum, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary))),
            ),
          );
        },
      )),
    ]));
  }

  void _changeBib(BuildContext context, ColorScheme cs, Participant p) {
    final all = ref.read(participantsProvider);
    final usedBibs = all.where((p) => p.bib.isNotEmpty).map((p) => p.bib).toSet();
    final ctrl = TextEditingController(text: p.bib);

    AppDialog.custom(context, title: 'Редактировать BIB — ${p.name}', child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(label: 'BIB', controller: ctrl, keyboardType: TextInputType.number, autofocus: true),
      const SizedBox(height: 12),
    ]), actions: [
      AppButton.text(text: 'Сбросить номер', onPressed: () {
        _undoManager.saveSnapshot('Сброс BIB: ${p.name}', all);
        ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: ''));
        Navigator.of(context, rootNavigator: true).pop();
      }),
      const Spacer(),
      AppButton.text(text: 'Отмена', onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
      AppButton.small(text: 'Сохранить', onPressed: () {
        final newBib = ctrl.text.padLeft(2, '0');
        if (newBib == p.bib) { 
          Navigator.of(context, rootNavigator: true).pop(); 
          return; 
        }
        if (usedBibs.contains(newBib)) { 
          AppSnackBar.error(context, 'BIB $newBib уже занят!'); 
          return; 
        }
        
        _undoManager.saveSnapshot('Изменение BIB: ${p.name}', all);
        ref.read(participantsProvider.notifier).update(p.id, (p) => p.copyWith(bib: newBib));
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackBar.success(context, 'BIB сохранён: $newBib');
      }),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // RESULT TABLE BUILDER
  // ─────────────────────────────────────────────────────────────────

  /// Строит [ResultTable] из отфильтрованного списка участников.
  ResultTable _buildResultTable(BuildContext context, ColorScheme cs, List<Participant> participants) {
    final columns = [
      const ColumnDef(id: '#', label: '#', minWidth: 40, flex: 0.5, type: ColumnType.number, align: ColumnAlign.center),
      const ColumnDef(id: 'pos', label: 'Поз.', minWidth: 50, flex: 0.5, type: ColumnType.number, align: ColumnAlign.center),
      const ColumnDef(id: 'bib', label: 'BIB', minWidth: 60, flex: 1.0, type: ColumnType.number, align: ColumnAlign.center),
      const ColumnDef(id: 'name', label: 'Участник', minWidth: 150, flex: 3.0),
      const ColumnDef(id: 'disc', label: 'Дисциплина', minWidth: 100, flex: 1.5),
      const ColumnDef(id: 'club', label: 'Клуб', minWidth: 100, flex: 1.5),
      const ColumnDef(id: 'action', label: 'Действие', minWidth: 80, flex: 1.0, align: ColumnAlign.center),
    ];

    int i = 1;
    final rows = participants.map((p) {
      final hasBib = p.bib.isNotEmpty;
      final isPreferred = hasBib && p.preferredBib != null && p.bib == p.preferredBib!.padLeft(2, '0');
      
      return ResultRow(
        entryId: p.id,
        type: hasBib ? RowType.finished : RowType.waiting,
        cells: {
          '#': CellValue(display: '${i++}', raw: i),
          'pos': CellValue(
            display: p.startPosition != null ? '${p.startPosition}' : '—',
            style: p.startPosition != null ? CellStyle.normal : CellStyle.muted,
          ),
          'bib': CellValue(
            display: hasBib ? (isPreferred ? '🔒 ${p.bib}' : p.bib) : (p.preferredBib != null ? '🔒 ${p.preferredBib}' : '—'),
            raw: p.bib,
            style: hasBib ? (isPreferred ? CellStyle.bold : CellStyle.normal) : (p.preferredBib != null ? CellStyle.highlight : CellStyle.muted),
          ),
          'name': CellValue(
            display: '${p.name} ${p.category != null ? "(${p.category})" : ""}',
            style: CellStyle.bold,
          ),
          'disc': CellValue(display: p.disciplineName),
          'club': CellValue(display: p.club ?? ''),
          'action': CellValue(
              display: hasBib ? 'Изменить' : 'Выдать',
              style: hasBib ? CellStyle.muted : CellStyle.highlight,
            ),
        },
      );
    }).toList();

    return ResultTable(columns: columns, rows: rows);
  }
}


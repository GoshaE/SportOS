import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/event/event_config.dart' hide TimeOfDay;
import 'package:sportos_app/domain/event/config_providers.dart';
import 'package:sportos_app/domain/timing/models.dart' show DisciplineConfig;
import 'package:sportos_app/domain/timing/result_table.dart';

/// Screen ID: E3 — Участники с группировкой и импортом.
///
/// [isOrganizer] = true  → полный вид (статус оплаты, заявки, кнопки)
/// [isOrganizer] = false → публичный вид (только список)
class ParticipantsScreen extends ConsumerStatefulWidget {
  final bool isOrganizer;
  const ParticipantsScreen({super.key, this.isOrganizer = true});

  @override
  ConsumerState<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends ConsumerState<ParticipantsScreen> {
  String _search = '';
  String? _selectedDisciplineId; // null = «Все»
  bool _showCards = false;

  // ── Multi-select state ──
  bool _selectMode = false;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final allParticipants = ref.watch(participantsProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    // Search filter
    final filtered = _search.isEmpty
        ? allParticipants
        : allParticipants.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();

    final total = allParticipants.length;

    return Scaffold(
      appBar: AppAppBar(
        title: Text(_selectMode
            ? 'Выбрано: ${_selected.length}'
            : widget.isOrganizer ? 'Участники ($total)' : 'Список участников ($total)'),
        leading: _selectMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectMode)
            : null,
        actions: [
          if (_selectMode) ...[
            IconButton(
              icon: Icon(_selected.length == allParticipants.length ? Icons.deselect : Icons.select_all, size: 20),
              tooltip: _selected.length == allParticipants.length ? 'Снять всё' : 'Выбрать всех',
              onPressed: () => setState(() {
                if (_selected.length == allParticipants.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(allParticipants.map((p) => p.id));
                }
              }),
            ),
          ] else ...[
            // Card/Table toggle
            IconButton(
              icon: Icon(_showCards ? Icons.table_rows : Icons.view_agenda, size: 20),
              tooltip: _showCards ? 'Таблица' : 'Карточки',
              onPressed: () => setState(() => _showCards = !_showCards),
            ),
            if (widget.isOrganizer) ...[
              IconButton(icon: const Icon(Icons.upload_file, size: 20), tooltip: 'Из Excel', onPressed: () => context.push('/manage/$eventId/import')),
              IconButton(icon: const Icon(Icons.person_add, size: 20), tooltip: 'Добавить', onPressed: () => _showAddParticipant(context)),
              // ⋮ Overflow menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: 'Ещё',
                onSelected: (value) {
                  switch (value) {
                    case 'select':
                      setState(() => _selectMode = true);
                    case 'select_all':
                      setState(() {
                        _selectMode = true;
                        _selected.addAll(allParticipants.map((p) => p.id));
                      });
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'select', child: ListTile(leading: Icon(Icons.checklist, size: 20), title: Text('Выделить несколько'), dense: true, contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(value: 'select_all', child: ListTile(leading: Icon(Icons.select_all, size: 20), title: Text('Выбрать всех'), dense: true, contentPadding: EdgeInsets.zero)),
                ],
              ),
            ],
          ],
        ],
      ),
      body: Column(children: [
        // ── Discipline filter chips ──
        if (!_selectMode)
          _DisciplineChips(
            disciplines: disciplines,
            selectedId: _selectedDisciplineId,
            totalCount: total,
            onSelected: (id) => setState(() => _selectedDisciplineId = id),
          ),

        // ── Search ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: AppTextField(
            label: 'Поиск по имени...',
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),

        // ── Stacked discipline tables ──
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(cs)
              : _buildStackedTables(filtered, disciplines, cs, theme),
        ),
      ]),

      // ── Bottom Action Bar (select mode) ──
      bottomNavigationBar: _selectMode && _selected.isNotEmpty
          ? _buildBulkActionBar(context, cs)
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Build stacked AppResultTable per discipline
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStackedTables(List<Participant> filtered, List<DisciplineConfig> disciplines, ColorScheme cs, ThemeData theme) {
    // Group by discipline
    final byDisc = <String, List<Participant>>{};
    for (final p in filtered) {
      byDisc.putIfAbsent(p.disciplineId, () => []).add(p);
    }

    // Filter by selected discipline
    final discIds = _selectedDisciplineId != null
        ? [_selectedDisciplineId!]
        : byDisc.keys.toList();

    final orderedDiscs = disciplines
        .where((d) => discIds.contains(d.id) && byDisc.containsKey(d.id))
        .toList();

    if (orderedDiscs.isEmpty) return _buildEmptyState(cs);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      itemCount: orderedDiscs.length,
      itemBuilder: (context, i) {
        final disc = orderedDiscs[i];
        final participants = byDisc[disc.id] ?? [];
        return _buildDisciplineBlock(disc, participants, cs, theme);
      },
    );
  }

  Widget _buildDisciplineBlock(DisciplineConfig disc, List<Participant> participants, ColorScheme cs, ThemeData theme) {
    // Group by category
    final byCategory = <String, List<Participant>>{};
    for (final p in participants) {
      final cat = p.category ?? 'Без категории';
      byCategory.putIfAbsent(cat, () => []).add(p);
    }
    final categories = byCategory.keys.toList()..sort();
    final showCatHeaders = categories.length > 1 || (categories.length == 1 && categories.first != 'Без категории');

    // Build ResultTable for this discipline
    final columns = _buildColumns();
    final rows = <ResultRow>[];

    for (final cat in categories) {
      // Add category separator row
      if (showCatHeaders) {
        rows.add(ResultRow(
          entryId: 'cat-$cat',
          type: RowType.waiting,
          cells: {
            for (final col in columns) col.id:
              col.id == 'name'
                ? CellValue(display: '$cat (${byCategory[cat]!.length})', style: CellStyle.bold)
                : const CellValue(display: ''),
          },
        ));
      }

      for (final p in byCategory[cat]!) {
        rows.add(_participantToRow(p));
      }
    }

    final table = ResultTable(columns: columns, rows: rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Discipline header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.primaryContainer.withValues(alpha: 0.12),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.sports, size: 14, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(disc.name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${participants.length} чел.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            ),
          ]),
        ),

        // Table
        AppResultTable(
          table: table,
          showCards: _showCards,
          onRowTap: (row) {
            if (row.entryId.startsWith('cat-')) return;
            if (_selectMode) {
              setState(() {
                if (_selected.contains(row.entryId)) {
                  _selected.remove(row.entryId);
                  if (_selected.isEmpty) _selectMode = false;
                } else {
                  _selected.add(row.entryId);
                }
              });
              return;
            }
            final p = participants.firstWhere(
              (p) => p.id == row.entryId,
              orElse: () => participants.first,
            );
            if (widget.isOrganizer) {
              _showParticipantActions(context, p);
            }
          },
          onRowLongPress: widget.isOrganizer ? (row) {
            if (row.entryId.startsWith('cat-')) return;
            setState(() {
              _selectMode = true;
              _selected.add(row.entryId);
            });
          } : null,
          selectedRowIds: _selectMode ? _selected : null,
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Column definitions
  // ═══════════════════════════════════════════════════════════════
  List<ColumnDef> _buildColumns() {
    return [
      const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.number, align: ColumnAlign.center, flex: 0.5, minWidth: 45),
      const ColumnDef(id: 'name', label: 'ФИО', type: ColumnType.text, flex: 2.0, minWidth: 120),
      const ColumnDef(id: 'city', label: 'Город', type: ColumnType.text, flex: 1.2, minWidth: 70),
      const ColumnDef(id: 'club', label: 'Клуб', type: ColumnType.text, flex: 1.2, minWidth: 70),
      const ColumnDef(id: 'dog', label: 'Собака', type: ColumnType.text, flex: 1.0, minWidth: 60),
      if (widget.isOrganizer) ...[
        const ColumnDef(id: 'paid', label: '₽', type: ColumnType.status, align: ColumnAlign.center, flex: 0.4, minWidth: 32),
        const ColumnDef(id: 'status', label: '✓', type: ColumnType.status, align: ColumnAlign.center, flex: 0.4, minWidth: 32),
      ],
    ];
  }

  ResultRow _participantToRow(Participant p) {
    final isPaid = p.paymentStatus == PaymentStatus.paid;
    final isApproved = p.applicationStatus == ApplicationStatus.approved;

    final cells = <String, CellValue>{
      'bib': CellValue(display: p.bib, raw: int.tryParse(p.bib) ?? 0),
      'name': CellValue(display: p.name, style: CellStyle.bold),
      'city': CellValue(display: p.city ?? '—', style: p.city != null ? CellStyle.normal : CellStyle.muted),
      'club': CellValue(display: p.club ?? '—', style: p.club != null ? CellStyle.normal : CellStyle.muted),
      'dog': CellValue(display: p.dogName ?? '—', style: p.dogName != null ? CellStyle.normal : CellStyle.muted),
    };

    if (widget.isOrganizer) {
      cells['paid'] = CellValue(display: isPaid ? '✓' : '✗', style: isPaid ? CellStyle.success : CellStyle.error);
      cells['status'] = CellValue(display: isApproved ? '✓' : '…', style: isApproved ? CellStyle.success : CellStyle.muted);
    }

    return ResultRow(entryId: p.id, type: RowType.finished, cells: cells);
  }

  // ═══════════════════════════════════════════════════════════════
  // Participant actions (edit / delete) — organizer only
  // ═══════════════════════════════════════════════════════════════
  void _showParticipantActions(BuildContext context, Participant p) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isPaid = p.paymentStatus == PaymentStatus.paid;
    final isApproved = p.applicationStatus == ApplicationStatus.approved;

    AppBottomSheet.show(context, title: p.name, child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Info card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow(theme, 'BIB', p.bib),
          _infoRow(theme, 'Дисциплина', p.disciplineName),
          if (p.gender != null) _infoRow(theme, 'Пол', p.gender == 'male' ? 'Мужской' : 'Женский'),
          if (p.birthDate != null) _infoRow(theme, 'Дата рождения', '${p.birthDate!.day.toString().padLeft(2, '0')}.${p.birthDate!.month.toString().padLeft(2, '0')}.${p.birthDate!.year}'),
          if (p.city != null) _infoRow(theme, 'Город', p.city!),
          if (p.club != null) _infoRow(theme, 'Клуб', p.club!),
          if (p.dogName != null) _infoRow(theme, 'Собака', p.dogName!),
          if (p.category != null) _infoRow(theme, 'Категория', p.category!),
        ]),
      ),
      const SizedBox(height: 16),

      // Actions
      _actionTile(cs, Icons.edit, 'Редактировать', null, () {
        Navigator.of(context, rootNavigator: true).pop();
        _showEditParticipant(context, p);
      }),
      _actionTile(cs, Icons.check_circle, isApproved ? 'Заявка подтверждена' : 'Подтвердить заявку',
        isApproved ? cs.primary : null, () {
        if (!isApproved) {
          ref.read(participantsProvider.notifier).approve(p.id);
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, '${p.name} — заявка подтверждена');
        }
      }),
      _actionTile(cs, Icons.payment, isPaid ? 'Оплачено (${p.priceRub ?? 0} ₽)' : 'Отметить оплату',
        isPaid ? cs.primary : null, () {
        if (!isPaid) {
          ref.read(participantsProvider.notifier).markPaid(p.id);
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, '${p.name} — оплата отмечена');
        }
      }),
      const Divider(),
      _actionTile(cs, Icons.delete, 'Удалить участника', cs.error, () {
        Navigator.of(context, rootNavigator: true).pop();
        _confirmDelete(context, p);
      }),
    ]));
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
      ]),
    );
  }

  Widget _actionTile(ColorScheme cs, IconData icon, String label, Color? color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color ?? cs.onSurfaceVariant, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? cs.onSurface)),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // ─── Delete confirmation ───
  void _confirmDelete(BuildContext context, Participant p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить участника?'),
      content: Text('${p.name} будет удалён из списка.'),
      actions: [
        AppButton.text(text: 'Отмена', onPressed: () => Navigator.pop(ctx)),
        AppButton.small(text: 'Удалить', onPressed: () {
          ref.read(participantsProvider.notifier).remove(p.id);
          Navigator.pop(ctx);
          AppSnackBar.success(context, '${p.name} удалён');
        }),
      ],
    ));
  }

  // ─── Edit participant ───
  void _showEditParticipant(BuildContext context, Participant p) {
    final nameCtrl = TextEditingController(text: p.name);
    final phoneCtrl = TextEditingController(text: p.phone ?? '');
    final dogCtrl = TextEditingController(text: p.dogName ?? '');
    final cityCtrl = TextEditingController(text: p.city ?? '');
    final clubCtrl = TextEditingController(text: p.club ?? '');
    final bibCtrl = TextEditingController(text: p.bib);
    String? selectedGender = p.gender;
    DateTime? birthDate = p.birthDate;
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'Редактировать', actions: [
      AppButton.primary(
        text: 'Сохранить',
        onPressed: () {
          if (nameCtrl.text.trim().isEmpty) {
            AppSnackBar.error(context, 'ФИО не может быть пустым');
            return;
          }
          ref.read(participantsProvider.notifier).update(p.id, (old) => old.copyWith(
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
            dogName: dogCtrl.text.trim().isNotEmpty ? dogCtrl.text.trim() : null,
            city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
            club: clubCtrl.text.trim().isNotEmpty ? clubCtrl.text.trim() : null,
            bib: bibCtrl.text.trim(),
            gender: selectedGender,
            birthDate: birthDate,
          ));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, '${nameCtrl.text.trim()} обновлён');
        },
      ),
    ], child: StatefulBuilder(builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: AppTextField(label: 'ФИО *', controller: nameCtrl)),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: AppTextField(label: 'BIB', controller: bibCtrl)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppSelect<String>(
          label: 'Пол',
          value: selectedGender,
          items: const [
            SelectItem(value: 'male', label: 'Мужской'),
            SelectItem(value: 'female', label: 'Женский'),
          ],
          onChanged: (v) => setModal(() => selectedGender = v),
        )),
        const SizedBox(width: 12),
        Expanded(child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: birthDate ?? DateTime(2000),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (picked != null) setModal(() => birthDate = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Дата рождения', border: OutlineInputBorder()),
            child: Text(
              birthDate != null
                  ? '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}'
                  : 'Выбрать',
              style: TextStyle(color: birthDate != null ? cs.onSurface : cs.outline),
            ),
          ),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(label: 'Телефон / Email', controller: phoneCtrl)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(label: 'Собака', controller: dogCtrl)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(label: 'Город', controller: cityCtrl)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(label: 'Клуб', controller: clubCtrl)),
      ]),
    ])));
  }

  // ─── Add participant ───
  void _showAddParticipant(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dogCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final clubCtrl = TextEditingController();
    String? selectedDisc;
    String? selectedGender;
    DateTime? birthDate;
    final disciplines = ref.read(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'Добавить участника', actions: [
      AppButton.primary(
        text: 'Добавить',
        onPressed: () {
          if (nameCtrl.text.trim().isEmpty) {
            AppSnackBar.error(context, 'Введите ФИО');
            return;
          }
          final eventConfig = ref.read(eventConfigProvider);
          final maxP = eventConfig.registrationConfig.maxParticipants;
          final participants = ref.read(participantsProvider);
          if (maxP != null && maxP > 0 && participants.length >= maxP) {
            AppSnackBar.error(context, 'Лимит участников ($maxP) исчерпан. Измените в настройках регистрации.');
            return;
          }
          final disc = disciplines.where((d) => d.id == selectedDisc).firstOrNull ?? disciplines.first;
          final nextBib = (participants.length + 1).toString().padLeft(2, '0');

          ref.read(participantsProvider.notifier).add(Participant(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
            disciplineId: disc.id,
            disciplineName: disc.name,
            bib: nextBib,
            dogName: dogCtrl.text.trim().isNotEmpty ? dogCtrl.text.trim() : null,
            gender: selectedGender,
            birthDate: birthDate,
            city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
            club: clubCtrl.text.trim().isNotEmpty ? clubCtrl.text.trim() : null,
            registeredAt: DateTime.now(),
          ));

          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, '${nameCtrl.text.trim()} добавлен');
        },
      ),
    ], child: StatefulBuilder(builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(label: 'ФИО *', controller: nameCtrl),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppSelect<String>(
          label: 'Пол',
          value: selectedGender,
          items: const [
            SelectItem(value: 'male', label: 'Мужской'),
            SelectItem(value: 'female', label: 'Женский'),
          ],
          onChanged: (v) => setModal(() => selectedGender = v),
        )),
        const SizedBox(width: 12),
        Expanded(child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: DateTime(2000),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
            );
            if (picked != null) setModal(() => birthDate = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Дата рождения', border: OutlineInputBorder()),
            child: Text(
              birthDate != null
                  ? '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}'
                  : 'Выбрать',
              style: TextStyle(color: birthDate != null ? cs.onSurface : cs.outline),
            ),
          ),
        )),
      ]),
      const SizedBox(height: 12),
      AppSelect<String>(
        label: 'Дисциплина *',
        value: selectedDisc,
        items: disciplines.map((d) => SelectItem(value: d.id, label: d.name)).toList(),
        onChanged: (v) => setModal(() => selectedDisc = v),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(label: 'Телефон / Email', controller: phoneCtrl)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(label: 'Собака', controller: dogCtrl)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(label: 'Город', controller: cityCtrl)),
        const SizedBox(width: 12),
        Expanded(child: AppTextField(label: 'Клуб', controller: clubCtrl)),
      ]),
    ])));
  }

  // ═══════════════════════════════════════════════════════════════
  // Multi-select helpers
  // ═══════════════════════════════════════════════════════════════

  void _exitSelectMode() => setState(() {
    _selectMode = false;
    _selected.clear();
  });

  Widget _buildBulkActionBar(BuildContext context, ColorScheme cs) {
    final n = _selected.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: Row(children: [
          Text('$n чел.', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(width: 12),
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _bulkChip(cs, Icons.wc, 'Пол', () => _showBulkGender(context)),
              const SizedBox(width: 8),
              _bulkChip(cs, Icons.payment, 'Оплата', () => _showBulkPayment(context)),
              const SizedBox(width: 8),
              _bulkChip(cs, Icons.verified_user, 'Заявка', () => _showBulkApplication(context)),
              const SizedBox(width: 8),
              _bulkChip(cs, Icons.delete_outline, 'Удалить', () => _showBulkDelete(context), isDestructive: true),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _bulkChip(ColorScheme cs, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? cs.error : cs.primary;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      onPressed: onTap,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }

  // ─── Bulk: Gender ───
  void _showBulkGender(BuildContext context) {
    AppBottomSheet.show(context, title: 'Установить пол (${_selected.length} чел.)', child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.male, color: Colors.blue),
        title: const Text('Мужской'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(gender: 'male'));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Пол → Мужской (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
      ListTile(
        leading: const Icon(Icons.female, color: Colors.pink),
        title: const Text('Женский'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(gender: 'female'));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Пол → Женский (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
    ]));
  }

  // ─── Bulk: Payment ───
  void _showBulkPayment(BuildContext context) {
    AppBottomSheet.show(context, title: 'Оплата (${_selected.length} чел.)', child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Отметить оплаченными'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(paymentStatus: PaymentStatus.paid));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Оплата ✓ (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
      ListTile(
        leading: Icon(Icons.cancel, color: Colors.orange.shade700),
        title: const Text('Отметить неоплаченными'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(paymentStatus: PaymentStatus.unpaid));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Оплата ✗ (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
    ]));
  }

  // ─── Bulk: Application status ───
  void _showBulkApplication(BuildContext context) {
    AppBottomSheet.show(context, title: 'Заявка (${_selected.length} чел.)', child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text('Подтвердить'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(applicationStatus: ApplicationStatus.approved));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Заявки подтверждены (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
      ListTile(
        leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
        title: const Text('На рассмотрении'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(applicationStatus: ApplicationStatus.pending));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Заявки → На рассмотрении (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
      ListTile(
        leading: const Icon(Icons.block, color: Colors.red),
        title: const Text('Отклонить'),
        onTap: () {
          ref.read(participantsProvider.notifier).bulkUpdate(_selected, (p) => p.copyWith(applicationStatus: ApplicationStatus.rejected));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Заявки отклонены (${_selected.length} чел.)');
          _exitSelectMode();
        },
      ),
    ]));
  }

  // ─── Bulk: Delete ───
  void _showBulkDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить участников?'),
      content: Text('Будет удалено ${_selected.length} участников. Это действие необратимо.'),
      actions: [
        AppButton.text(text: 'Отмена', onPressed: () => Navigator.pop(ctx)),
        AppButton.small(text: 'Удалить', onPressed: () {
          final count = _selected.length;
          ref.read(participantsProvider.notifier).bulkRemove(_selected);
          Navigator.pop(ctx);
          AppSnackBar.success(context, 'Удалено $count участников');
          _exitSelectMode();
        }),
      ],
    ));
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.people_outline, size: 48, color: cs.outline),
      const SizedBox(height: 8),
      Text('Нет участников', style: TextStyle(color: cs.outline)),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════
// Discipline Filter Chips
// ═══════════════════════════════════════════════════════════════
class _DisciplineChips extends StatelessWidget {
  final List<DisciplineConfig> disciplines;
  final String? selectedId;
  final int totalCount;
  final ValueChanged<String?> onSelected;

  const _DisciplineChips({
    required this.disciplines,
    required this.selectedId,
    required this.totalCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip(cs, 'Все ($totalCount)', selectedId == null, () => onSelected(null)),
          ...disciplines.map((d) =>
            _chip(cs, d.name, selectedId == d.id, () => onSelected(d.id)),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        )),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primary,
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        side: BorderSide.none,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

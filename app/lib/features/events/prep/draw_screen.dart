import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

// ─────────────────────────────────────────────────────────────────
// DRAW STATE
// ─────────────────────────────────────────────────────────────────

/// One participant entry in the draw.
class DrawEntry {
  final int position;
  final int bib;
  final String participantId;
  final String name;
  final String gender;
  final String dog;
  final String startTime;
  final String? category;
  final String? city;

  const DrawEntry({
    required this.position,
    required this.bib,
    required this.participantId,
    required this.name,
    required this.gender,
    required this.dog,
    required this.startTime,
    this.category,
    this.city,
  });

  DrawEntry copyWith({int? position, int? bib, String? startTime}) =>
      DrawEntry(
        position: position ?? this.position,
        bib: bib ?? this.bib,
        participantId: participantId,
        name: name,
        gender: gender,
        dog: dog,
        startTime: startTime ?? this.startTime,
        category: category,
        city: city,
      );
}

/// Draw result for one discipline.
class DrawResult {
  final String disciplineId;
  final String status; // 'pending', 'draft', 'approved'
  final List<DrawEntry> entries;

  const DrawResult({
    required this.disciplineId,
    this.status = 'pending',
    this.entries = const [],
  });

  DrawResult copyWith({String? status, List<DrawEntry>? entries}) =>
      DrawResult(
        disciplineId: disciplineId,
        status: status ?? this.status,
        entries: entries ?? this.entries,
      );
}

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

/// Screen P1: Жеребьёвка — connected to real participants.
class DrawScreen extends ConsumerStatefulWidget {
  const DrawScreen({super.key});

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  final Map<String, DrawResult> _results = {};
  String? _selectedDiscId;

  String _mode = 'auto';
  String _grouping = 'together';
  String _seeding = 'random';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initResults());
  }

  void _initResults() {
    final disciplines = ref.read(disciplineConfigsProvider);
    final participants = ref.read(participantsProvider);
    final config = ref.read(eventConfigProvider);

    for (final d in disciplines) {
      if (_results.containsKey(d.id)) continue;

      // Get real participants for this discipline
      final discParticipants = participants.where((p) => p.disciplineId == d.id).toList();
      final pool = config.bibPools.where((p) => p.disciplineId == d.id).firstOrNull
          ?? config.bibPools.firstOrNull;

      final entries = _buildEntries(discParticipants, d, pool);
      _results[d.id] = DrawResult(disciplineId: d.id, entries: entries);
    }
    if (mounted) setState(() {});
  }

  /// Build draw entries from real participants.
  List<DrawEntry> _buildEntries(List<Participant> participants, DisciplineConfig disc, BibPool? pool) {
    final bibStart = pool?.rangeStart ?? 1;
    final hour = disc.firstStartTime.hour;
    final minute = disc.firstStartTime.minute;
    final intervalSec = disc.interval.inSeconds;

    // Create entries from participants, shuffle for random draw
    final shuffled = List<Participant>.from(participants)..shuffle(Random());

    return List.generate(shuffled.length, (i) {
      final p = shuffled[i];
      final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      final s = totalSec % 60;

      return DrawEntry(
        position: i + 1,
        bib: bibStart + i,
        participantId: p.id,
        name: p.name,
        gender: p.gender == 'male' ? 'М' : p.gender == 'female' ? 'Ж' : '?',
        dog: p.dogName ?? '',
        startTime: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
        category: p.category,
        city: p.city,
      );
    });
  }

  void _openDiscipline(String id) => setState(() => _selectedDiscId = id);
  void _closeDiscipline() => setState(() => _selectedDiscId = null);

  void _reshuffle(DisciplineConfig disc) {
    final result = _results[disc.id];
    if (result == null) return;
    final entries = List<DrawEntry>.from(result.entries)..shuffle();
    final hour = disc.firstStartTime.hour;
    final minute = disc.firstStartTime.minute;
    final intervalSec = disc.interval.inSeconds;

    for (var i = 0; i < entries.length; i++) {
      final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      final s = totalSec % 60;
      entries[i] = entries[i].copyWith(
        position: i + 1,
        startTime: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
      );
    }

    // If grouping by gender — sort M first then Ж (or vice versa), then re-number
    if (_grouping == 'separate') {
      entries.sort((a, b) => a.gender.compareTo(b.gender));
      for (var i = 0; i < entries.length; i++) {
        final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
        final h = totalSec ~/ 3600;
        final m = (totalSec % 3600) ~/ 60;
        final s = totalSec % 60;
        entries[i] = entries[i].copyWith(
          position: i + 1,
          startTime: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
        );
      }
    }

    setState(() => _results[disc.id] = result.copyWith(status: 'draft', entries: entries));
    AppSnackBar.success(context, 'Жеребьёвка пересчитана — ${entries.length} участников');
  }

  void _approve(DisciplineConfig disc) {
    // When approved — write BIBs back to participants
    final result = _results[disc.id];
    if (result == null) return;
    final notifier = ref.read(participantsProvider.notifier);
    for (final entry in result.entries) {
      notifier.update(entry.participantId, (p) => p.copyWith(
        bib: entry.bib.toString(),
      ));
    }

    setState(() => _results[disc.id] = result.copyWith(status: 'approved'));
    AppSnackBar.success(context, '${disc.name} — жеребьёвка утверждена! BIB назначены.');
    Future.delayed(const Duration(milliseconds: 600), _closeDiscipline);
  }

  void _editPosition(DisciplineConfig disc, int index) {
    final result = _results[disc.id]!;
    final entry = result.entries[index];
    final posCtrl = TextEditingController(text: '${entry.position}');
    final bibCtrl = TextEditingController(text: '${entry.bib}');
    final timeCtrl = TextEditingController(text: entry.startTime);

    AppBottomSheet.show(context,
      title: '${entry.name} — BIB ${entry.bib}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: TextField(
            controller: posCtrl,
            decoration: const InputDecoration(labelText: 'Позиция', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: bibCtrl,
            decoration: const InputDecoration(labelText: 'BIB', border: OutlineInputBorder(), isDense: true),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: timeCtrl,
          decoration: const InputDecoration(labelText: 'Время старта', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            final entries = List<DrawEntry>.from(result.entries);
            entries[index] = entries[index].copyWith(
              position: int.tryParse(posCtrl.text) ?? entry.position,
              bib: int.tryParse(bibCtrl.text) ?? entry.bib,
              startTime: timeCtrl.text,
            );
            entries.sort((a, b) => a.position.compareTo(b.position));
            setState(() => _results[disc.id] = result.copyWith(status: 'draft', entries: entries));
          },
          icon: const Icon(Icons.save),
          label: const Text('Сохранить'),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _removeFromDraw(DisciplineConfig disc, int index) async {
    final result = _results[disc.id]!;
    final entry = result.entries[index];
    final confirm = await AppDialog.confirm(
      context,
      title: 'Убрать ${entry.name}?',
      message: 'BIB ${entry.bib} будет исключён из жеребьёвки.',
      confirmText: 'Убрать',
      isDanger: true,
    );
    if (confirm == true && mounted) {
      final entries = List<DrawEntry>.from(result.entries)..removeAt(index);
      for (var i = 0; i < entries.length; i++) {
        entries[i] = entries[i].copyWith(position: i + 1);
      }
      setState(() => _results[disc.id] = result.copyWith(entries: entries));
    }
  }

  @override
  Widget build(BuildContext context) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final participants = ref.watch(participantsProvider);
    final cs = Theme.of(context).colorScheme;

    final disc = _selectedDiscId != null
        ? disciplines.where((d) => d.id == _selectedDiscId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppAppBar(
        leading: _selectedDiscId == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: _closeDiscipline),
        title: Text(_selectedDiscId == null
            ? 'Жеребьёвка'
            : disc?.name ?? ''),
        actions: [
          if (disc != null && _results[disc.id]?.status == 'approved')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(Icons.check_circle, color: cs.primary, size: 18),
                label: Text('Утверждена', style: TextStyle(color: cs.primary, fontSize: 12)),
              ),
            ),
          if (_selectedDiscId == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить из участников',
              onPressed: () {
                _results.clear();
                _initResults();
                AppSnackBar.info(context, 'Список обновлён из участников (${participants.length})');
              },
            ),
        ],
      ),
      body: _selectedDiscId == null
          ? _buildGroupList(cs, disciplines, participants)
          : disc != null
              ? _buildEditor(cs, disc)
              : const SizedBox(),
    );
  }

  Widget _buildGroupList(ColorScheme cs, List<DisciplineConfig> disciplines, List<Participant> participants) {
    final approvedCount = _results.values.where((r) => r.status == 'approved').length;
    final totalCount = disciplines.length;

    return Column(children: [
      // Progress
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: approvedCount == totalCount
              ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
              : cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: approvedCount == totalCount
              ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
              : cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(approvedCount == totalCount ? Icons.check_circle : Icons.casino, color: approvedCount == totalCount ? const Color(0xFF2E7D32) : cs.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              approvedCount == totalCount ? 'Все жеребьёвки утверждены!' : '$approvedCount из $totalCount утверждено',
              style: TextStyle(fontWeight: FontWeight.bold, color: approvedCount == totalCount ? const Color(0xFF2E7D32) : cs.primary),
            ),
            Text(
              'Всего ${participants.length} участников зарегистрировано',
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ])),
        ]),
      ),

      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: disciplines.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = disciplines[i];
          final result = _results[d.id];
          final status = result?.status ?? 'pending';
          final count = result?.entries.length ?? 0;
          final regCount = participants.where((p) => p.disciplineId == d.id).length;
          final isApproved = status == 'approved';

          final (statusColor, statusIcon, statusText) = switch (status) {
            'approved' => (const Color(0xFF2E7D32), Icons.check_circle, 'Утверждена'),
            'draft' => (cs.tertiary, Icons.edit_note, 'Черновик'),
            _ => (cs.outline, Icons.hourglass_empty, 'Ожидает'),
          };

          return Card(
            elevation: isApproved ? 0 : 2,
            color: isApproved ? const Color(0xFF2E7D32).withValues(alpha: 0.05) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isApproved ? BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openDiscipline(d.id),
              child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: [
                    Text('$regCount зарег.', style: TextStyle(color: cs.outline, fontSize: 12)),
                    if (count != regCount) ...[
                      Text('·', style: TextStyle(color: cs.outline)),
                      Text('$count в жеребьёвке', style: TextStyle(color: cs.primary, fontSize: 12)),
                    ],
                    Text('·', style: TextStyle(color: cs.outline)),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                    if (d.dayNumber != null) ...[
                      Text('·', style: TextStyle(color: cs.outline)),
                      Text('День ${d.dayNumber}', style: TextStyle(color: cs.outline, fontSize: 12)),
                    ],
                  ]),
                ])),
                Icon(Icons.chevron_right, color: cs.outline),
              ])),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildEditor(ColorScheme cs, DisciplineConfig disc) {
    final result = _results[disc.id]!;
    final isApproved = result.status == 'approved';
    final entries = result.entries;

    final maleCount = entries.where((e) => e.gender == 'М').length;
    final femaleCount = entries.where((e) => e.gender == 'Ж').length;

    return Column(children: [
      // Stats bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: cs.primaryContainer.withValues(alpha: 0.1),
        child: Row(children: [
          Icon(Icons.people, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text('${entries.length} участников', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
          const Spacer(),
          Text('$maleCount М', style: TextStyle(fontSize: 12, color: cs.primary)),
          const SizedBox(width: 8),
          Text('$femaleCount Ж', style: TextStyle(fontSize: 12, color: cs.tertiary)),
        ]),
      ),

      // Settings card
      Card(
        margin: const EdgeInsets.all(8),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Режим', border: OutlineInputBorder(), isDense: true),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Авто')),
                DropdownMenuItem(value: 'manual', child: Text('Ручная')),
                DropdownMenuItem(value: 'seed', child: Text('По рейтингу')),
              ],
              initialValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Группировка', border: OutlineInputBorder(), isDense: true),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'together', child: Text('Вместе')),
                DropdownMenuItem(value: 'separate', child: Text('М / Ж раздельно')),
              ],
              initialValue: _grouping,
              onChanged: (v) => setState(() => _grouping = v!),
            )),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Посев', border: OutlineInputBorder(), isDense: true),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Случайный')),
                DropdownMenuItem(value: 'rating', child: Text('По рейтингу')),
                DropdownMenuItem(value: 'bib', child: Text('По номеру BIB')),
              ],
              initialValue: _seeding,
              onChanged: (v) => setState(() => _seeding = v!),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                Icon(Icons.schedule, size: 16, color: cs.outline),
                const SizedBox(width: 6),
                Text(
                  'Инт. ${disc.interval.inSeconds}с',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
              ]),
            )),
          ]),
        ])),
      ),

      // Empty state
      if (entries.isEmpty)
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 48, color: cs.outline),
          const SizedBox(height: 12),
          Text('Нет участников в этой дисциплине', style: TextStyle(color: cs.outline, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Добавьте участников через Управлять → Участники', style: TextStyle(color: cs.outline, fontSize: 12)),
        ])))

      // Athlete list
      else Expanded(child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: entries.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          setState(() {
            final list = List<DrawEntry>.from(entries);
            final item = list.removeAt(oldIndex);
            list.insert(newIndex, item);
            _recalcTimes(list, disc);
            _results[disc.id] = result.copyWith(status: 'draft', entries: list);
          });
        },
        itemBuilder: (context, i) {
          final entry = entries[i];
          final isFemale = entry.gender == 'Ж';
          final color = isFemale ? cs.tertiary : cs.primary;

          return ListTile(
            key: ValueKey('draw-${entry.participantId}'),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text('${entry.position}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ),
            title: Text('${entry.name}  (${entry.gender})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              [
                'BIB ${entry.bib}',
                if (entry.dog.isNotEmpty) entry.dog,
                entry.startTime,
                if (entry.city != null && entry.city!.isNotEmpty) entry.city,
              ].join('  ·  '),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editPosition(disc, i)),
              IconButton(icon: Icon(Icons.close, size: 18, color: cs.error), onPressed: () => _removeFromDraw(disc, i)),
              const Icon(Icons.drag_handle),
            ]),
          );
        },
      )),

      // Bottom actions
      SafeArea(child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: entries.isEmpty ? null : () => _reshuffle(disc),
            icon: const Icon(Icons.refresh),
            label: const Text('Провести'),
          )),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(
            onPressed: entries.isEmpty || isApproved ? null : () => _approve(disc),
            icon: Icon(isApproved ? Icons.check : Icons.gavel),
            label: Text(isApproved ? 'Утверждено' : 'Утвердить'),
          )),
        ]),
      )),
    ]);
  }

  void _recalcTimes(List<DrawEntry> list, DisciplineConfig disc) {
    final hour = disc.firstStartTime.hour;
    final minute = disc.firstStartTime.minute;
    final intervalSec = disc.interval.inSeconds;
    for (var i = 0; i < list.length; i++) {
      final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
      list[i] = list[i].copyWith(
        position: i + 1,
        startTime: '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:${((totalSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}',
      );
    }
  }
}

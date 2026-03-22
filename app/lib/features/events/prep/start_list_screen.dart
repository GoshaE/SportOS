import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';
import '../../../domain/timing/result_table.dart';

/// P2 — Стартовый лист, подключён к реальным участникам.
///
/// Берёт дисциплины и участников из провайдеров,
/// формирует стартовый лист по BIB-пулам и интервалам.
class StartListScreen extends ConsumerStatefulWidget {
  const StartListScreen({super.key});

  @override
  ConsumerState<StartListScreen> createState() => _StartListScreenState();
}

class _StartListScreenState extends ConsumerState<StartListScreen> {
  final Map<String, List<Map<String, dynamic>>> _lists = {};
  String? _selectedDiscId;
  bool _showCards = false;
  bool _published = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  void _generate() {
    final disciplines = ref.read(disciplineConfigsProvider);
    final participants = ref.read(participantsProvider);
    final config = ref.read(eventConfigProvider);

    for (final d in disciplines) {
      if (_lists.containsKey(d.id)) continue;

      // Get real participants for this discipline
      final discParticipants = participants.where((p) => p.disciplineId == d.id).toList();
      final pool = config.bibPools.where((p) => p.disciplineId == d.id).firstOrNull
          ?? config.bibPools.firstOrNull;
      final bibStart = pool?.rangeStart ?? 1;
      final intervalSec = d.interval.inSeconds;
      final hour = d.firstStartTime.hour;
      final minute = d.firstStartTime.minute;

      final list = <Map<String, dynamic>>[];
      for (var i = 0; i < discParticipants.length; i++) {
        final p = discParticipants[i];
        final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
        // Use BIB from participant if already assigned (after draw), otherwise sequential
        final bib = p.bib.isNotEmpty ? p.bib : '${bibStart + i}';
        list.add({
          'pos': i + 1,
          'bib': bib,
          'name': p.name,
          'gender': p.gender == 'male' ? 'М' : p.gender == 'female' ? 'Ж' : '?',
          'dog': p.dogName ?? '',
          'city': p.city ?? '',
          'time': '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:${((totalSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}',
          'status': 'confirmed',
          'participantId': p.id,
        });
      }
      _lists[d.id] = list;
    }
    if (disciplines.isNotEmpty) {
      _selectedDiscId ??= disciplines.first.id;
    }
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _currentList => _lists[_selectedDiscId] ?? [];
  DisciplineConfig? get _currentDisc {
    final disciplines = ref.read(disciplineConfigsProvider);
    return disciplines.where((d) => d.id == _selectedDiscId).firstOrNull;
  }

  void _showAddLateAthlete() {
    final nameCtrl = TextEditingController();
    final dogCtrl = TextEditingController();
    final list = _currentList;
    final disc = _currentDisc;
    if (disc == null) return;

    final regConfig = ref.read(eventConfigProvider).registrationConfig;

    AppBottomSheet.show(context, title: 'Добавить спортсмена', child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(label: 'ФИО *', controller: nameCtrl),
      if (regConfig.fieldDogName != FieldVisibility.hidden) ...[
        const SizedBox(height: 12),
        AppTextField(label: regConfig.fieldDogName == FieldVisibility.required ? 'Кличка собаки *' : 'Кличка собаки', controller: dogCtrl),
      ],
      const SizedBox(height: 16),
      AppButton.primary(
        text: 'Добавить',
        icon: Icons.add,
        onPressed: () {
          if (nameCtrl.text.isEmpty) { AppSnackBar.error(context, 'Заполните ФИО'); return; }
          final lastPos = list.isEmpty ? 0 : list.last['pos'] as int;
          final intervalSec = disc.interval.inSeconds;
          final h = disc.firstStartTime.hour;
          final m = disc.firstStartTime.minute;
          final totalSec = h * 3600 + m * 60 + lastPos * intervalSec;
          final nextBib = list.isEmpty ? 1 : (int.tryParse(list.last['bib'] ?? '0') ?? 0) + 1;

          // Also add to participants provider
          final p = Participant(
            id: 'p-late-${DateTime.now().millisecondsSinceEpoch}',
            name: nameCtrl.text,
            disciplineId: disc.id,
            disciplineName: disc.name,
            bib: '$nextBib',
            dogName: dogCtrl.text.isEmpty ? null : dogCtrl.text,
            registeredAt: DateTime.now(),
          );
          ref.read(participantsProvider.notifier).add(p);

          setState(() {
            list.add({
              'pos': lastPos + 1,
              'bib': '$nextBib',
              'name': nameCtrl.text,
              'gender': '?',
              'dog': dogCtrl.text,
              'city': '',
              'time': '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:${((totalSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}',
              'status': 'late_add',
              'participantId': p.id,
            });
          });
          Navigator.pop(context);
          AppSnackBar.success(context, '${nameCtrl.text} (BIB $nextBib) добавлен');
        },
      ),
      const SizedBox(height: 8),
    ]));
  }

  void _showEditRow(int index) {
    final list = _currentList;
    final a = list[index];
    final posCtrl = TextEditingController(text: '${a['pos']}');
    final timeCtrl = TextEditingController(text: a['time']);
    final bibCtrl = TextEditingController(text: a['bib']);

    AppBottomSheet.show(context, title: '${a['name']} (BIB ${a['bib']})', child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(label: 'Позиция', controller: posCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      AppTextField(label: 'BIB', controller: bibCtrl),
      const SizedBox(height: 12),
      AppTextField(label: 'Время старта', controller: timeCtrl),
      const SizedBox(height: 16),
      AppButton.primary(
        text: 'Сохранить',
        icon: Icons.save,
        onPressed: () {
          setState(() {
            a['pos'] = int.tryParse(posCtrl.text) ?? a['pos'];
            a['bib'] = bibCtrl.text;
            a['time'] = timeCtrl.text;
            list.sort((ca, cb) => (ca['pos'] as int).compareTo(cb['pos'] as int));
          });
          Navigator.pop(context);
          AppSnackBar.success(context, 'Стартовый лист скорректирован');
        },
      ),
      const SizedBox(height: 8),
    ]));
  }

  void _publish() {
    setState(() => _published = true);
    AppSnackBar.success(context, 'Стартовый лист опубликован! 🎉');
  }

  void _refresh() {
    _lists.clear();
    _generate();
    AppSnackBar.info(context, 'Стартовый лист обновлён из участников');
  }

  @override
  Widget build(BuildContext context) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    final list = _currentList;
    final disc = _currentDisc;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Стартовый лист'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить из участников',
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(_showCards ? Icons.table_rows : Icons.view_agenda_outlined),
            tooltip: 'Вид',
            onPressed: () => setState(() => _showCards = !_showCards),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Экспорт PDF',
            onPressed: () => AppSnackBar.info(context, 'PDF → Печать'),
          ),
          if (!_published)
            IconButton(
              icon: const Icon(Icons.publish),
              tooltip: 'Опубликовать',
              onPressed: _publish,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLateAthlete,
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить'),
      ),
      body: Column(children: [
        // Published banner
        if (_published)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Стартовый лист опубликован', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF2E7D32))),
              const Spacer(),
              AppButton.text(text: 'Снять', onPressed: () => setState(() => _published = false)),
            ]),
          ),

        // Discipline chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: disciplines.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final d = disciplines[i];
              final isSelected = d.id == _selectedDiscId;
              final count = (_lists[d.id] ?? []).length;
              return ChoiceChip(
                label: Text('${d.name} ($count)', style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : null)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDiscId = d.id),
              );
            },
          ),
        ),

        // Info bar
        if (disc != null) Container(
          color: cs.surfaceContainerHighest.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Icon(Icons.timer, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text('Инт. ${disc.interval.inSeconds}с', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(width: 16),
            Icon(Icons.schedule, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              'Старт ${disc.firstStartTime.hour.toString().padLeft(2, '0')}:${disc.firstStartTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary),
            ),
            const Spacer(),
            Text('${list.length} чел.', style: TextStyle(fontSize: 12, color: cs.outline)),
          ]),
        ),

        // Table
        Expanded(
          child: list.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_outline, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('Нет участников в этой дисциплине', style: TextStyle(color: cs.outline, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Добавьте участников через Управлять → Участники', style: TextStyle(color: cs.outline, fontSize: 12)),
                ]))
              : Builder(builder: (context) {
                  final regConfig = ref.read(eventConfigProvider).registrationConfig;
                  final showDog = regConfig.fieldDogName != FieldVisibility.hidden;
                  final columns = <ColumnDef>[
                    const ColumnDef(id: 'pos', label: '№', type: ColumnType.number, align: ColumnAlign.center, flex: 0.5, minWidth: 40),
                    const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 50),
                    const ColumnDef(id: 'name', label: 'ФИО', type: ColumnType.text, align: ColumnAlign.left, flex: 2.0, minWidth: 140),
                    if (showDog)
                      const ColumnDef(id: 'dog', label: 'Собака', type: ColumnType.text, align: ColumnAlign.left, flex: 1.2, minWidth: 100),
                    const ColumnDef(id: 'time', label: 'Старт', type: ColumnType.time, align: ColumnAlign.right, flex: 1.0, minWidth: 75),
                    const ColumnDef(id: 'status', label: 'Статус', type: ColumnType.text, align: ColumnAlign.center, flex: 0.8, minWidth: 60),
                  ];

                  final rows = list.asMap().entries.map((e) {
                    final a = e.value;
                    final isLate = a['status'] == 'late_add';
                    return ResultRow(
                      entryId: 'sl-${e.key}',
                      cells: {
                        'pos': CellValue(raw: a['pos'], display: '${a['pos']}'),
                        'bib': CellValue(raw: a['bib'], display: a['bib'] as String),
                        'name': CellValue(raw: a['name'], display: a['name'] as String),
                        'dog': CellValue(raw: a['dog'], display: a['dog'] as String),
                        'time': CellValue(raw: a['time'], display: a['time'] as String),
                        'status': CellValue(
                          display: isLate ? 'ДОП.' : 'Подтв.',
                          style: isLate ? CellStyle.highlight : CellStyle.normal,
                        ),
                      },
                    );
                  }).toList();

                  return AppResultTable(
                    table: ResultTable(columns: columns, rows: rows),
                    showCards: _showCards,
                    onRowTap: (row) {
                      final idx = list.indexWhere((a) => 'sl-${list.indexOf(a)}' == row.entryId);
                      if (idx >= 0) _showEditRow(idx);
                    },
                  );
                }),
        ),

        // Footer stats
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(8),
          child: SafeArea(
            top: false,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Всего', '${list.length}', cs.onSurface),
              _stat('Подтв.', '${list.where((a) => a['status'] == 'confirmed').length}', cs.primary),
              _stat('Доп.', '${list.where((a) => a['status'] == 'late_add').length}', cs.tertiary),
              if (_published)
                _stat('Статус', 'Опубликован', const Color(0xFF2E7D32)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
    ]);
  }
}

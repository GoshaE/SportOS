import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

/// P2 — Стартовый лист, подключён к Config Engine.
///
/// Берёт дисциплины из провайдера, формирует стартовый лист
/// по BIB-пулам и интервалам, позволяет добавлять/редактировать,
/// показывает таблицу (card/table) с фильтрацией по дисциплине.
class StartListScreen extends ConsumerStatefulWidget {
  const StartListScreen({super.key});

  @override
  ConsumerState<StartListScreen> createState() => _StartListScreenState();
}

class _StartListScreenState extends ConsumerState<StartListScreen> {
  final Map<String, List<Map<String, dynamic>>> _lists = {};
  String? _selectedDiscId;
  bool _isTableView = false;
  bool _initialized = false;
  bool _published = false;

  // Demo names for generation
  static const _demoAthletes = [
    ('Петров А.А.', 'М', 'Rex'),    ('Иванов В.В.', 'М', 'Storm'),
    ('Волкова Е.Е.', 'Ж', 'Alaska'),('Сидоров Б.Б.', 'М', 'Luna'),
    ('Козлов Г.Г.', 'М', 'Wolf'),   ('Новикова З.З.', 'Ж', 'Rocky'),
    ('Белов Д.Д.', 'М', 'Husky'),   ('Орлова М.М.', 'Ж', 'Sky'),
    ('Фролов К.К.', 'М', 'Flash'),  ('Морозова С.С.', 'Ж', 'Nina'),
    ('Тихонов Л.Л.', 'М', 'King'),  ('Зайцева Ю.Ю.', 'Ж', 'Maya'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  void _generate() {
    final disciplines = ref.read(disciplineConfigsProvider);
    final config = ref.read(eventConfigProvider);

    for (final d in disciplines) {
      if (_lists.containsKey(d.id)) continue;

      final pool = config.bibPools.where((p) => p.disciplineId == d.id).firstOrNull
          ?? config.bibPools.firstOrNull;
      final count = d.maxParticipants?.clamp(4, 12) ?? 8;
      final bibStart = pool?.rangeStart ?? 1;
      final intervalSec = d.interval.inSeconds;
      final hour = d.firstStartTime.hour;
      final minute = d.firstStartTime.minute;

      final list = <Map<String, dynamic>>[];
      for (var i = 0; i < count; i++) {
        final name = _demoAthletes[i % _demoAthletes.length];
        final totalSec = hour * 3600 + minute * 60 + i * intervalSec;
        list.add({
          'pos': i + 1,
          'bib': '${bibStart + i}',
          'name': name.$1,
          'gender': name.$2,
          'dog': name.$3,
          'time': '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:${((totalSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}',
          'status': 'confirmed',
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
    final cs = Theme.of(context).colorScheme;
    final list = _currentList;
    final disc = _currentDisc;
    if (disc == null) return;

    AppBottomSheet.show(context, title: 'Добавить спортсмена', child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Будет добавлен в конец стартового листа', style: TextStyle(color: cs.outline, fontSize: 12)),
      const SizedBox(height: 12),
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: dogCtrl, decoration: const InputDecoration(labelText: 'Кличка собаки *', border: OutlineInputBorder())),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () {
          if (nameCtrl.text.isEmpty) { AppSnackBar.error(context, 'Заполните ФИО'); return; }
          final lastPos = list.isEmpty ? 0 : list.last['pos'] as int;
          final intervalSec = disc.interval.inSeconds;
          final h = disc.firstStartTime.hour;
          final m = disc.firstStartTime.minute;
          final totalSec = h * 3600 + m * 60 + lastPos * intervalSec;
          final nextBib = list.isEmpty ? 1 : (int.tryParse(list.last['bib'] ?? '0') ?? 0) + 1;

          setState(() {
            list.add({
              'pos': lastPos + 1,
              'bib': '$nextBib',
              'name': nameCtrl.text,
              'gender': '?',
              'dog': dogCtrl.text,
              'time': '${(totalSec ~/ 3600).toString().padLeft(2, '0')}:${((totalSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(totalSec % 60).toString().padLeft(2, '0')}',
              'status': 'late_add',
            });
          });
          Navigator.pop(context);
          AppSnackBar.success(context, '${nameCtrl.text} (BIB $nextBib) добавлен');
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      )),
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
      TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Позиция', border: OutlineInputBorder()), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      TextField(controller: bibCtrl, decoration: const InputDecoration(labelText: 'BIB', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Время старта', border: OutlineInputBorder())),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
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
        icon: const Icon(Icons.save),
        label: const Text('Сохранить'),
      )),
      const SizedBox(height: 8),
    ]));
  }

  void _publish() {
    setState(() => _published = true);
    AppSnackBar.success(context, 'Стартовый лист опубликован! 🎉');
  }

  @override
  Widget build(BuildContext context) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;

    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }
    final list = _currentList;
    final disc = _currentDisc;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Стартовый лист'),
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows),
            tooltip: 'Вид',
            onPressed: () => setState(() => _isTableView = !_isTableView),
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
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Стартовый лист опубликован', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF2E7D32))),
              const Spacer(),
              TextButton(onPressed: () => setState(() => _published = false), child: const Text('Снять', style: TextStyle(fontSize: 11))),
            ]),
          ),

        // Discipline chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: disciplines.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final d = disciplines[i];
              final isSelected = d.id == _selectedDiscId;
              return ChoiceChip(
                label: Text(d.name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : null)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDiscId = d.id),
              );
            },
          ),
        ),

        // Info bar
        if (disc != null) Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
              ? Center(child: Text('Нет участников', style: TextStyle(color: cs.outline)))
              : SingleChildScrollView(
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
                    itemCount: list.length,
                    itemBuilder: (context, index, isCard) {
                      final a = list[index];
                      final isLate = a['status'] == 'late_add';

                      return AppProtocolRow(
                        isCardView: isCard,
                        place: a['pos'] as int,
                        bib: a['bib'] as String,
                        name: a['name'] as String,
                        cat: isLate ? 'ДОП.' : '',
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
      Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P1 — Жеребьёвка
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final List<Map<String, dynamic>> _groups = [
    {'id': 'g1', 'title': 'Скиджоринг 5км', 'count': 8, 'status': 'pending'},
    {'id': 'g2', 'title': 'Каникросс 3км', 'count': 12, 'status': 'approved'},
    {'id': 'g3', 'title': 'Нарты 2 собаки', 'count': 5, 'status': 'pending'},
  ];

  String? _selectedGroupId;
  String _mode = 'auto';
  String _grouping = 'together';
  String _seeding = 'random';
  String _startInterval = '30с';
  String _firstStart = '10:00:00';
  int _currentDay = 1;
  final int _totalDays = 2;
  String _day2Order = 'same';
  List<Map<String, dynamic>> _athletes = [];

  void _openGroup(String id) {
    setState(() {
      _selectedGroupId = id;
      _athletes = [
        {'pos': 1, 'bib': '07', 'name': 'Петров А.А.', 'gender': 'М', 'dog': 'Rex', 'time': '10:00:00', 'rating': 1250},
        {'pos': 2, 'bib': '24', 'name': 'Иванов В.В.', 'gender': 'М', 'dog': 'Storm', 'time': '10:00:30', 'rating': 1180},
        {'pos': 3, 'bib': '55', 'name': 'Волкова Е.Е.', 'gender': 'Ж', 'dog': 'Alaska', 'time': '10:01:00', 'rating': 1320},
        {'pos': 4, 'bib': '12', 'name': 'Сидоров Б.Б.', 'gender': 'М', 'dog': 'Luna', 'time': '10:01:30', 'rating': 1100},
        {'pos': 5, 'bib': '31', 'name': 'Козлов Г.Г.', 'gender': 'М', 'dog': 'Wolf', 'time': '10:02:00', 'rating': 1050},
        {'pos': 6, 'bib': '77', 'name': 'Новикова З.З.', 'gender': 'Ж', 'dog': 'Rocky', 'time': '10:02:30', 'rating': 1010},
      ];
      if (_groups.firstWhere((g) => g['id'] == id)['status'] == 'approved') {
        _athletes.shuffle();
      } else {
        for (var i = 0; i < _athletes.length; i++) { _athletes[i]['time'] = '--:--:--'; _athletes[i]['pos'] = 0; }
      }
    });
  }

  void _closeGroup() => setState(() => _selectedGroupId = null);

  void _reshuffle() {
    setState(() {
      _athletes.shuffle();
      for (var i = 0; i < _athletes.length; i++) {
        _athletes[i]['pos'] = i + 1;
        final sec = 10 * 60 + i * 30;
        _athletes[i]['time'] = '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}:00';
      }
      _groups.firstWhere((g) => g['id'] == _selectedGroupId)['status'] = 'draft';
    });
    AppSnackBar.success(context, 'Жеребьёвка пересчитана');
  }

  void _approve() {
    setState(() => _groups.firstWhere((g) => g['id'] == _selectedGroupId)['status'] = 'approved');
    AppSnackBar.success(context, 'Жеребьёвка группы утверждена!');
    Future.delayed(const Duration(seconds: 1), _closeGroup);
  }

  void _editPosition(int index) {
    final isApproved = _groups.firstWhere((g) => g['id'] == _selectedGroupId)['status'] == 'approved';
    final posCtrl = TextEditingController(text: '${_athletes[index]['pos']}');
    final timeCtrl = TextEditingController(text: _athletes[index]['time']);
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: 'BIB ${_athletes[index]['bib']} — ${_athletes[index]['name']}',
      initialHeight: 0.6,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            setState(() {
              _athletes[index]['pos'] = int.tryParse(posCtrl.text) ?? _athletes[index]['pos'];
              _athletes[index]['time'] = timeCtrl.text;
              _athletes.sort((a, b) => (a['pos'] as int).compareTo(b['pos'] as int));
            });
            AppSnackBar.success(context, 'Позиция BIB ${_athletes[index]['bib']} изменена');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Позиция (1-N)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Время старта', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Причина корректировки', border: OutlineInputBorder(), hintText: 'Ошибка при жеребьёвке, перестановка...'), maxLines: 2),
            ]
          ),
          if (isApproved) ...[
            const SizedBox(height: 12),
            Text('Внимание: жеребьёвка уже утверждена! Изменение будет записано в Audit Log.', style: TextStyle(color: cs.tertiary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  void _removeFromDraw(int index) async {
    final removed = _athletes[index]['name'];
    final confirm = await AppDialog.confirm(
      context,
      title: 'Убрать BIB ${_athletes[index]['bib']}?',
      message: '$removed будет исключён из жеребьёвки.\nОн может быть добавлен обратно позже.',
      confirmText: 'Убрать',
      isDanger: true,
    );
    
    if (confirm == true && mounted) {
      setState(() {
        _athletes.removeAt(index);
        for (var i = 0; i < _athletes.length; i++) {
          _athletes[i]['pos'] = i + 1;
        }
        _groups.firstWhere((g) => g['id'] == _selectedGroupId)['count'] = _athletes.length;
      });
      AppSnackBar.error(context, '$removed убран из жеребьёвки');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return Scaffold(
      appBar: AppAppBar(
        leading: _selectedGroupId == null
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/manage/$eventId'))
          : IconButton(icon: const Icon(Icons.close), onPressed: _closeGroup),
        title: Text(_selectedGroupId == null ? 'Жеребьёвка (Группы)' : _groups.firstWhere((g) => g['id'] == _selectedGroupId)['title']),
        actions: _selectedGroupId != null ? [
          if (_groups.firstWhere((g) => g['id'] == _selectedGroupId)['status'] == 'approved')
            Padding(padding: const EdgeInsets.only(right: 8), child: Chip(avatar: Icon(Icons.check_circle, color: cs.primary, size: 18), label: Text('Утверждена', style: TextStyle(color: cs.primary, fontSize: 12)))),
        ] : null,
      ),
      body: _selectedGroupId == null ? _buildGroupList(cs, eventId) : _buildEditor(cs),
    );
  }

  Widget _buildGroupList(ColorScheme cs, String eventId) {
    return Column(children: [
      AppInfoBanner.info(title: 'Выберите группу участников для проведения жеребьёвки. После утверждения всех групп можно переходить к стартовым листам.'),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.all(8), itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final g = _groups[i];
          final isApproved = g['status'] == 'approved';
          final isDraft = g['status'] == 'draft';
          Color statusColor = cs.onSurfaceVariant;
          IconData statusIcon = Icons.hourglass_empty;
          String statusText = 'Ожидает';
          if (isApproved) { statusColor = cs.primary; statusIcon = Icons.check_circle; statusText = 'Утверждена'; }
          else if (isDraft) { statusColor = cs.tertiary; statusIcon = Icons.edit_note; statusText = 'Черновик (не утв.)'; }

          return Card(
            elevation: isApproved ? 0 : 2,
            color: isApproved ? cs.primary.withValues(alpha: 0.05) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isApproved ? BorderSide(color: cs.primary.withValues(alpha: 0.3)) : BorderSide.none),
            child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => _openGroup(g['id']), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.1), child: Icon(statusIcon, color: statusColor)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${g['count']} участников  ·  $statusText', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ])),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ]))),
          );
        },
      )),
    ]);
  }

  Widget _buildEditor(ColorScheme cs) {
    final group = _groups.firstWhere((g) => g['id'] == _selectedGroupId);
    final isApproved = group['status'] == 'approved';

    return Column(children: [
      if (_totalDays > 1) Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: cs.secondaryContainer.withValues(alpha: 0.15),
        child: Row(children: [
          Icon(Icons.calendar_month, size: 18, color: cs.secondary),
          const SizedBox(width: 8),
          ...List.generate(_totalDays, (d) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
            label: Text('День ${d + 1}', style: TextStyle(fontSize: 12, color: _currentDay == d + 1 ? cs.onPrimary : null)),
            selected: _currentDay == d + 1, onSelected: (_) => setState(() => _currentDay = d + 1),
          ))),
          const Spacer(),
          if (_currentDay > 1) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('Порядок: $_day2OrderLabel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.tertiary)),
          ),
        ]),
      ),
      Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(children: [Expanded(child: DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Режим', border: OutlineInputBorder(), isDense: true), isExpanded: true, items: const [
          DropdownMenuItem(value: 'auto', child: Text('Автоматическая')), DropdownMenuItem(value: 'manual', child: Text('Ручная')), DropdownMenuItem(value: 'seed', child: Text('По рейтингу')),
        ], initialValue: _mode, onChanged: (v) => setState(() => _mode = v!)))]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Группировка М/Ж', border: OutlineInputBorder(), isDense: true), isExpanded: true, items: const [
            DropdownMenuItem(value: 'together', child: Text('Вместе')), DropdownMenuItem(value: 'separate', child: Text('Раздельно')),
            DropdownMenuItem(value: 'men_first', child: Text('Сначала М')), DropdownMenuItem(value: 'women_first', child: Text('Сначала Ж')),
          ], initialValue: _grouping, onChanged: (v) => setState(() => _grouping = v!))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Посев', border: OutlineInputBorder(), isDense: true), isExpanded: true, items: const [
            DropdownMenuItem(value: 'random', child: Text('Случайный')), DropdownMenuItem(value: 'rating', child: Text('По рейтингу')),
            DropdownMenuItem(value: 'bib', child: Text('По номеру BIB')), DropdownMenuItem(value: 'alpha', child: Text('По алфавиту')),
          ], initialValue: _seeding, onChanged: (v) => setState(() => _seeding = v!))),
        ]),
        if (_currentDay > 1) ...[const SizedBox(height: 8), DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Порядок старта дня 2', border: OutlineInputBorder(), isDense: true), isExpanded: true, items: const [
          DropdownMenuItem(value: 'same', child: Text('Такой же как день 1')), DropdownMenuItem(value: 'reverse', child: Text('Обратный (лидер последний)')),
          DropdownMenuItem(value: 'gundersen', child: Text('Гундерсен (по отставанию)')), DropdownMenuItem(value: 'new_draw', child: Text('Новая жеребьёвка')),
        ], initialValue: _day2Order, onChanged: (v) => setState(() => _day2Order = v!))],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Интервал старта', border: OutlineInputBorder(), isDense: true), isExpanded: true, items: const [
            DropdownMenuItem(value: '15с', child: Text('15 сек')), DropdownMenuItem(value: '30с', child: Text('30 сек')),
            DropdownMenuItem(value: '1м', child: Text('1 мин')), DropdownMenuItem(value: '2м', child: Text('2 мин')), DropdownMenuItem(value: '3м', child: Text('3 мин')),
          ], initialValue: _startInterval, onChanged: (v) => setState(() => _startInterval = v!))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(initialValue: _firstStart, decoration: const InputDecoration(labelText: 'Первый старт', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.schedule, size: 18)), onChanged: (v) => _firstStart = v)),
        ]),
      ]))),

      if (_currentDay > 1 && _day2Order == 'gundersen') Container(
        padding: const EdgeInsets.all(8), margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: cs.secondaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.secondary.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Гундерсен (Pursuit Start)', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Лидер дня 1 стартует первым. Остальные стартуют с отставанием по времени от дня 1.\nПример: лидер → 00:00, 2-й (+1:33) → через 1:33, 3-й (+2:50) → через 2:50.', style: TextStyle(fontSize: 11)),
        ]),
      ),

      Expanded(child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: _athletes.length,
        onReorder: (oldIndex, newIndex) { setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _athletes.removeAt(oldIndex); _athletes.insert(newIndex, item);
          for (var i = 0; i < _athletes.length; i++) {
            _athletes[i]['pos'] = i + 1;
          }
          group['status'] = 'draft';
        }); },
        itemBuilder: (context, i) {
          final a = _athletes[i];
          final isFemale = a['gender'] == 'Ж';
          return ListTile(
            key: ValueKey('draw-${a['bib']}'),
            leading: CircleAvatar(
              backgroundColor: (isFemale ? cs.tertiary : cs.primary).withValues(alpha: 0.15),
              child: Text('${a['pos'] > 0 ? a['pos'] : '-'}', style: TextStyle(fontWeight: FontWeight.bold, color: isFemale ? cs.tertiary : cs.primary)),
            ),
            title: Text('${a['name']}  (${a['gender']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('BIB ${a['bib']}  ·  ${a['dog']}  ·  Старт: ${a['time']}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), tooltip: 'Редактировать позицию', onPressed: () => _editPosition(i)),
              IconButton(icon: Icon(Icons.close, size: 20, color: cs.error), tooltip: 'Убрать из жеребьёвки', onPressed: () => _removeFromDraw(i)),
              const Icon(Icons.drag_handle),
            ]),
          );
        },
      )),

      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _currentDay > 1 && _day2Order == 'same' ? null : _reshuffle, icon: const Icon(Icons.refresh), label: const Text('Провести'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: isApproved ? cs.onSurfaceVariant : cs.primary),
          onPressed: isApproved ? null : _approve,
          icon: const Icon(Icons.check), label: Text(isApproved ? 'Утверждено' : 'Утвердить'),
        )),
      ]))),
    ]);
  }

  String get _day2OrderLabel => switch (_day2Order) {
    'same' => 'Как день 1', 'reverse' => 'Обратный', 'gundersen' => 'Гундерсен', 'new_draw' => 'Новая жребия', _ => _day2Order,
  };
}

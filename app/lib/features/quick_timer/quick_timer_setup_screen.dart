import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';

/// QT1 — Настройка быстрой сессии хронометража.
class QuickTimerSetupScreen extends ConsumerStatefulWidget {
  const QuickTimerSetupScreen({super.key});

  @override
  ConsumerState<QuickTimerSetupScreen> createState() => _QuickTimerSetupScreenState();
}

class _QuickTimerSetupScreenState extends ConsumerState<QuickTimerSetupScreen> {
  QuickStartMode _mode = QuickStartMode.mass;
  int _laps = 1;
  int _intervalSeconds = 30;

  /// Пары (имя, номер). Минимум 1 строка.
  final List<_AthleteEntry> _entries = [
    _AthleteEntry(),
  ];

  void _addEntry() => setState(() => _entries.add(_AthleteEntry()));

  void _removeEntry(int i) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(i));
  }

  /// Быстрое заполнение номерами 1..N
  void _autoFillBibs() {
    setState(() {
      for (var i = 0; i < _entries.length; i++) {
        if (_entries[i].bibCtrl.text.isEmpty) {
          _entries[i].bibCtrl.text = '${i + 1}';
        }
        if (_entries[i].nameCtrl.text.isEmpty) {
          _entries[i].nameCtrl.text = 'Участник ${i + 1}';
        }
      }
    });
  }

  void _loadGroup(SavedGroup group) {
    setState(() {
      _entries.clear();
      for (final m in group.members) {
        _entries.add(_AthleteEntry()
          ..nameCtrl.text = m.name
          ..bibCtrl.text = m.defaultBib);
      }
      if (_entries.isEmpty) _entries.add(_AthleteEntry());
    });
    AppSnackBar.success(context, 'Группа «${group.name}» загружена');
  }

  void _saveCurrentGroup() {
    final nameCtrl = TextEditingController();
    AppBottomSheet.show(
      context,
      title: 'Сохранить группу',
      initialHeight: 0.35,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final group = SavedGroup(
              id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              members: _entries
                  .where((e) => e.nameCtrl.text.trim().isNotEmpty)
                  .map((e) => SavedGroupMember(
                        name: e.nameCtrl.text.trim(),
                        defaultBib: e.bibCtrl.text.trim(),
                      ))
                  .toList(),
            );
            ref.read(savedGroupsProvider.notifier).save(group);
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Группа «$name» сохранена');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Название группы',
            hintText: 'например: Младшая группа',
            controller: nameCtrl,
          ),
        ],
      ),
    );
  }

  void _showGroupPicker() {
    final groups = ref.read(savedGroupsProvider);
    if (groups.isEmpty) {
      AppSnackBar.info(context, 'Нет сохранённых групп');
      return;
    }
    AppBottomSheet.show(
      context,
      title: 'Загрузить группу',
      initialHeight: 0.5,
      child: Column(
        children: groups.map((g) => ListTile(
          leading: const Icon(Icons.group),
          title: Text(g.name),
          subtitle: Text('${g.members.length} чел.'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              ref.read(savedGroupsProvider.notifier).delete(g.id);
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.info(context, 'Группа удалена');
            },
          ),
          onTap: () {
            _loadGroup(g);
            Navigator.of(context, rootNavigator: true).pop();
          },
        )).toList(),
      ),
    );
  }

  void _startSession() {
    // Валидация
    final athletes = _entries
        .where((e) => e.nameCtrl.text.trim().isNotEmpty)
        .toList();
    if (athletes.isEmpty) {
      AppSnackBar.info(context, 'Добавьте хотя бы одного участника');
      return;
    }

    // Автозаполнение пустых BIB
    for (var i = 0; i < athletes.length; i++) {
      if (athletes[i].bibCtrl.text.trim().isEmpty) {
        athletes[i].bibCtrl.text = '${i + 1}';
      }
    }

    ref.read(quickSessionProvider.notifier).createSession(
      mode: _mode,
      totalLaps: _laps,
      intervalSeconds: _intervalSeconds,
      athletes: athletes
          .map((e) => (name: e.nameCtrl.text.trim(), bib: e.bibCtrl.text.trim()))
          .toList(),
    );
    context.push('/quick-timer/live');
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.nameCtrl.dispose();
      e.bibCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Быстрый Секундомер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История',
            onPressed: () => context.push('/quick-timer/history'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── Режим старта ──
          AppSectionHeader(title: 'Режим старта', icon: Icons.play_arrow),
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              SegmentedButton<QuickStartMode>(
                segments: const [
                  ButtonSegment(value: QuickStartMode.mass, label: Text('Масс'), icon: Icon(Icons.groups)),
                  ButtonSegment(value: QuickStartMode.interval, label: Text('Интервал'), icon: Icon(Icons.timer)),
                  ButtonSegment(value: QuickStartMode.manual, label: Text('Ручной'), icon: Icon(Icons.touch_app)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              AppInfoBanner.info(
                title: _mode == QuickStartMode.mass
                    ? 'Масс-старт'
                    : _mode == QuickStartMode.interval
                        ? 'Интервальный старт'
                        : 'Ручной старт',
                subtitle: _mode == QuickStartMode.mass
                    ? 'Все спортсмены стартуют одновременно по нажатию кнопки «Старт».'
                    : _mode == QuickStartMode.interval
                        ? 'Нажмите «Старт» — первый спортсмен уйдёт, далее остальные стартуют автоматически через заданный интервал.'
                        : 'Вы вручную нажимаете на каждого спортсмена, когда он готов к старту.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Кол-во кругов ──
          AppSectionHeader(title: 'Количество кругов', icon: Icons.loop),
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  for (final n in [1, 2, 3, 4, 5])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$n'),
                        selected: _laps == n,
                        onSelected: (_) => setState(() => _laps = n),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Интервал (только интервальный режим) ──
          if (_mode == QuickStartMode.interval) ...[
            AppSectionHeader(title: 'Интервал между стартами', icon: Icons.schedule),
            AppCard(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    for (final sec in [15, 30, 45, 60])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          // ignore: unnecessary_brace_in_string_interps
                          label: Text('${sec}с'),
                          selected: _intervalSeconds == sec,
                          onSelected: (_) => setState(() => _intervalSeconds = sec),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Участники ──
          AppSectionHeader(
            title: 'Участники (${_entries.length})',
            icon: Icons.people,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                icon: Icon(Icons.folder_open, size: 20, color: cs.primary),
                tooltip: 'Загрузить группу',
                onPressed: _showGroupPicker,
              ),
              IconButton(
                icon: Icon(Icons.save_alt, size: 20, color: cs.primary),
                tooltip: 'Сохранить группу',
                onPressed: _saveCurrentGroup,
              ),
              IconButton(
                icon: Icon(Icons.auto_fix_high, size: 20, color: cs.primary),
                tooltip: 'Автозаполнение',
                onPressed: _autoFillBibs,
              ),
          ]),

          ...List.generate(_entries.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              // BIB
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _entries[i].bibCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.primary),
                  decoration: InputDecoration(
                    hintText: '#',
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Имя
              Expanded(
                child: TextField(
                  controller: _entries[i].nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Имя участника',
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Удалить
              if (_entries.length > 1)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, size: 20, color: cs.error),
                  onPressed: () => _removeEntry(i),
                  visualDensity: VisualDensity.compact,
                ),
            ]),
          )),

          // Кнопка добавить
          TextButton.icon(
            onPressed: _addEntry,
            icon: Icon(Icons.add, color: cs.primary),
            label: Text('Добавить участника', style: TextStyle(color: cs.primary)),
          ),
          const SizedBox(height: 24),

          // ── СТАРТ ──
          AppButton.primary(
            text: 'СТАРТ  ▶',
            icon: Icons.play_arrow,
            onPressed: _startSession,
          ),
        ],
      ),
    );
  }
}

/// Контроллеры для одной строки ввода.
class _AthleteEntry {
  final nameCtrl = TextEditingController();
  final bibCtrl = TextEditingController();
}

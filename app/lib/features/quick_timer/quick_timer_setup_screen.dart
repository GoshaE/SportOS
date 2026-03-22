import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';

/// QT1 — Настройка быстрой сессии хронометража.
///
/// Используемые компоненты:
/// - [AppSectionHeader] — заголовки секций с action
/// - [AppCard] — карточки секций
/// - [AppInfoBanner] — подсказки по режимам
/// - [AppUserTile] — строки участников
/// - [AppTextField] — поля ввода
/// - [AppSearchBar] — поиск/добавление
/// - [AppBottomSheet] — модалка добавления + группы
/// - [AppButton] — кнопки действий
/// - [AppSnackBar] — уведомления
class QuickTimerSetupScreen extends ConsumerStatefulWidget {
  const QuickTimerSetupScreen({super.key});

  @override
  ConsumerState<QuickTimerSetupScreen> createState() => _QuickTimerSetupScreenState();
}

class _QuickTimerSetupScreenState extends ConsumerState<QuickTimerSetupScreen> {
  QuickStartMode _mode = QuickStartMode.mass;
  int _laps = 1;
  int _intervalSeconds = 30;

  /// Список участников: (имя, bib).
  final List<_AthleteEntry> _entries = [];

  // ═══════════════════════════════════════
  // Actions: участники
  // ═══════════════════════════════════════

  void _addEntry({String name = '', String bib = ''}) {
    setState(() {
      final nextBib = bib.isNotEmpty ? bib : '${_entries.length + 1}';
      _entries.add(_AthleteEntry()
        ..nameCtrl.text = name
        ..bibCtrl.text = nextBib);
    });
  }

  void _removeEntry(int i) {
    setState(() {
      _entries[i].nameCtrl.dispose();
      _entries[i].bibCtrl.dispose();
      _entries.removeAt(i);
    });
  }

  void _showAddAthleteSheet() {
    final nameCtrl = TextEditingController();
    final surnameCtrl = TextEditingController();
    final bibCtrl = TextEditingController(text: '${_entries.length + 1}');

    AppBottomSheet.show(
      context,
      title: 'Добавить участника',
      initialHeight: 0.45,
      actions: [
        AppButton.primary(
          text: 'Добавить',
          icon: Icons.add,
          onPressed: () {
            final name = '${nameCtrl.text.trim()} ${surnameCtrl.text.trim()}'.trim();
            if (name.isEmpty) {
              AppSnackBar.info(context, 'Введите имя');
              return;
            }
            final bib = bibCtrl.text.trim();
            _addEntry(name: name, bib: bib);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: AppTextField(label: 'Имя', controller: nameCtrl, hintText: 'Алексей', autofocus: true)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Фамилия', controller: surnameCtrl, hintText: 'Иванов')),
          ]),
          const SizedBox(height: 12),
          AppTextField(
            label: 'BIB (номер)',
            controller: bibCtrl,
            hintText: '${_entries.length + 1}',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  /// Быстрое заполнение пустых BIB и имён.
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
    AppSnackBar.success(context, 'Номера и имена заполнены');
  }

  /// Быстрое добавление N пустых строк.
  void _addMultipleEntries() {
    final countCtrl = TextEditingController(text: '5');
    AppBottomSheet.show(
      context,
      title: 'Добавить несколько',
      initialHeight: 0.3,
      actions: [
        AppButton.primary(
          text: 'Добавить',
          icon: Icons.group_add,
          onPressed: () {
            final count = int.tryParse(countCtrl.text.trim()) ?? 0;
            if (count <= 0 || count > 50) {
              AppSnackBar.info(context, 'Укажите число от 1 до 50');
              return;
            }
            for (var i = 0; i < count; i++) {
              _addEntry();
            }
            _autoFillBibs();
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: AppTextField(
        label: 'Количество участников',
        controller: countCtrl,
        hintText: '5',
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
    );
  }

  // ═══════════════════════════════════════
  // Actions: группы (книга тренера)
  // ═══════════════════════════════════════

  void _loadGroup(SavedGroup group) {
    setState(() {
      for (final e in _entries) {
        e.nameCtrl.dispose();
        e.bibCtrl.dispose();
      }
      _entries.clear();
      for (final m in group.members) {
        _entries.add(_AthleteEntry()
          ..nameCtrl.text = m.name
          ..bibCtrl.text = m.defaultBib);
      }
    });
    AppSnackBar.success(context, 'Группа «${group.name}» загружена');
  }

  void _saveCurrentGroup() {
    if (_entries.isEmpty) {
      AppSnackBar.info(context, 'Добавьте участников');
      return;
    }
    final nameCtrl = TextEditingController();
    AppBottomSheet.show(
      context,
      title: 'Сохранить как группу',
      initialHeight: 0.35,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          icon: Icons.save,
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
      child: AppTextField(
        label: 'Название группы',
        hintText: 'например: Младшая группа',
        controller: nameCtrl,
        autofocus: true,
      ),
    );
  }

  void _showGroupPicker() {
    final groups = ref.read(savedGroupsProvider);
    if (groups.isEmpty) {
      AppSnackBar.info(context, 'Нет сохранённых групп. Добавьте участников и сохраните группу.');
      return;
    }
    AppBottomSheet.show(
      context,
      title: 'Книга тренера',
      initialHeight: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoBanner.info(
            title: 'Загрузите сохранённую группу',
            subtitle: 'Текущий список будет заменён.',
          ),
          const SizedBox(height: 12),
          ...groups.map((g) => AppUserTile(
            name: g.name,
            subtitle: '${g.members.length} участник(ов)',
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.group, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                onPressed: () {
                  ref.read(savedGroupsProvider.notifier).delete(g.id);
                  Navigator.of(context, rootNavigator: true).pop();
                  AppSnackBar.info(context, 'Группа удалена');
                },
              ),
            ]),
            onTap: () {
              _loadGroup(g);
              Navigator.of(context, rootNavigator: true).pop();
            },
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Start session
  // ═══════════════════════════════════════

  void _startSession() {
    final valid = _entries.where((e) => e.nameCtrl.text.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      AppSnackBar.info(context, 'Добавьте хотя бы одного участника');
      return;
    }

    // Автозаполнение пустых BIB
    for (var i = 0; i < valid.length; i++) {
      if (valid[i].bibCtrl.text.trim().isEmpty) {
        valid[i].bibCtrl.text = '${i + 1}';
      }
    }

    ref.read(quickSessionProvider.notifier).createSession(
      mode: _mode,
      totalLaps: _laps,
      intervalSeconds: _intervalSeconds,
      athletes: valid
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

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ═══════════════════════════════
          // 1. РЕЖИМ СТАРТА
          // ═══════════════════════════════
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
              const SizedBox(height: 10),
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

          // ═══════════════════════════════
          // 2. КОЛ-ВО КРУГОВ
          // ═══════════════════════════════
          AppSectionHeader(title: 'Количество кругов', icon: Icons.loop),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

          // ═══════════════════════════════
          // 3. ИНТЕРВАЛ (только interval)
          // ═══════════════════════════════
          if (_mode == QuickStartMode.interval) ...[
            AppSectionHeader(title: 'Интервал между стартами', icon: Icons.schedule),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ],

          // ═══════════════════════════════
          // 4. УЧАСТНИКИ
          // ═══════════════════════════════
          AppSectionHeader(
            title: 'Участники (${_entries.length})',
            icon: Icons.people,
            action: '+ Добавить',
            onAction: _showAddAthleteSheet,
          ),

          // ── Действия с группой ──
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              AppButton.small(
                text: 'Из книги',
                icon: Icons.folder_open,
                onPressed: _showGroupPicker,
              ),
              const SizedBox(width: 8),
              AppButton.smallSecondary(
                text: 'Сохранить',
                icon: Icons.save_alt,
                onPressed: _saveCurrentGroup,
              ),
              const Spacer(),
              AppButton.smallSecondary(
                text: 'Группу',
                icon: Icons.group_add,
                onPressed: _addMultipleEntries,
              ),
              const SizedBox(width: 8),
              AppButton.smallSecondary(
                text: 'Авто',
                icon: Icons.auto_fix_high,
                onPressed: _entries.isNotEmpty ? _autoFillBibs : null,
              ),
            ]),
          ),

          // ── Пустой стейт ──
          if (_entries.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_outlined, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('Добавьте участников', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Нажмите «+ Добавить» или загрузите из книги тренера',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                    const SizedBox(height: 16),
                    AppButton.small(
                      text: '+ Добавить участника',
                      icon: Icons.person_add,
                      onPressed: _showAddAthleteSheet,
                    ),
                  ]),
                ),
              ],
            ),

          // ── Список участников (drag-to-reorder) ──
          if (_entries.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _entries.removeAt(oldIndex);
                  _entries.insert(newIndex, item);
                });
              },
              itemCount: _entries.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
                    return Material(
                      elevation: elevation,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, i) {
                final e = _entries[i];
                final name = e.nameCtrl.text.trim();
                final bib = e.bibCtrl.text.trim();
                final displayName = name.isNotEmpty ? name : 'Участник ${i + 1}';

                return Padding(
                  key: ValueKey(e),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AppUserTile(
                    name: displayName,
                    subtitle: '#${i + 1} · BIB: ${bib.isNotEmpty ? bib : '—'}',
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                      child: Text(
                        bib.isNotEmpty ? bib : '${i + 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.primary),
                      ),
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      // Drag handle
                      ReorderableDragStartListener(
                        index: i,
                        child: Icon(Icons.drag_handle, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      ),
                      // Редактировать
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _editEntry(i),
                      ),
                      // Удалить
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: cs.error.withValues(alpha: 0.7)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeEntry(i),
                      ),
                    ]),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // ═══════════════════════════════
          // 5. СТАРТ
          // ═══════════════════════════════
          AppButton.primary(
            text: 'СТАРТ  ▶',
            icon: Icons.play_arrow,
            onPressed: _startSession,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Edit athlete
  // ═══════════════════════════════════════

  void _editEntry(int index) {
    final e = _entries[index];
    final parts = e.nameCtrl.text.trim().split(RegExp(r'\s+'));
    final nameCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    final surnameCtrl = TextEditingController(text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    final bibCtrl = TextEditingController(text: e.bibCtrl.text);

    AppBottomSheet.show(
      context,
      title: 'Редактировать участника',
      initialHeight: 0.45,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          icon: Icons.check,
          onPressed: () {
            final name = '${nameCtrl.text.trim()} ${surnameCtrl.text.trim()}'.trim();
            if (name.isEmpty) {
              AppSnackBar.info(context, 'Введите имя');
              return;
            }
            setState(() {
              e.nameCtrl.text = name;
              e.bibCtrl.text = bibCtrl.text.trim();
            });
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: AppTextField(label: 'Имя', controller: nameCtrl, hintText: 'Алексей', autofocus: true)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Фамилия', controller: surnameCtrl, hintText: 'Иванов')),
          ]),
          const SizedBox(height: 12),
          AppTextField(
            label: 'BIB (номер)',
            controller: bibCtrl,
            hintText: '${index + 1}',
            keyboardType: TextInputType.number,
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

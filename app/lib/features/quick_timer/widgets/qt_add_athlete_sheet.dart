import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_models.dart';
import '../../../domain/quick_timer/quick_timer_providers.dart';

/// Открыть шторку добавления участника
void showQtAddAthleteSheet(BuildContext context, WidgetRef ref) {
  AppBottomSheet.show(
    context,
    title: 'Добавить участника',
    initialHeight: 0.65,
    child: const _AddAthleteContent(),
  );
}

class _AddAthleteContent extends ConsumerStatefulWidget {
  const _AddAthleteContent();

  @override
  ConsumerState<_AddAthleteContent> createState() => _AddAthleteContentState();
}

class _AddAthleteContentState extends ConsumerState<_AddAthleteContent> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final Set<String> _selectedRecent = {};

  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  late final TextEditingController bibCtrl;

  @override
  void initState() {
    super.initState();
    // Инициализируем BIB следующим доступным номером
    final session = ref.read(quickSessionProvider);
    final nextBib = '${(session?.athletes.length ?? 0) + 1}';
    bibCtrl = TextEditingController(text: nextBib);

    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    surnameCtrl.dispose();
    bibCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _addNewAthlete() {
    final name = '${nameCtrl.text.trim()} ${surnameCtrl.text.trim()}'.trim();
    if (name.isEmpty) {
      AppSnackBar.info(context, 'Введите имя');
      return;
    }
    ref.read(quickSessionProvider.notifier).addAthlete(
      name: name,
      bib: bibCtrl.text.trim(),
    );
    AppSnackBar.success(context, '$name добавлен');
    Navigator.of(context, rootNavigator: true).pop();
  }


  void _addSelectedRecentAthletes() {
    if (_selectedRecent.isEmpty) return;
    final session = ref.read(quickSessionProvider);
    final notifier = ref.read(quickSessionProvider.notifier);
    int nextBibInt = (session?.athletes.length ?? 0) + 1;

    int suffix = 0;
    for (var name in _selectedRecent) {
      notifier.addAthlete(name: name, bib: '$nextBibInt', idSuffix: suffix);
      nextBibInt++;
      suffix++;
    }
    AppSnackBar.success(context, 'Добавлено: ${_selectedRecent.length}');
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Переключатель (Табы) ──
        AppPillTabBar(
          controller: _tabCtrl,
          tabs: const ['Новый', 'Недавние'],
        ),
        const SizedBox(height: 16),

        // ── Контент вкладок ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _tabCtrl.index == 0 ? _buildNewTab(cs) : _buildRecentTab(cs),
        ),
      ],
    );
  }

  Widget _buildNewTab(ColorScheme cs) {
    return Column(
      key: const ValueKey('tab_new'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          hintText: '1',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        AppButton.primary(
          text: 'Добавить',
          icon: Icons.add,
          onPressed: _addNewAthlete,
        ),
      ],
    );
  }

  Widget _buildRecentTab(ColorScheme cs) {
    final history = ref.watch(quickHistoryProvider);
    
    // Извлекаем уникальных спортсменов
    final recentAthletes = <String, QuickAthlete>{};
    for (final session in history.reversed) { // От новых к старым
      for (final a in session.athletes) {
        if (a.name.isNotEmpty && !recentAthletes.containsKey(a.name)) {
          recentAthletes[a.name] = a;
        }
      }
    }
    
    final list = recentAthletes.values.toList();

    if (list.isEmpty) {
      return Center(
        key: const ValueKey('tab_recent_empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Нет сохраненной истории', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          key: const ValueKey('tab_recent_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            final session = ref.read(quickSessionProvider);
            final exists = session?.athletes.any((sa) => sa.name == a.name) ?? false;
            final isSelected = _selectedRecent.contains(a.name);
            
            final parts = a.name.trim().split(RegExp(r'\s+'));
            final initials = parts.isNotEmpty
                ? (parts.length > 1
                    ? '${parts[0].characters.first}${parts[1].characters.first}'.toUpperCase()
                    : parts[0].characters.first.toUpperCase())
                : '?';
            
            return AppUserTile(
              name: a.name,
              subtitle: exists ? 'Уже в стартовом листе' : 'Участвовал ранее',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSelected || exists,
                    onChanged: exists ? null : (val) {
                      setState(() {
                        if (val == true) {
                          _selectedRecent.add(a.name);
                        } else {
                          _selectedRecent.remove(a.name);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primary.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: exists ? Icon(Icons.check_circle, color: cs.primary) : null,
              onTap: exists ? null : () {
                setState(() {
                  if (isSelected) {
                    _selectedRecent.remove(a.name);
                  } else {
                    _selectedRecent.add(a.name);
                  }
                });
              },
            );
          },
        ),
        
        // Кнопка множественного добавления
        if (_selectedRecent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppButton.primary(
              text: 'Добавить выбранных (${_selectedRecent.length})',
              icon: Icons.group_add,
              onPressed: _addSelectedRecentAthletes,
            ),
          )
        else
          const SizedBox(height: 32),
      ],
    );
  }
}

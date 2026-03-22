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

  void _addRecentAthlete(QuickAthlete athlete) {
    final session = ref.read(quickSessionProvider);
    final nextBib = '${(session?.athletes.length ?? 0) + 1}';
    
    // Проверяем, нет ли его уже в сессии
    final exists = session?.athletes.any((a) => a.name == athlete.name) ?? false;
    if (exists) {
      AppSnackBar.warning(context, '${athlete.name} уже в стартовом листе');
      return;
    }

    ref.read(quickSessionProvider.notifier).addAthlete(
      name: athlete.name,
      bib: nextBib, // Выдаем новый уникальный биб
    );
    AppSnackBar.success(context, '${athlete.name} добавлен ($nextBib)');
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppPillTabBar(
            controller: _tabCtrl,
            tabs: const ['Новый', 'Недавние'],
          ),
        ),

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: AppTextField(label: 'Имя', controller: nameCtrl, hintText: 'Алексей', autofocus: true)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Фамилия', controller: surnameCtrl, hintText: 'Иванов')),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppTextField(
            label: 'BIB (номер)',
            controller: bibCtrl,
            hintText: '1',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 32),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: AppButton.primary(
              text: 'Добавить',
              icon: Icons.add,
              onPressed: _addNewAthlete,
            ),
          ),
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

    return ListView.builder(
      key: const ValueKey('tab_recent_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final a = list[i];
        final session = ref.read(quickSessionProvider);
        final exists = session?.athletes.any((sa) => sa.name == a.name) ?? false;
        
        return AppUserTile(
          name: a.name,
          subtitle: 'Участвовал ранее',
          trailing: exists 
            ? Icon(Icons.check_circle, color: cs.primary)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: cs.primary,
                onPressed: () => _addRecentAthlete(a),
              ),
          onTap: exists ? null : () => _addRecentAthlete(a),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_providers.dart';

/// Выбор сохранённой группы атлетов из Книги Тренера
void showQtGroupPickerSheet(BuildContext context, WidgetRef ref) {
  final groups = ref.read(savedGroupsProvider);
  
  if (groups.isEmpty) {
    AppSnackBar.info(context, 'Нет сохранённых групп');
    return;
  }
  
  final cs = Theme.of(context).colorScheme;
  
  AppBottomSheet.show(
    context,
    title: 'Книга тренера',
    initialHeight: 0.5,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInfoBanner.info(title: 'Загрузите сохранённую группу', subtitle: 'Участники будут добавлены.'),
        const SizedBox(height: 12),
        ...groups.map((g) => AppUserTile(
          name: g.name,
          subtitle: '${g.members.length} участник(ов)',
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.group, color: cs.primary, size: 20),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
            onPressed: () {
              ref.read(savedGroupsProvider.notifier).delete(g.id);
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.info(context, 'Группа удалена');
            },
          ),
          onTap: () {
            for (final m in g.members) {
              ref.read(quickSessionProvider.notifier).addAthlete(name: m.name, bib: m.defaultBib);
            }
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Группа «${g.name}» загружена');
          },
        )),
      ],
    ),
  );
}

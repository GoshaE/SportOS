import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_models.dart';
import '../../../domain/quick_timer/quick_timer_providers.dart';
import 'qt_group_picker_sheet.dart';

/// Открыть шторку настроек быстрой сессии.
void showQtSettingsSheet(BuildContext context, WidgetRef ref, VoidCallback onReset) {
  final session = ref.read(quickSessionProvider);
  if (session == null) return;
  
  final isRunning = session.status == QuickSessionStatus.running;
  var mode = session.mode;
  var laps = session.totalLaps;
  var interval = session.intervalSeconds;

  AppBottomSheet.show(
    context,
    title: 'Настройки сессии',
    initialHeight: 0.55,
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Режим старта ──
          Text('РЕЖИМ СТАРТА', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          )),
          const SizedBox(height: 8),
          SegmentedButton<QuickStartMode>(
            segments: const [
              ButtonSegment(value: QuickStartMode.mass, label: Text('Масс'), icon: Icon(Icons.groups)),
              ButtonSegment(value: QuickStartMode.interval, label: Text('Интервал'), icon: Icon(Icons.timer)),
              ButtonSegment(value: QuickStartMode.manual, label: Text('Ручной'), icon: Icon(Icons.touch_app)),
            ],
            selected: {mode},
            onSelectionChanged: isRunning ? null : (s) {
              setSheetState(() => mode = s.first);
              ref.read(quickSessionProvider.notifier).updateSettings(mode: mode);
            },
          ),
          const SizedBox(height: 8),
          AppInfoBanner.info(
            title: mode == QuickStartMode.mass
                ? 'Все стартуют одновременно'
                : mode == QuickStartMode.interval
                    ? 'Автоматический старт через интервал'
                    : 'Тренер запускает каждого вручную',
          ),

          const SizedBox(height: 16),
          // ── Количество кругов (ИСПРАВЛЕН Overflow тут) ──
          Text('КОЛИЧЕСТВО КРУГОВ', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in [1, 2, 3, 4, 5])
                ChoiceChip(
                  label: Text('$n'),
                  selected: laps == n,
                  onSelected: (_) {
                    setSheetState(() => laps = n);
                    ref.read(quickSessionProvider.notifier).updateSettings(totalLaps: n);
                  },
                ),
            ],
          ),

          // ── Интервал (только для interval mode) ──
          if (mode == QuickStartMode.interval) ...[
            const SizedBox(height: 16),
            Text('ИНТЕРВАЛ МЕЖДУ СТАРТАМИ', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sec in [15, 30, 45, 60])
                  ChoiceChip(
                    label: Text('${sec}с'),
                    selected: interval == sec,
                    onSelected: isRunning ? null : (_) {
                      setSheetState(() => interval = sec);
                      ref.read(quickSessionProvider.notifier).updateSettings(intervalSeconds: sec);
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          // ── Группы ──
          Row(children: [
            Expanded(
              child: AppButton.small(
                text: 'Из книги',
                icon: Icons.folder_open,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  showQtGroupPickerSheet(context, ref);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton.smallSecondary(
                text: 'Сохранить',
                icon: Icons.save_alt,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _showSaveGroupSheet(context, ref, session);
                },
              ),
            ),
          ]),

          // ── Новая сессия ──
          if (session.status == QuickSessionStatus.finished) ...[
            const SizedBox(height: 16),
            AppButton.danger(
              text: 'Новая сессия',
              icon: Icons.refresh,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                onReset();
              },
            ),
          ],
        ],
      ),
    ),
  );
}

void _showSaveGroupSheet(BuildContext context, WidgetRef ref, QuickSession session) {
  if (session.athletes.isEmpty) {
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
            members: session.athletes
                .map((a) => SavedGroupMember(name: a.name, defaultBib: a.bib))
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
      hintText: 'Младшая группа', 
      controller: nameCtrl, 
      autofocus: true,
    ),
  );
}

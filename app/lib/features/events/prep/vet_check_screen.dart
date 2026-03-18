import 'package:flutter/material.dart';
import 'package:sportos_app/ui/molecules/app_list_row.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P4 — Ветконтроль
class VetCheckScreen extends StatelessWidget {
  const VetCheckScreen({super.key});

  void _showDogCard(BuildContext context, String animal, String chip, String owner, String vaccDate, bool valid) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(context, title: animal, initialHeight: 0.55, actions: [
      Row(children: [
        Expanded(child: FilledButton.icon(
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.success(context, '$animal — допущен'); },
          icon: const Icon(Icons.check), label: const Text('Допустить'),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); _showRejectReason(context, animal); },
          icon: const Icon(Icons.close), label: const Text('Не допустить'),
        )),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.info(context, 'Замена собаки — двухэтапная проверка чипа'); },
        icon: const Icon(Icons.swap_horiz), label: const Text('Замена собаки'),
      ),
    ], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 30, backgroundColor: cs.secondaryContainer, child: Icon(Icons.pets, size: 32, color: cs.secondary)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(animal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Чип: $chip', style: TextStyle(color: cs.onSurfaceVariant)),
          Text('Владелец: $owner'),
        ]),
      ]),
      Divider(height: 24, color: cs.outlineVariant.withValues(alpha: 0.3)),
      AppListRow.status(icon: valid ? Icons.check_circle : Icons.warning, title: 'Вакцинация', subtitle: 'До: $vaccDate'),
      AppListRow.status(icon: Icons.medical_services, title: 'Осмотр', subtitle: 'Общее состояние: хорошее'),
      AppListRow.status(icon: Icons.thermostat, iconColor: cs.tertiary, title: 'Температура', subtitle: '38.5°C (норма)'),
    ]));
  }

  void _showRejectReason(BuildContext context, String animal) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Не допустить — $animal',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Подтвердить отказ',
          backgroundColor: cs.error,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.error(context, '$animal — не допущен');
          },
        ),
      ],
      child: AppCard(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('Просрочена вакцинация'), selected: true, onSelected: (_) {}),
            ChoiceChip(label: const Text('Травма'), selected: false, onSelected: (_) {}),
            ChoiceChip(label: const Text('Агрессия'), selected: false, onSelected: (_) {}),
            ChoiceChip(label: const Text('Другое'), selected: false, onSelected: (_) {}),
          ]),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Комментарий', border: OutlineInputBorder()), maxLines: 2),
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Ветконтроль'), actions: [
        Badge(label: const Text('3'), child: IconButton(icon: const Icon(Icons.warning), onPressed: () {})),
        IconButton(icon: const Icon(Icons.nfc), tooltip: 'NFC чтение чипа', onPressed: () => AppSnackBar.info(context, 'NFC — поиск чипа собаки')),
      ]),
      body: Column(children: [
        AppInfoPanel(
          backgroundColor: cs.surfaceContainerHighest,
          children: [
            AppInfoPanel.stat('35', 'Прошли', cs.primary),
            AppInfoPanel.stat('10', 'Ожидают', cs.tertiary),
            AppInfoPanel.stat('3', 'Отклонены', cs.error),
          ],
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(8), children: [
          _vetRow(context, cs, 'Rex (Хаски)', '123456', 'Петров А.А.', '01.12.2025', true, 'passed'),
          _vetRow(context, cs, 'Luna (Маламут)', '789012', 'Сидоров Б.Б.', '15.11.2025', true, 'passed'),
          _vetRow(context, cs, 'Storm (Хаски)', '345678', 'Иванов В.В.', '01.09.2025', false, 'warning'),
          _vetRow(context, cs, 'Wolf (Овчарка)', '901234', 'Козлов Г.Г.', 'ПРОСРОЧЕНА', false, 'failed'),
          _vetRow(context, cs, 'Buddy (Метис)', '567890', 'Морозов Д.Д.', 'Ожидает', false, 'pending'),
          _vetRow(context, cs, 'Alaska (Маламут)', '234567', 'Волков Е.Е.', '20.01.2026', true, 'passed'),
        ])),
      ]),
    );
  }

  Widget _vetRow(BuildContext context, ColorScheme cs, String animal, String chip, String owner, String vaccDate, bool valid, String state) {
    final color = state == 'passed' ? cs.primary : state == 'warning' ? cs.tertiary : state == 'failed' ? cs.error : cs.onSurfaceVariant;
    final icon = state == 'passed' ? Icons.check_circle : state == 'warning' ? Icons.warning : state == 'failed' ? Icons.cancel : Icons.hourglass_empty;
    return Card(child: AppListRow.status(
      icon: icon,
      iconColor: color,
      title: animal,
      subtitle: '$owner\nВакц.: $vaccDate · Чип: $chip',
      trailing: state == 'pending'
        ? FilledButton(onPressed: () => _showDogCard(context, animal, chip, owner, vaccDate, valid), child: const Text('Осмотр'))
        : IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showDogCard(context, animal, chip, owner, vaccDate, valid)),
      onTap: () => _showDogCard(context, animal, chip, owner, vaccDate, valid),
    ));
  }
}

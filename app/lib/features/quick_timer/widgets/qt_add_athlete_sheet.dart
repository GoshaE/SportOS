import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../../domain/quick_timer/quick_timer_providers.dart';

/// Открыть шторку добавления участника
void showQtAddAthleteSheet(BuildContext context, WidgetRef ref) {
  final session = ref.read(quickSessionProvider);
  final nextBib = '${(session?.athletes.length ?? 0) + 1}';
  
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final bibCtrl = TextEditingController(text: nextBib);

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
          ref.read(quickSessionProvider.notifier).addAthlete(
            name: name,
            bib: bibCtrl.text.trim(),
          );
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
          hintText: nextBib,
          keyboardType: TextInputType.number,
        ),
      ],
    ),
  );
}

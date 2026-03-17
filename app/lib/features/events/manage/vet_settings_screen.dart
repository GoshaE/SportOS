import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';

/// Screen: Настройки ветеринарного контроля
class VetSettingsScreen extends ConsumerWidget {
  const VetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventConfig = ref.watch(eventConfigProvider);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Ветконтроль')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(title: 'Обязательный ветконтроль', subtitle: 'Чип-проверка перед стартом', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Grace-period вакцинации', subtitle: '30 дней'),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Замена собаки между днями',
              subtitle: 'Для многодневных мероприятий',
              value: eventConfig.allowDogSwapBetweenDays,
              onChanged: (v) {
                ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(allowDogSwapBetweenDays: v));
              },
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Мин. возраст собак', subtitle: '15 месяцев'),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'Ветконтроль день 2', subtitle: 'Повторная проверка чипа', value: true, onChanged: (_) {}),
          ]),
        ]),
      ]),
    );
  }
}

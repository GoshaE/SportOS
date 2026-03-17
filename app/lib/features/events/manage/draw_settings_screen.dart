import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen: Настройки жеребьёвки
class DrawSettingsScreen extends StatelessWidget {
  const DrawSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Жеребьёвка')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle(cs, 'Режим'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.radio(title: 'Авто жеребьёвка', subtitle: 'Случайный порядок', value: 'auto', groupValue: 'auto', onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(title: 'Ручная', subtitle: 'Организатор назначает', value: 'manual', groupValue: 'auto', onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(title: 'Комбинированная', subtitle: 'Посев + авто', value: 'combined', groupValue: 'auto', onChanged: (_) {}),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Группировка'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.radio(title: 'Совместная', subtitle: 'Все категории вместе', value: 'joint', groupValue: 'joint', onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(title: 'По категориям', subtitle: 'CEC → OPEN → Юн...', value: 'byCategory', groupValue: 'joint', onChanged: (_) {}),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Дополнительно'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(title: 'Буфер между группами', subtitle: '5 минут'),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Кто участвует', subtitle: 'Только подтверждённые'),
          ]),
        ]),
      ]),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }
}

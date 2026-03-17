import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen: Настройки системы хронометража
class TimingSettingsScreen extends StatelessWidget {
  const TimingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Хронометраж')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle(cs, 'Точность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(title: 'Точность отсечки', subtitle: 'Миллисекунды (0.001)'),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Формат времени', subtitle: 'HH:mm:ss.S'),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Режим работы'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(title: 'Двойной хронометраж', subtitle: 'Мастер + Контрольный', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'GPS трекинг', value: false, onChanged: (_) {}),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Безопасность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(title: 'Аудит лог', subtitle: 'Запись всех изменений', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'Двойное подтверждение DNF', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'Photo-Finish', subtitle: 'Два судьи', value: false, onChanged: (_) {}),
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

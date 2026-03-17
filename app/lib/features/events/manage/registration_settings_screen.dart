import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen: Настройки регистрации
class RegistrationSettingsScreen extends StatelessWidget {
  const RegistrationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Регистрация')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle(cs, 'Публичность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(title: 'Регистрация открыта', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'Публичный стартовый лист', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(title: 'Публичные результаты', value: true, onChanged: (_) {}),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Лимиты'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(title: 'Макс. участников', subtitle: '60'),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Waitlist', subtitle: 'Включен (макс. 20)'),
          ]),
        ]),
        const SizedBox(height: 16),

        _sectionTitle(cs, 'Оплата'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(title: 'Возврат оплаты', subtitle: 'До 48ч до старта', value: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.nav(title: 'Таймаут бронирования', subtitle: '48 часов'),
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

import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR2.1 — Карточка собаки (детальная)
class DogDetailScreen extends StatefulWidget {
  const DogDetailScreen({super.key});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends State<DogDetailScreen> {
  String _name = 'Rex';
  String _breed = 'Сибирский хаски';
  String _chip = '643093400123456';
  String _vaccine = '15.01.2027';
  final String _sex = 'Кобель';
  final String _birthday = '12.03.2020';
  final bool _vaccineOk = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: Text(_name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEdit),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Фото + имя ──
          Center(child: Column(children: [
            AppAvatar(name: _name, size: 96, editable: true),
            const SizedBox(height: 12),
            Text(_name, style: theme.textTheme.headlineSmall),
            Text(_breed, style: theme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          const SizedBox(height: 20),

          // ── Основные данные ──
          AppSectionHeader(title: 'Основные', icon: Icons.info_outline),
          AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            AppDetailRow(label: 'Пол', value: _sex, icon: Icons.wc),
            AppDetailRow(label: 'Дата рождения', value: _birthday, icon: Icons.cake),
            AppDetailRow(label: 'Чип', value: _chip, icon: Icons.memory),
          ]),
          const SizedBox(height: 12),

          // ── Вакцинация ──
          AppSectionHeader(title: 'Вакцинация', icon: _vaccineOk ? Icons.verified : Icons.warning),
          _vaccineOk
              ? AppInfoBanner.success(title: 'Вакцинация в порядке', subtitle: 'Действует до $_vaccine')
              : AppInfoBanner.error(title: 'Вакцинация просрочена', subtitle: 'Обновите данные'),
          const SizedBox(height: 8),
          AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            AppDetailRow(label: 'Бешенство', value: 'До $_vaccine', icon: Icons.medical_services),
            AppDetailRow(label: 'Комплексная', value: 'До 20.08.2026', icon: Icons.vaccines),
          ]),
          const SizedBox(height: 4),
          AppButton.secondary(text: 'Загрузить сертификат', icon: Icons.upload_file, onPressed: () {}),
          const SizedBox(height: 12),

          // ── Статистика ──
          AppSectionHeader(title: 'Статистика', icon: Icons.bar_chart),
          AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            AppDetailRow(label: 'Всего стартов', value: '12', icon: Icons.flag),
            AppDetailRow(label: 'Подиумов', value: '5', icon: Icons.emoji_events),
            AppDetailRow(label: 'Лучшее время', value: '23:15 (Скидж. 6км)', icon: Icons.timer),
          ]),
          const SizedBox(height: 12),

          // ── Последние старты ──
          AppExpandableList<Map<String, String>>(
            initialCount: 3,
            expandLabel: 'стартов',
            headerBuilder: (expandWidget) => Row(children: [
              Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Последние старты', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              expandWidget,
            ]),
            items: const [
              {'place': '🥇', 'event': 'Чемпионат Урала 2026', 'detail': 'Скидж. 5км · 38:12', 'date': '15.03.2026'},
              {'place': '🥈', 'event': 'Кубок Сибири 2025', 'detail': 'Скидж. 10км · 1:12:45', 'date': '20.12.2025'},
              {'place': '4', 'event': 'Кубок Москвы', 'detail': 'Скидж. 5км · 42:30', 'date': '15.11.2025'},
              {'place': '🥉', 'event': 'Кубок Урала 2025', 'detail': 'Каникросс · 18:05', 'date': '20.10.2025'},
              {'place': '6', 'event': 'Чемпионат России', 'detail': 'Скидж. 10км · 1:15:20', 'date': '10.09.2025'},
              {'place': '🥇', 'event': 'Кубок Тюмени', 'detail': 'Каникросс · 16:40', 'date': '15.08.2025'},
              {'place': '5', 'event': 'Марафон Урала', 'detail': 'Скидж. 20км · 2:45:10', 'date': '01.07.2025'},
              {'place': '🥈', 'event': 'Летний кубок', 'detail': 'Каникросс · 17:55', 'date': '15.06.2025'},
            ],
            itemBuilder: (item) => _startRow(item['place']!, item['event']!, item['detail']!, item['date']!),
          ),
        ],
      ),
    );
  }

  Widget _startRow(String place, String event, String detail, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Text(place, style: const TextStyle(fontSize: 16)),
        title: Text(event, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text('$detail · $date', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  void _showEdit() {
    final nameCtrl = TextEditingController(text: _name);
    final breedCtrl = TextEditingController(text: _breed);
    final chipCtrl = TextEditingController(text: _chip);
    final vaccCtrl = TextEditingController(text: _vaccine);

    AppBottomSheet.show(
      context,
      title: 'Редактировать',
      initialHeight: 0.55,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            setState(() {
              _name = nameCtrl.text;
              _breed = breedCtrl.text;
              _chip = chipCtrl.text;
              _vaccine = vaccCtrl.text;
            });
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Данные обновлены');
          },
        ),
      ],
      child: Column(children: [
        AppTextField(label: 'Кличка', controller: nameCtrl),
        const SizedBox(height: 10),
        AppTextField(label: 'Порода', controller: breedCtrl),
        const SizedBox(height: 10),
        AppTextField(label: 'Чип', controller: chipCtrl),
        const SizedBox(height: 10),
        AppTextField(label: 'Вакцинация до', controller: vaccCtrl),
      ]),
    );
  }
}

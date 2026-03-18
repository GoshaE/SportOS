import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import '../../ui/molecules/app_placeholder.dart';
import 'dog_detail_screen.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR2 — Мои собаки
class MyDogsScreen extends StatefulWidget {
  const MyDogsScreen({super.key});

  @override
  State<MyDogsScreen> createState() => _MyDogsScreenState();
}

class _MyDogsScreenState extends State<MyDogsScreen> {
  final List<Map<String, dynamic>> _dogs = [
    {'id': 'dog-1', 'name': 'Rex', 'breed': 'Сибирский хаски', 'chip': '643093400123456', 'vaccineOk': true, 'starts': 12, 'imageUrl': 'assets/images/dog1.JPG'},
    {'id': 'dog-2', 'name': 'Luna', 'breed': 'Аляскинский маламут', 'chip': '643093400789012', 'vaccineOk': true, 'starts': 8, 'imageUrl': 'assets/images/dog2.jpeg'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Мои собаки')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: _dogs.isEmpty
          ? AppPlaceholder.empty(
              icon: Icons.pets,
              title: 'У вас пока нет собак',
              subtitle: 'Добавьте собаку для участия в мероприятиях',
              actionLabel: 'Добавить собаку',
              onAction: _showAddDog,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _dogs.length,
              itemBuilder: (_, i) {
                final d = _dogs[i];
                final bool vaccineOk = d['vaccineOk'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppHeroCard(
                    closedBorderRadius: 12,
                    openBuilder: (context) => const DogDetailScreen(),
                    closedBuilder: (context) => ListTile(
                      leading: AppAvatar(name: d['name'], imageUrl: d['imageUrl'], size: 48),
                      title: Text(d['name'], style: theme.textTheme.titleSmall),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['breed'], style: theme.textTheme.bodySmall),
                          const SizedBox(height: 2),
                          Text('Чип: ${d['chip']}', style: theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusBadge(
                            text: vaccineOk ? 'Вакцина ✅' : 'Просрочена',
                            type: vaccineOk ? BadgeType.success : BadgeType.error,
                          ),
                          const SizedBox(height: 4),
                          Text('${d['starts']} стартов', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDog() {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final chipCtrl = TextEditingController();

    AppBottomSheet.show(
      context,
      title: 'Добавить собаку',
      initialHeight: 0.75,
      actions: [
        AppButton.primary(
          text: 'Добавить',
          onPressed: () {
            if (nameCtrl.text.isNotEmpty && breedCtrl.text.isNotEmpty) {
              setState(() => _dogs.add({
                'id': 'dog-${_dogs.length + 1}',
                'name': nameCtrl.text,
                'breed': breedCtrl.text,
                'chip': chipCtrl.text.isEmpty ? 'Не указан' : chipCtrl.text,
                'vaccineOk': true,
                'starts': 0,
              }));
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, '${nameCtrl.text} добавлена!');
            }
          },
        ),
      ],
      child: Column(children: [
        AppTextField(label: 'Кличка *', prefixIcon: Icons.pets, controller: nameCtrl),
        const SizedBox(height: 10),
        AppTextField(label: 'Порода *', prefixIcon: Icons.category, controller: breedCtrl),
        const SizedBox(height: 10),
        AppTextField(label: 'Номер чипа', prefixIcon: Icons.memory, controller: chipCtrl, hintText: '15-значный номер ISO 11784/85'),
        const SizedBox(height: 10),
        AppTextField(label: 'Вакцинация до', prefixIcon: Icons.medical_services),
        const SizedBox(height: 10),
        AppTextField(label: 'Дата рождения', prefixIcon: Icons.cake),
      ]),
    );
  }
}

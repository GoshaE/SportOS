import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen: Основная информация мероприятия
///
/// Дата, место, описание, контакты, статус.
class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contactCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _initControllers(EventConfig config) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: config.name);
    _locationCtrl = TextEditingController(text: config.location ?? '');
    _descCtrl = TextEditingController(text: config.description ?? '');
    _contactCtrl = TextEditingController(text: config.contactInfo ?? '');
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(eventConfigProvider);
    _initControllers(config);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Основное')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Статус ───
        _sectionTitle(cs, 'Статус мероприятия', Icons.flag),
        AppCard(padding: EdgeInsets.zero, children: [
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _statusColor(config.status, cs).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_statusIcon(config.status), size: 18, color: _statusColor(config.status, cs)),
            ),
            title: Text(_statusLabel(config.status), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_statusHint(config.status), style: TextStyle(fontSize: 12, color: cs.outline)),
            trailing: _nextStatusButton(config.status, cs),
          ),
        ]),
        const SizedBox(height: 20),

        // ─── Название ───
        _sectionTitle(cs, 'Название', Icons.title),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Чемпионат Урала 2026',
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // ─── Даты ───
        _sectionTitle(cs, 'Даты проведения', Icons.calendar_month),
        Row(children: [
          Expanded(child: _DateCard(
            label: 'Начало',
            date: config.startDate,
            color: cs.primary,
            onTap: () => _pickDate(context, config.startDate, (d) {
              ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(startDate: d));
            }),
          )),
          const SizedBox(width: 12),
          Expanded(child: _DateCard(
            label: 'Окончание',
            date: config.endDate ?? config.startDate,
            color: cs.secondary,
            onTap: () => _pickDate(context, config.endDate ?? config.startDate, (d) {
              ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(endDate: d));
            }),
          )),
        ]),
        const SizedBox(height: 20),

        // ─── Место ───
        _sectionTitle(cs, 'Место проведения', Icons.location_on),
        TextField(
          controller: _locationCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Екатеринбург, озеро Шарташ',
            prefixIcon: Icon(Icons.place),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Описание ───
        _sectionTitle(cs, 'Описание', Icons.description),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Описание мероприятия для участников...',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 20),

        // ─── Контакты ───
        _sectionTitle(cs, 'Контактная информация', Icons.phone),
        TextField(
          controller: _contactCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Телефон, email организатора',
            prefixIcon: Icon(Icons.contact_phone),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Сохранить ───
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Сохранить'),
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _save() {
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      contactInfo: _contactCtrl.text.trim().isNotEmpty ? _contactCtrl.text.trim() : null,
    ));
    AppSnackBar.success(context, 'Информация сохранена');
  }

  Future<void> _pickDate(BuildContext context, DateTime initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPicked(picked);
  }

  Widget? _nextStatusButton(EventStatus status, ColorScheme cs) {
    final (nextLabel, nextStatus) = switch (status) {
      EventStatus.draft => ('Открыть регистрацию', EventStatus.registrationOpen),
      EventStatus.registrationOpen => ('Закрыть регистрацию', EventStatus.registrationClosed),
      EventStatus.registrationClosed => ('Начать гонку', EventStatus.inProgress),
      EventStatus.inProgress => ('Завершить', EventStatus.completed),
      EventStatus.completed => ('Архивировать', EventStatus.archived),
      EventStatus.archived => (null, null),
    };
    if (nextLabel == null) return null;
    return FilledButton.tonal(
      onPressed: () {
        ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(status: nextStatus));
      },
      child: Text(nextLabel, style: const TextStyle(fontSize: 12)),
    );
  }

  // ─── Labels ───

  String _statusLabel(EventStatus s) => switch (s) {
    EventStatus.draft => 'Черновик',
    EventStatus.registrationOpen => 'Регистрация открыта',
    EventStatus.registrationClosed => 'Регистрация закрыта',
    EventStatus.inProgress => 'В процессе',
    EventStatus.completed => 'Завершено',
    EventStatus.archived => 'Архив',
  };

  String _statusHint(EventStatus s) => switch (s) {
    EventStatus.draft => 'Мероприятие не видно участникам',
    EventStatus.registrationOpen => 'Участники могут подавать заявки',
    EventStatus.registrationClosed => 'Жеребьёвка, финальная подготовка',
    EventStatus.inProgress => 'Гонка идёт, хронометраж активен',
    EventStatus.completed => 'Протоколы опубликованы',
    EventStatus.archived => 'Мероприятие в архиве',
  };

  IconData _statusIcon(EventStatus s) => switch (s) {
    EventStatus.draft => Icons.edit_note,
    EventStatus.registrationOpen => Icons.how_to_reg,
    EventStatus.registrationClosed => Icons.lock_outline,
    EventStatus.inProgress => Icons.play_circle_outline,
    EventStatus.completed => Icons.check_circle_outline,
    EventStatus.archived => Icons.archive,
  };

  Color _statusColor(EventStatus s, ColorScheme cs) => switch (s) {
    EventStatus.draft => cs.outline,
    EventStatus.registrationOpen => const Color(0xFF2E7D32),
    EventStatus.registrationClosed => const Color(0xFFE65100),
    EventStatus.inProgress => cs.primary,
    EventStatus.completed => const Color(0xFF1565C0),
    EventStatus.archived => cs.outline,
  };

  Widget _sectionTitle(ColorScheme cs, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
      ]),
    );
  }
}

// ─── Date Card Widget ───

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  const _DateCard({required this.label, required this.date, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return AppCard(padding: EdgeInsets.zero, children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${date.day}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(months[date.month - 1], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                Text('${date.year}', style: TextStyle(fontSize: 11, color: cs.outline)),
              ]),
            ]),
          ]),
        ),
      ),
    ]);
  }
}

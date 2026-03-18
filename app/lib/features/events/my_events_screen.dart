import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/event/config_providers.dart';
import '../../domain/event/event_config.dart' hide TimeOfDay;

/// Screen ID: M1 — Мои мероприятия (с табами)
class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(eventConfigProvider.notifier).disciplines;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppAppBar(
          title: const Text('Мои мероприятия'),
          bottom: const AppPillTabBar(
            tabs: ['Предстоящие', 'Прошедшие', 'Организую'],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.add), tooltip: 'Создать мероприятие', onPressed: () => context.push('/my/create')),
          ],
        ),
        body: TabBarView(children: [
          // ── Предстоящие ──
          ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            AppEventCard(
              title: 'Чемпионат Урала 2026',
              subtitle: '15 марта · Екатеринбург',
              sport: 'Скиджоринг 5км',
              slotsText: 'BIB 42',
              badge: 'Зарегистрирован',
              status: EventCardStatus.upcoming,
              accentColor: cs.primary,
              imageUrl: 'assets/images/event1.jpeg',
              onTap: () => context.push('/hub/event/evt-1'),
              mode: EventCardMode.hero,
            ),
            AppEventCard(
              title: 'Лесная гонка 2026',
              subtitle: '22 апреля · Казань',
              sport: 'Каникросс 3км',
              badge: 'Ожидает оплаты',
              status: EventCardStatus.upcoming,
              accentColor: cs.tertiary,
              imageUrl: 'assets/images/event2.jpg',
              onTap: () => context.push('/hub/event/evt-2'),
              mode: EventCardMode.hero,
            ),
          ]),

          // ── Прошедшие ──
          ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            AppEventCard(
              title: 'Кубок Сибири 2025',
              subtitle: '20 декабря · Новосибирск',
              sport: 'Скиджоринг 10км',
              slotsText: '🥈 2 место · 1:12:45',
              badge: 'Завершено',
              status: EventCardStatus.completed,
              accentColor: cs.secondary,
              imageUrl: 'assets/images/event3.jpeg',
              onTap: () => context.push('/hub/event/evt-6'),
              mode: EventCardMode.hero,
            ),
          ]),

          // ── Организую (из провайдера) ──
          ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            // Красивая карточка из провайдера
            AppEventCard(
              title: config.name,
              subtitle: '${_fmtDate(config.startDate)}${config.location != null ? ' · ${config.location}' : ''}',
              sport: disciplines.isNotEmpty ? disciplines.map((d) => d.name).join(', ') : 'Нет дисциплин',
              badge: _statusBadge(config.status),
              status: _cardStatus(config.status),
              accentColor: _statusAccent(config.status, cs),
              imageUrl: config.logoUrl ?? 'assets/images/event1.jpeg',
              onTap: () => context.push('/hub/event/${config.id}'),
              mode: EventCardMode.hero,
            ),
            const SizedBox(height: 8),
            // Quick actions row
            Row(children: [
              Expanded(child: AppButton.primary(
                text: 'Подробнее',
                icon: Icons.visibility,
                onPressed: () => context.push('/hub/event/${config.id}'),
              )),
              const SizedBox(width: 8),
              Expanded(child: AppButton.secondary(
                text: 'Управлять',
                icon: Icons.settings,
                onPressed: () => context.push('/manage/${config.id}'),
              )),
            ]),
            const SizedBox(height: 16),
            AppButton.secondary(
              text: 'Создать мероприятие',
              icon: Icons.add,
              onPressed: () => context.push('/my/create'),
            ),
          ]),
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _statusBadge(EventStatus s) => switch (s) {
    EventStatus.draft => 'Черновик',
    EventStatus.registrationOpen => 'Регистрация открыта',
    EventStatus.registrationClosed => 'Регистрация закрыта',
    EventStatus.inProgress => 'LIVE',
    EventStatus.completed => 'Завершено',
    EventStatus.archived => 'Архив',
  };

  EventCardStatus _cardStatus(EventStatus s) => switch (s) {
    EventStatus.draft => EventCardStatus.upcoming,
    EventStatus.registrationOpen => EventCardStatus.upcoming,
    EventStatus.registrationClosed => EventCardStatus.upcoming,
    EventStatus.inProgress => EventCardStatus.live,
    EventStatus.completed => EventCardStatus.completed,
    EventStatus.archived => EventCardStatus.completed,
  };

  Color _statusAccent(EventStatus s, ColorScheme cs) => switch (s) {
    EventStatus.draft => cs.outline,
    EventStatus.registrationOpen => cs.primary,
    EventStatus.registrationClosed => cs.tertiary,
    EventStatus.inProgress => cs.error,
    EventStatus.completed => cs.secondary,
    EventStatus.archived => cs.outline,
  };
}

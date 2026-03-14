import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: M1 — Мои мероприятия (с табами)
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
            AppEventCard(
              title: 'Кубок Москвы',
              subtitle: '15 ноября · Москва',
              sport: 'Скиджоринг 5км',
              slotsText: '4 место · 42:30',
              badge: 'Завершено',
              status: EventCardStatus.completed,
              accentColor: cs.outlineVariant,
              imageUrl: 'assets/images/event4.jpg',
              onTap: () => context.push('/hub/event/evt-7'),
              mode: EventCardMode.hero,
            ),
            AppEventCard(
              title: 'Кубок Урала 2025',
              subtitle: '20 октября · Екатеринбург',
              sport: 'Каникросс 3км',
              slotsText: '🥉 3 место · 18:05',
              badge: 'Завершено',
              status: EventCardStatus.completed,
              accentColor: cs.outlineVariant,
              imageUrl: 'assets/images/event5.jpg',
              onTap: () => context.push('/hub/event/evt-8'),
              mode: EventCardMode.hero,
            ),
          ]),

          // ── Организую ──
          ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            _OrgEventCard(
              title: 'Ночная гонка 2026',
              subtitle: '10 мая · Кавголово',
              detail: '48/60 участников · Регистрация открыта',
              eventId: 'evt-1',
            ),
            _OrgEventCard(
              title: 'Контрольный старт',
              subtitle: '25 марта · Кавголово',
              detail: '12 участников · Закрытое (клубное)',
              eventId: 'evt-5',
            ),
            const SizedBox(height: 12),
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
}


// ── Карточка организатора ──
class _OrgEventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final String eventId;

  const _OrgEventCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/manage/$eventId'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.admin_panel_settings, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(detail, style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
              )),
            ])),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.push('/manage/$eventId'),
              child: Text('Управлять', style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimary)),
            ),
          ]),
        ),
      ),
    );
  }
}

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
            IconButton(icon: const Icon(Icons.add), tooltip: 'Создать', onPressed: () => _showCreateSheet(context)),
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

          // ── Организую ──
          ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
            // ── Quick Timer CTA ──
            AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: cs.tertiaryContainer.withOpacity(0.08),
              borderColor: cs.tertiary.withOpacity(0.2),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/quick-timer'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.tertiary.withOpacity(0.15), cs.tertiary.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.timer, size: 28, color: cs.tertiary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('⚡ Быстрый Секундомер', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Засечь тренировку без создания мероприятия', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ])),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

  void _showCreateSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    AppBottomSheet.show(
      context,
      title: 'Что создаём?',
      initialHeight: 0.38,
      child: Column(children: [
        // ── Мероприятие ──
        _CreateOptionCard(
          icon: Icons.emoji_events,
          color: cs.primary,
          title: 'Мероприятие',
          subtitle: 'Полный процесс: регистрация, дисциплины, хронометраж',
          textTheme: textTheme,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push('/my/create');
          },
        ),
        const SizedBox(height: 12),
        // ── Быстрый старт ──
        _CreateOptionCard(
          icon: Icons.timer,
          color: cs.tertiary,
          title: '⚡ Быстрый старт',
          subtitle: 'Секундомер для тренировок. Без регистрации, сразу таймер',
          textTheme: textTheme,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push('/quick-timer');
          },
        ),
      ]),
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

/// Карточка выбора действия (для BottomSheet «Что создаём?»).
class _CreateOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            )),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
          ]),
        ),
      ),
    );
  }
}

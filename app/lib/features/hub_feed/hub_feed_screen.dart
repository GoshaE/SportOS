import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: H1 — Хаб / Лента (с фильтрами)
class HubFeedScreen extends StatefulWidget {
  const HubFeedScreen({super.key});

  @override
  State<HubFeedScreen> createState() => _HubFeedScreenState();
}

class _HubFeedScreenState extends State<HubFeedScreen> {
  String _sport = 'Все';

  final _sports = const [
    _SportFilter('Все', Icons.sports),
    _SportFilter('Ездовой спорт', Icons.pets),
    _SportFilter('Каникросс', Icons.directions_run),
    _SportFilter('Лыжные гонки', Icons.downhill_skiing),
    _SportFilter('Биатлон', Icons.track_changes),
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateNetworkLoad();
  }

  Future<void> _simulateNetworkLoad() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isLoading = false);
  }

  // ... rest of the code ...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: Text('SportOS', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/hub/search')),
          IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'QR Pairing', onPressed: () => context.push('/pair')),
        ],
      ),
      body: Column(children: [
        // ── Фильтры по спорту ──
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _sports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final s = _sports[i];
              final sel = _sport == s.label;
              return ChoiceChip(
                avatar: Icon(s.icon, size: 16),
                label: Text(s.label),
                selected: sel,
                onSelected: (_) => setState(() => _sport = s.label),
              );
            },
          ),
        ),

        // ── Лента мероприятий ──
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // 100 = floating nav clearance
          children: [
            // Ближайшие
            AppSectionHeader(title: 'Ближайшие', icon: Icons.local_fire_department),
            if (_isLoading) ...[
              const AppEventCardSkeleton(isHero: true),
              const AppEventCardSkeleton(isHero: true),
              const AppEventCardSkeleton(isHero: true),
            ] else ...[
              AppEventCard(
                title: 'Чемпионат Урала 2026',
                subtitle: '15 марта · Екатеринбург',
                sport: 'Ездовой спорт · 6 дисциплин',
                slotsText: '48 / 60 мест',
                slotsProgress: 48 / 60,
                accentColor: cs.primary,
                badge: 'Открыто',
                status: EventCardStatus.upcoming,
                mode: EventCardMode.hero,
                heroTag: 'hero-evt-1',
                imageUrl: 'assets/images/event1.jpeg',
                onTap: () => context.push(
                  '/hub/event/evt-1',
                  extra: {
                    'heroTag': 'hero-evt-1',
                    'imageUrl': 'assets/images/event1.jpeg',
                  },
                ),
              ),
              AppEventCard(
                title: 'Лесная гонка 2026',
                subtitle: '22 апреля · Казань',
                sport: 'Каникросс · 3 дисциплины',
                slotsText: '10 / 12 мест',
                slotsProgress: 10 / 12,
                accentColor: cs.tertiary,
                badge: 'Открыто',
                status: EventCardStatus.upcoming,
                mode: EventCardMode.hero,
                heroTag: 'hero-evt-2',
                imageUrl: 'https://images.unsplash.com/photo-1533560904424-a0c61dc306fc?auto=format&fit=crop&w=1000',
                onTap: () => context.push(
                  '/hub/event/evt-2',
                  extra: {
                    'heroTag': 'hero-evt-2',
                    'imageUrl': 'https://images.unsplash.com/photo-1533560904424-a0c61dc306fc?auto=format&fit=crop&w=1000',
                  },
                ),
              ),
              AppEventCard(
                title: 'Зимний Кубок 2026',
                subtitle: '10 мая · Кавголово',
                sport: 'Лыжные гонки · 4 дисциплины',
                accentColor: cs.secondary,
                badge: 'Скоро',
                status: EventCardStatus.draft,
                mode: EventCardMode.hero,
                heroTag: 'hero-evt-3',
                imageUrl: 'assets/images/event4.jpg',
                onTap: () => context.push(
                  '/hub/event/evt-3',
                  extra: {
                    'heroTag': 'hero-evt-3',
                    'imageUrl': 'assets/images/event4.jpg',
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Кубки / Серии
            AppSectionHeader(title: 'Кубки / Серии', icon: Icons.emoji_events),
            if (_isLoading) ...[
              const AppEventCardSkeleton(isHero: false),
              const AppEventCardSkeleton(isHero: false),
            ] else ...[
              _SeriesCard(
                title: 'Кубок Сибири 2026',
                schedule: '5 этапов · Январь — Май',
                progress: '2 из 5 завершены · 86 участников',
                progressValue: 2 / 5,
                seriesId: 'cup-1',
              ),
              _SeriesCard(
                title: 'Серия Лесных Забегов',
                schedule: '3 этапа · Июнь — Август',
                progress: 'Регистрация открыта',
                progressValue: 0.0,
                seriesId: 'cup-2',
              ),
            ],

            const SizedBox(height: 16),

            // Прошедшие
            AppSectionHeader(title: 'Прошедшие', icon: Icons.history),
            AppEventCard(
              title: 'Кубок Сибири 2025',
              subtitle: '20 декабря · Новосибирск',
              sport: 'Ездовой спорт · 87 участников',
              accentColor: cs.outlineVariant,
              badge: 'Завершено',
              status: EventCardStatus.completed,
              mode: EventCardMode.hero,
              heroTag: 'hero-evt-6',
              imageUrl: 'assets/images/event5.jpg',
              onTap: () => context.push(
                '/hub/event/evt-6',
                extra: {
                  'heroTag': 'hero-evt-6',
                  'imageUrl': 'assets/images/event5.jpg',
                },
              ),
            ),
            AppEventCard(
              title: 'Кубок Москвы',
              subtitle: '15 ноября · Москва',
              sport: 'Ездовой спорт · 42 участника',
              accentColor: cs.outlineVariant,
              badge: 'Завершено',
              status: EventCardStatus.completed,
              mode: EventCardMode.hero,
              heroTag: 'hero-evt-7',
              imageUrl: 'assets/images/event6.jpg',
              onTap: () => context.push(
                '/hub/event/evt-7',
                extra: {
                  'heroTag': 'hero-evt-7',
                  'imageUrl': 'assets/images/event6.jpg',
                },
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

// ── Data ──
class _SportFilter {
  final String label;
  final IconData icon;
  const _SportFilter(this.label, this.icon);
}



// ── Series Card ──
class _SeriesCard extends StatelessWidget {
  final String title;
  final String schedule;
  final String progress;
  final double progressValue;
  final String seriesId;

  const _SeriesCard({
    required this.title,
    required this.schedule,
    required this.progress,
    required this.progressValue,
    required this.seriesId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/series/$seriesId'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primaryContainer,
                            cs.primary.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.emoji_events, size: 24, color: cs.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              StatusBadge(text: 'Серия', type: BadgeType.info, icon: Icons.auto_awesome_motion),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(schedule, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(progress, style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    )),
                    Text('${(progressValue * 100).toInt()}%', style: theme.textTheme.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

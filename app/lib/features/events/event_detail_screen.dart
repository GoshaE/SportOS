import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/event/config_providers.dart';
import '../../domain/event/event_config.dart' hide TimeOfDay;
import '../../domain/timing/models.dart';

/// Screen ID: H2 — Детали мероприятия
///
/// Data-driven: читает из eventConfigProvider.
/// Кнопки управления и судейства доступны всем (пока без ролей).
class EventDetailScreen extends ConsumerWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedEventId = eventId ?? _tryGetRouterEventId(context);
    final extra = _tryGetRouterExtra(context);
    final heroTag = extra?['heroTag'] as String?;

    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(eventConfigProvider.notifier).disciplines;
    final imageUrl = config.logoUrl ?? 'assets/images/event1.jpeg';

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ═══════════════════════════════════════
              // HERO BANNER
              // ═══════════════════════════════════════
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                actions: [
                  IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () => AppSnackBar.success(context, 'Добавлено в избранное'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      heroTag != null
                        ? Hero(tag: heroTag, child: AppCachedImage(url: imageUrl, fit: BoxFit.cover))
                        : AppCachedImage(url: imageUrl, fit: BoxFit.cover),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.4, 0.75, 1.0],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StatusBadge(
                                text: _statusLabel(config.status),
                                type: _badgeType(config.status),
                              ),
                              const SizedBox(height: 8),
                              Text(config.name, style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold,
                              )),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(_fmtDate(config.startDate), style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                                if (config.location != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(config.location!, style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ), overflow: TextOverflow.ellipsis)),
                                ],
                              ]),
                              if (disciplines.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Icon(Icons.sports, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(
                                    '${disciplines.length} ${_discWord(disciplines.length)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  )),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══════════════════════════════════════
              // CONTENT
              // ═══════════════════════════════════════
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList(delegate: SliverChildListDelegate([

                  // 1️⃣ Action grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      _ActionTile(icon: Icons.settings, label: 'Управлять', color: cs.primary,
                        onTap: () => context.push('/manage/$resolvedEventId')),
                      _ActionTile(icon: Icons.people, label: 'Участники', color: cs.secondary,
                        onTap: () => context.push('/hub/event/$resolvedEventId/participants')),
                      _ActionTile(icon: Icons.leaderboard, label: 'Результаты', color: cs.tertiary,
                        onTap: () => context.push('/results/$resolvedEventId/live')),
                      _ActionTile(icon: Icons.timer, label: 'Хронометраж', color: Colors.deepOrange,
                        onTap: () => context.push('/events/$resolvedEventId/timing')),
                      _ActionTile(icon: Icons.gavel, label: 'Судейство', color: cs.error,
                        onTap: () => context.push('/ops/$resolvedEventId/timing')),
                     ],
                  ),
                  const SizedBox(height: 16),

                  // 2️⃣ Дисциплины (из провайдера)
                  if (disciplines.isNotEmpty) ...[
                    _DisciplineSection(disciplines: disciplines),
                    const SizedBox(height: 12),
                  ],

                  // 3️⃣ Расписание (из days + firstStartTime)
                  if (config.days.isNotEmpty || disciplines.isNotEmpty) ...[
                    AppSectionHeader(title: 'Расписание', icon: Icons.schedule),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      children: _buildSchedule(config, disciplines),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 4️⃣ Информация (Bento Grid)
                  AppSectionHeader(title: 'Информация', icon: Icons.info_outline),
                  Row(children: [
                    _BentoItem(
                      icon: Icons.location_on, title: 'Место',
                      value: config.location ?? 'Не указано',
                      onTap: () => _showInfoModal(context, cs, theme, 'Локация', Icons.location_on, config.location ?? 'Место не указано'),
                      cs: cs, theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _BentoItem(
                      icon: Icons.payments, title: 'Взнос',
                      value: _minPrice(disciplines),
                      onTap: () => _showInfoModal(context, cs, theme, 'Стоимость', Icons.payments,
                        disciplines.map((d) => '${d.name}: ${d.priceRub != null ? "${d.priceRub} ₽" : "бесплатно"}').join('\n')),
                      cs: cs, theme: theme,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // 5️⃣ Описание (если есть)
                  if (config.description != null && config.description!.isNotEmpty) ...[
                    AppSectionHeader(title: 'О мероприятии', icon: Icons.description),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(config.description!, style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant, height: 1.5,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 6️⃣ Контакты (если есть)
                  if (config.contactInfo != null && config.contactInfo!.isNotEmpty) ...[
                    AppSectionHeader(title: 'Контакты', icon: Icons.phone),
                    AppCard(
                      padding: EdgeInsets.zero,
                      children: [
                        ListTile(
                          leading: Icon(Icons.contact_phone, color: cs.primary),
                          title: Text(config.contactInfo!, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ],

                ])),
              ),
            ],
          ),

          // Floating Action Bar
          Positioned(
            left: 16, right: 16, bottom: 24,
            child: SafeArea(
              child: _RegisterCard(eventId: resolvedEventId, cs: cs, theme: theme, disciplines: disciplines),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _statusLabel(EventStatus s) => switch (s) {
    EventStatus.draft => 'Черновик',
    EventStatus.registrationOpen => 'Регистрация открыта',
    EventStatus.registrationClosed => 'Регистрация закрыта',
    EventStatus.inProgress => 'LIVE',
    EventStatus.completed => 'Завершено',
    EventStatus.archived => 'Архив',
  };

  BadgeType _badgeType(EventStatus s) => switch (s) {
    EventStatus.draft => BadgeType.neutral,
    EventStatus.registrationOpen => BadgeType.success,
    EventStatus.registrationClosed => BadgeType.warning,
    EventStatus.inProgress => BadgeType.error,
    EventStatus.completed => BadgeType.neutral,
    EventStatus.archived => BadgeType.neutral,
  };

  String _discWord(int n) {
    if (n == 1) return 'дисциплина';
    if (n >= 2 && n <= 4) return 'дисциплины';
    return 'дисциплин';
  }

  String _minPrice(List<DisciplineConfig> disciplines) {
    final prices = disciplines.where((d) => d.priceRub != null).map((d) => d.priceRub!).toList();
    if (prices.isEmpty) return 'Бесплатно';
    prices.sort();
    return 'от ${prices.first} ₽';
  }

  List<Widget> _buildSchedule(EventConfig config, List<DisciplineConfig> disciplines) {
    final items = <Widget>[];
    // Generate schedule from disciplines' firstStartTime
    final sorted = [...disciplines]..sort((a, b) => a.firstStartTime.compareTo(b.firstStartTime));
    for (var i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      final time = '${d.firstStartTime.hour.toString().padLeft(2, '0')}:${d.firstStartTime.minute.toString().padLeft(2, '0')}';
      items.add(AppTimelineRow(
        time: time,
        title: 'Старт: ${d.name}',
        subtitle: '${d.startType.name} · ${d.distanceKm} км',
        isFirst: i == 0,
        isLast: i == sorted.length - 1,
        icon: _discIcon(d.startType),
      ));
    }
    if (items.isEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Расписание пока не настроено'),
      ));
    }
    return items;
  }

  IconData _discIcon(StartType t) => switch (t) {
    StartType.individual => Icons.person,
    StartType.mass => Icons.groups,
    StartType.wave => Icons.waves,
    StartType.pursuit => Icons.speed,
    StartType.relay => Icons.people,
  };
}

// ═══════════════════════════════════════
// Action Tile (grid button)
// ═══════════════════════════════════════
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showInfoModal(BuildContext context, ColorScheme cs, ThemeData theme, String title, IconData icon, String content) {
  AppBottomSheet.show(
    context,
    title: title,
    initialHeight: 0.5,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 24),
        Text(content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: cs.onSurfaceVariant)),
        const SizedBox(height: 32),
        AppButton.primary(text: 'Понятно', onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
      ],
    ),
  );
}

// ═══════════════════════════════════════
// Bento Grid Item
// ═══════════════════════════════════════
class _BentoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final ColorScheme cs;
  final ThemeData theme;

  const _BentoItem({required this.icon, required this.title, required this.value,
    required this.onTap, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: EdgeInsets.zero,
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                ]),
                const SizedBox(height: 12),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(title, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.normal)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _tryGetRouterEventId(BuildContext context) {
  try { return GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1'; }
  catch (_) { return 'evt-1'; }
}

Map<String, dynamic>? _tryGetRouterExtra(BuildContext context) {
  try { return GoRouterState.of(context).extra as Map<String, dynamic>?; }
  catch (_) { return null; }
}

// ═══════════════════════════════════════
// Register Card
// ═══════════════════════════════════════
class _RegisterCard extends StatelessWidget {
  final String eventId;
  final ColorScheme cs;
  final ThemeData theme;
  final List<DisciplineConfig> disciplines;
  const _RegisterCard({required this.eventId, required this.cs, required this.theme, required this.disciplines});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      borderColor: cs.primary.withValues(alpha: 0.3),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/hub/event/$eventId/register'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.how_to_reg, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Регистрация', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${disciplines.length} ${_discWord(disciplines.length)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              AppButton.small(
                text: 'Выбрать',
                onPressed: () => context.push('/hub/event/$eventId/register'),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  String _discWord(int n) {
    if (n == 1) return 'дисциплина';
    if (n >= 2 && n <= 4) return 'дисциплины';
    return 'дисциплин';
  }
}

// ═══════════════════════════════════════
// Disciplines Section (data-driven)
// ═══════════════════════════════════════
class _DisciplineSection extends StatefulWidget {
  final List<DisciplineConfig> disciplines;
  const _DisciplineSection({required this.disciplines});

  @override
  State<_DisciplineSection> createState() => _DisciplineSectionState();
}

class _DisciplineSectionState extends State<_DisciplineSection> {
  bool _expanded = false;
  static const _initialCount = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final all = widget.disciplines;
    final showToggle = all.length > _initialCount;
    final visible = _expanded ? all : all.take(_initialCount).toList();

    return Column(children: [
      Row(children: [
        Icon(Icons.sports, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text('Дисциплины', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(' · ${all.length}', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        if (showToggle) InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_expanded ? 'Свернуть' : 'Ещё ${all.length - _initialCount}',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.primary)),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, size: 18, color: cs.primary),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: AppCard(
          padding: EdgeInsets.zero,
          children: List.generate(visible.length, (i) =>
            _DisciplineRow(disc: visible[i], isLast: i == visible.length - 1),
          ),
        ),
      ),
    ]);
  }
}

class _DisciplineRow extends StatelessWidget {
  final DisciplineConfig disc;
  final bool isLast;
  const _DisciplineRow({required this.disc, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(), size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(disc.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${disc.distanceKm} км · ${disc.startType.name}',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
          ])),
          if (disc.priceRub != null)
            Text('${disc.priceRub} ₽', style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold, color: cs.onSurface,
            )),
        ]),
      ),
      if (!isLast) Divider(height: 1, indent: 62, endIndent: 14, color: cs.outlineVariant.withValues(alpha: 0.3)),
    ]);
  }

  IconData _icon() => switch (disc.startType) {
    StartType.individual => Icons.person,
    StartType.mass => Icons.groups,
    StartType.wave => Icons.waves,
    StartType.pursuit => Icons.speed,
    StartType.relay => Icons.people,
  };
}

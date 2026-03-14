import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';

/// Screen ID: H2 — Детали мероприятия (для участника)
class EventDetailScreen extends StatelessWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  // Simulate registration state: true = registered, false = not
  bool get _isRegistered => true;
  // Simulate event state: 'upcoming', 'live', 'finished'
  String get _eventState => 'upcoming';

  @override
  Widget build(BuildContext context) {
    final resolvedEventId = eventId ?? _tryGetRouterEventId(context);
    final extra = _tryGetRouterExtra(context);
    final heroTag = extra?['heroTag'] as String?;
    final imageUrl = extra?['imageUrl'] as String? ?? 'assets/images/event1.jpeg';

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ═══════════════════════════════════════
              // HERO BANNER (тёмный gradient для читаемости)
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
                      // Backdrop / Image
                      heroTag != null 
                        ? Hero(tag: heroTag, child: AppCachedImage(url: imageUrl, fit: BoxFit.cover))
                        : AppCachedImage(url: imageUrl, fit: BoxFit.cover),
                      // Premium Dark Gradient overlay for text readability
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
                                text: _eventState == 'finished' ? 'Завершено' : _eventState == 'live' ? 'LIVE' : 'Регистрация открыта',
                                type: _eventState == 'finished' ? BadgeType.neutral : _eventState == 'live' ? BadgeType.error : BadgeType.success,
                              ),
                              const SizedBox(height: 8),
                              Text('Чемпионат Урала 2026', style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold,
                              )),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text('15 марта 2026', style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text('Екатеринбург', style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                              ]),
                              const SizedBox(height: 8),
                              // Участники progress
                              Row(children: [
                                Icon(Icons.groups, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                                const SizedBox(width: 6),
                                Text('48 / 60 мест', style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 48 / 60,
                                    minHeight: 4,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                                  ),
                                )),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══════════════════════════════════════
              // CONTENT (порядок: важное сверху)
              // ═══════════════════════════════════════
              SliverPadding(
                // Increased bottom padding to accommodate floating action bar
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList(delegate: SliverChildListDelegate([

                  // 1️⃣ Быстрые действия (Управление, Результаты, Протоколы)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.settings, size: 16, color: theme.colorScheme.primary),
                        label: Text('Управлять', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        side: BorderSide(color: theme.colorScheme.primaryContainer),
                        shape: const StadiumBorder(),
                        onPressed: () => context.push('/manage/$resolvedEventId'),
                      ),
                      ActionChip(
                        avatar: Icon(Icons.leaderboard, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        label: Text('Результаты', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        onPressed: () => context.push('/results/$resolvedEventId/live'),
                      ),
                      ActionChip(
                        avatar: Icon(Icons.article, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        label: Text('Протоколы', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        onPressed: () => context.push('/results/$resolvedEventId/protocol'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2️⃣ Результаты Top-3 (если live/finished)
                  if (_eventState == 'live' || _eventState == 'finished') ...[
                    _ResultsPreview(eventId: resolvedEventId, isLive: _eventState == 'live'),
                    const SizedBox(height: 12),
                  ],

                  // 3️⃣ Дисциплины (collapsible)
                  const SizedBox(height: 8),
                  _DisciplineSection(),
                  const SizedBox(height: 12),

                  // 4️⃣ Информация (Interactive Bento Grid)
                  // 4️⃣ Расписание
                  AppSectionHeader(title: 'Расписание', icon: Icons.schedule),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    children: const [
                      AppTimelineRow(
                        time: '09:00',
                        title: 'Открытие выдачи стартовых пакетов',
                        subtitle: 'Палатка секретариата',
                        isPast: true,
                        isFirst: true,
                      ),
                      AppTimelineRow(
                        time: '10:30',
                        title: 'Брифинг для участников',
                        subtitle: 'Обязательное присутствие',
                        isCurrent: true,
                        icon: Icons.campaign,
                      ),
                      AppTimelineRow(
                        time: '11:00',
                        title: 'Старт первой дистанции',
                        subtitle: 'Скиджоринг 5км',
                      ),
                      AppTimelineRow(
                        time: '15:00',
                        title: 'Церемония награждения',
                        isLast: true,
                        icon: Icons.emoji_events,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5️⃣ Информация (Interactive Bento Grid)
                  AppSectionHeader(title: 'Информация', icon: Icons.info_outline),
                  Row(children: [
                    _BentoItem(
                      icon: Icons.location_on, title: 'Место', value: 'Парк «Лесная»', 
                      onTap: () => _showInfoModal(context, cs, theme, 'Локация', Icons.location_on, 'Свердловская область, г. Екатеринбург\nПарк «Лесная сказка»\nКоординаты GPS: 56.8389° N, 60.6057° E\nПредусмотрена бесплатная парковка.'),
                      cs: cs, theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _BentoItem(
                      icon: Icons.payments, title: 'Взнос', value: '2 000 ₽', 
                      onTap: () => _showInfoModal(context, cs, theme, 'Условия участия', Icons.payments, 'Скиджоринг 5км: 2000 ₽\nУпряжки 10км: 3500 ₽\n\nВозврат 100% до 1 марта\nВозврат 50% до 10 марта'),
                      cs: cs, theme: theme,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _BentoItem(
                      icon: Icons.pin_drop, title: 'GPS', value: '56.8389° N...', 
                      onTap: () => _showInfoModal(context, cs, theme, 'Локация', Icons.location_on, 'Свердловская область, г. Екатеринбург\nПарк «Лесная сказка»\nКоординаты GPS: 56.8389° N, 60.6057° E\nПредусмотрена бесплатная парковка.'),
                      cs: cs, theme: theme,
                    ),
                    const SizedBox(width: 8),
                    // Пустой блок для выравнивания сетки
                    Expanded(child: const SizedBox()),
                  ]),
                  const SizedBox(height: 12),

                  // 5️⃣ Организатор
                  AppSectionHeader(title: 'Организатор', icon: Icons.business),
                  AppCard(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: AppAvatar(name: 'Быстрые лапы', size: 44),
                        title: Text('Клуб «Быстрые лапы»', style: theme.textTheme.titleSmall),
                        subtitle: Text('Санкт-Петербург · 25 членов', style: theme.textTheme.bodySmall),
                        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                        onTap: () => context.push('/profile/clubs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                ])),
              ),
            ],
          ),
          
          // Floating Action Bar (Glass Pill)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: _isRegistered ? _RegisteredCard(cs: cs, theme: theme) : _RegisterCard(eventId: resolvedEventId, cs: cs, theme: theme),
            ),
          ),
        ],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cs.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          AppButton.primary(
            text: 'Понятно',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

// ═══════════════════════════════════════
// Interactive Bento Grid Item
// ═══════════════════════════════════════
class _BentoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final ColorScheme cs;
  final ThemeData theme;

  const _BentoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: EdgeInsets.zero,
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
                      ),
                      const Spacer(),
                      Icon(Icons.open_in_new, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, height: 1.3,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(title, style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.normal,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _tryGetRouterEventId(BuildContext context) {
  try {
    return GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';
  } catch (_) {
    return 'evt-1';
  }
}

Map<String, dynamic>? _tryGetRouterExtra(BuildContext context) {
  try {
    return GoRouterState.of(context).extra as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
}


// ═══════════════════════════════════════
// Карточка «Зарегистрироваться»
// ═══════════════════════════════════════
class _RegisterCard extends StatelessWidget {
  final String eventId;
  final ColorScheme cs;
  final ThemeData theme;
  const _RegisterCard({required this.eventId, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(999),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.push('/hub/event/$eventId/register'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.how_to_reg, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Зарегистрироваться', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 2),
                Text('6 дисциплин · 2 000–3 500₽', style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                )),
              ])),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: () => context.push('/hub/event/$eventId/register'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Выбрать', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// Карточка «Вы участвуете» (компактная)
// ═══════════════════════════════════════
class _RegisteredCard extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  const _RegisteredCard({required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(999),
      children: [
        Container(
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3)),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _showDetails(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.check_circle, color: cs.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Вы участвуете', style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.primary,
                  )),
                  Text('Скиджоринг 5км · BIB 42', style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
                ])),
                const StatusBadge(text: 'Оплачено', type: BadgeType.success),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: () => _showDetails(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.1),
                      foregroundColor: cs.onPrimaryContainer,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: Text('Билет', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Моя регистрация',
      initialHeight: 0.45,
      actions: [
        AppButton.secondary(text: 'Изменить регистрацию', icon: Icons.edit, onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          AppDetailRow(label: 'Дисциплина', value: 'Скиджоринг 5км', icon: Icons.sports),
          AppDetailRow(label: 'BIB', value: '42', icon: Icons.tag),
          AppDetailRow(label: 'Категория', value: 'M 25-34', icon: Icons.people),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Собаки', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          AppDetailRow(label: 'Rex', value: 'Хаски · Чип: 643...456', icon: Icons.pets),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Оплата', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          AppDetailRow(label: 'Сумма', value: '2 000 ₽', icon: Icons.payments),
          AppDetailRow(label: 'Способ', value: 'Перевод на карту', icon: Icons.credit_card),
          AppDetailRow(label: 'Статус', value: 'Подтверждена ✅', icon: Icons.verified),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════
// Дисциплины (collapsible, 3 по умолчанию)
// ═══════════════════════════════════════
class _DisciplineSection extends StatefulWidget {
  @override
  State<_DisciplineSection> createState() => _DisciplineSectionState();
}

class _DisciplineSectionState extends State<_DisciplineSection> {
  bool _expanded = false;

  static const _disciplines = [
    _Disc('Скиджоринг 5км', 18, 20, 2000, Icons.downhill_skiing),
    _Disc('Скиджоринг 10км', 12, 15, 3000, Icons.downhill_skiing),
    _Disc('Каникросс 3км', 8, 10, 1500, Icons.directions_run),
    _Disc('Нарты 15км', 6, 10, 3500, Icons.sledding),
    _Disc('Пулка 5км', 2, 5, 2500, Icons.ac_unit),
    _Disc('Байкджоринг 10км', 2, 5, 2000, Icons.pedal_bike),
  ];

  static const _initialCount = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showToggle = _disciplines.length > _initialCount;
    final visible = _expanded ? _disciplines : _disciplines.take(_initialCount).toList();

    return Column(children: [
      // Header с кнопкой раскрытия справа
      Row(children: [
        Icon(Icons.sports, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text('Дисциплины', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(' · ${_disciplines.length}', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        if (showToggle) InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                _expanded ? 'Свернуть' : 'Ещё ${_disciplines.length - _initialCount}',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
              ),
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

      // Список с анимацией
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

class _Disc {
  final String name;
  final int filled;
  final int total;
  final int price;
  final IconData icon;
  const _Disc(this.name, this.filled, this.total, this.price, this.icon);
  double get ratio => filled / total;
  bool get isHot => ratio >= 0.8;
}

class _DisciplineRow extends StatelessWidget {
  final _Disc disc;
  final bool isLast;
  const _DisciplineRow({required this.disc, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hot = disc.isHot;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (hot ? cs.error : cs.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(disc.icon, size: 18, color: hot ? cs.error : cs.primary),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(child: Text(
            disc.name,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          )),
          // Slots
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${disc.filled}/${disc.total}', style: theme.textTheme.bodySmall?.copyWith(
                color: hot ? cs.error : cs.onSurfaceVariant,
                fontWeight: hot ? FontWeight.bold : null,
              )),
              if (hot) ...[
                const SizedBox(width: 2),
                Icon(Icons.local_fire_department, size: 12, color: cs.error),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${disc.price} ₽', style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold, color: cs.onSurface,
            )),
          ]),
        ]),
      ),
      if (!isLast) Divider(height: 1, indent: 62, endIndent: 14, color: cs.outlineVariant.withValues(alpha: 0.3)),
    ]);
  }
}

// ═══════════════════════════════════════
// Превью результатов (Top-3)
// ═══════════════════════════════════════
class _ResultsPreview extends StatelessWidget {
  final String eventId;
  final bool isLive;
  const _ResultsPreview({required this.eventId, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AppSectionHeader(title: isLive ? 'Результаты LIVE' : 'Результаты', icon: Icons.emoji_events),
        const Spacer(),
        if (isLive) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('LIVE', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
      AppCard(
        padding: EdgeInsets.zero,
        children: [
          const AppResultRow(place: 1, name: 'Иванов Алексей', time: '38:12'),
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.3)),
          const AppResultRow(place: 2, name: 'Петров Сергей', time: '39:45'),
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.3)),
          const AppResultRow(place: 3, name: 'Сидоров Кирилл', time: '41:20'),
          // "Все результаты" link
          InkWell(
            onTap: () => context.push('/results/$eventId/live'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(Icons.leaderboard, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text('Все результаты', style: theme.textTheme.labelLarge?.copyWith(color: cs.primary)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: cs.primary),
              ]),
            ),
          ),
        ],
      ),
    ]);
  }
}

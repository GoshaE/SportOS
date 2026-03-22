import 'package:flutter/material.dart';
import 'package:sportos_app/ui/molecules/app_list_row.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';

/// Screen ID: C2 — Профиль клуба (публичная страница)
/// 4 таба: О клубе | Мероприятия | Рейтинг | Лента
class ClubProfileScreen extends StatefulWidget {
  const ClubProfileScreen({super.key});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // Simulated membership state: null | 'pending' | 'approved' | 'active'
  String? _membershipStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final clubId = GoRouterState.of(context).pathParameters['clubId'] ?? 'club-1';
    final isOwner = clubId == 'club-1';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Hero AppBar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              if (isOwner) IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/clubs/$clubId/manage')),
              IconButton(icon: const Icon(Icons.share), onPressed: () => AppSnackBar.info(context, 'Ссылка скопирована')),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              title: innerBoxIsScrolled ? const Padding(
                padding: EdgeInsets.only(left: 72, bottom: 16),
                child: Text('Быстрые лапы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ) : const SizedBox(),
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Background Cover
                  Image.network(
                    'https://images.unsplash.com/photo-1541819665671-b0db45d2e737?auto=format&fit=crop&w=1000',
                    fit: BoxFit.cover,
                  ),
                  // Gradient for Text Readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Club Logo Avatar
                        Hero(
                          tag: 'club-avatar-$clubId',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2), 
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: AppAvatar(
                              name: 'Быстрые лапы',
                              imageUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=300',
                              size: 72,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Club Info & Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Быстрые лапы', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.8)),
                                  const SizedBox(width: 4),
                                  Text('Санкт-Петербург', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white.withOpacity(0.8))),
                                  const SizedBox(width: 12),
                                  Icon(Icons.people, size: 14, color: Colors.white.withOpacity(0.8)),
                                  const SizedBox(width: 4),
                                  Text('45 участников', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // PillTabBar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              AppPillTabBar(
                controller: _tabController,
                tabs: const ['О клубе', 'Мероприятия', 'Рейтинг', 'Лента'],
                icons: const [Icons.info_outline, Icons.event, Icons.leaderboard, Icons.feed],
                isScrollable: true,
              ),
            ),
          ),
        ],
        body: TabBarView(controller: _tabController, children: [
          _aboutTab(theme, cs, clubId, isOwner),
          _eventsTab(theme, cs),
          _leaderboardTab(theme, cs),
          _feedTab(theme, cs),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Tab 1: О клубе
  // ═══════════════════════════════════════
  Widget _aboutTab(ThemeData theme, ColorScheme cs, String clubId, bool isOwner) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Виды спорта
      Wrap(spacing: 6, children: [
        Chip(label: const Text('🐕 Ездовой спорт'), backgroundColor: cs.primary.withOpacity(0.1)),
        Chip(label: const Text('🏔 Трейл'), backgroundColor: cs.tertiary.withOpacity(0.1)),
      ]),
      const SizedBox(height: 12),

      // Описание
      Text('Сообщество любителей ездового спорта и трейлраннинга. Проводим тренировки, контрольные старты и соревнования. Основан в 2020 году.', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),

      // Статистика
      const Row(children: [
        AppStatCard(value: '45', label: 'участников', icon: Icons.people),
        SizedBox(width: 8),
        AppStatCard(value: '12', label: 'мероприятий', icon: Icons.emoji_events),
        SizedBox(width: 8),
        AppStatCard(value: '3', label: 'тренера', icon: Icons.sports),
      ]),
      const SizedBox(height: 16),

      // Membership Status / Actions
      if (!isOwner) _buildMembershipSection(cs, theme)
      else ...[
        AppButton.primary(
          text: 'Управление клубом',
          icon: Icons.admin_panel_settings,
          onPressed: () => context.push('/clubs/$clubId/manage'),
        ),
        const SizedBox(height: 16),
      ],

      // Контакты
      AppSectionHeader(title: 'Контакты', icon: Icons.contact_mail),
      AppCard(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        AppListRow.detail(label: 'Telegram', value: '@bystryelapy', icon: Icons.telegram),
        AppListRow.detail(label: 'VK', value: 'vk.com/bystryelapy', icon: Icons.language),
        AppListRow.detail(label: 'Email', value: 'club@bystryelapy.ru', icon: Icons.email),
      ]),

      const SizedBox(height: 16),

      // Клубная структура
      AppSectionHeader(title: 'Клубная структура', icon: Icons.account_tree),
      ...[ 
        {'name': 'Иванов Алексей', 'role': 'Владелец', 'type': BadgeType.warning},
        {'name': 'Петрова Мария', 'role': 'Тренер', 'type': BadgeType.success},
        {'name': 'Сидоров Дмитрий', 'role': 'Тренер', 'type': BadgeType.success},
        {'name': 'Волкова Анна', 'role': 'Администратор', 'type': BadgeType.info},
        {'name': 'Кузнецов Игорь', 'role': 'Секретарь', 'type': BadgeType.neutral},
      ].map((m) => AppUserTile(
        name: m['name'] as String,
        dense: true,
        leading: AppAvatar(name: m['name'] as String, size: 32),
        badge: StatusBadge(text: m['role'] as String, type: m['type'] as BadgeType),
      )),

      AppButton.text(
        text: 'Все участники (45)',
        icon: Icons.people,
        onPressed: () {},
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 2: Мероприятия клуба
  // ═══════════════════════════════════════
  Widget _eventsTab(ThemeData theme, ColorScheme cs) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Summary stats
      Row(children: [
        AppStatCard(value: '3', label: 'Предстоящих', icon: Icons.upcoming, color: cs.primary),
        const SizedBox(width: 8),
        AppStatCard(value: '9', label: 'Проведённых', icon: Icons.history, color: cs.secondary),
      ]),
      const SizedBox(height: 16),

      // Upcoming
      AppSectionHeader(title: 'Предстоящие', icon: Icons.upcoming),
      AppEventCard(
        title: 'Ночная гонка на УТЦ Кавголово',
        subtitle: '22 марта 2026',
        sport: '🐕 Ездовой',
        slotsText: '38 / 50 участников',
        slotsProgress: 38 / 50,
        badge: 'Записаться',
        status: EventCardStatus.upcoming,
        mode: EventCardMode.bento,
        onTap: () {},
      ),
      AppEventCard(
        title: 'Весенний контрольный старт',
        subtitle: '5 апреля 2026',
        sport: '🏔 Трейл',
        slotsText: '22 / 40 участника',
        slotsProgress: 22 / 40,
        badge: '✓ Записан',
        status: EventCardStatus.upcoming,
        accentColor: cs.primary,
        mode: EventCardMode.bento,
        onTap: () {},
      ),
      AppEventCard(
        title: 'Клубная тренировка — скиджоринг',
        subtitle: '12 апреля 2026',
        sport: '🐕 Скиджоринг',
        slotsText: '12 / 20 участников',
        slotsProgress: 12 / 20,
        badge: 'Только для членов',
        status: EventCardStatus.upcoming,
        mode: EventCardMode.bento,
        onTap: () {},
      ),

      const SizedBox(height: 20),

      // Past events
      AppSectionHeader(title: 'Прошедшие', icon: Icons.history),
      AppEventCard(
        title: 'Зимний Кубок «Быстрых лап»',
        subtitle: '15 февраля 2026',
        sport: '🐕 Ездовой',
        slotsText: '42 участника',
        accentColor: cs.outline,
        status: EventCardStatus.completed,
        mode: EventCardMode.bento,
      ),
      AppEventCard(
        title: 'Новогодняя гонка',
        subtitle: '3 января 2026',
        sport: '🐕 Ездовой',
        slotsText: '55 участников',
        accentColor: cs.outline,
        status: EventCardStatus.completed,
        mode: EventCardMode.bento,
      ),
      AppEventCard(
        title: 'Осенний трейл',
        subtitle: '15 октября 2025',
        sport: '🏔 Трейл',
        slotsText: '30 участников',
        accentColor: cs.outline,
        status: EventCardStatus.completed,
        mode: EventCardMode.bento,
      ),
    ]);
  }



  // ═══════════════════════════════════════
  // Tab 3: Клубный рейтинг
  // ═══════════════════════════════════════
  Widget _leaderboardTab(ThemeData theme, ColorScheme cs) {
    const leaderboard = [
      {'rank': '🥇', 'name': 'Иванов Алексей',   'points': '520', 'starts': '12', 'podiums': '8'},
      {'rank': '🥈', 'name': 'Петрова Мария',     'points': '480', 'starts': '11', 'podiums': '6'},
      {'rank': '🥉', 'name': 'Козлов Артём',      'points': '410', 'starts': '10', 'podiums': '5'},
      {'rank': '4',  'name': 'Васильева Наталья', 'points': '350', 'starts': '9',  'podiums': '3'},
      {'rank': '5',  'name': 'Сидоров Дмитрий',   'points': '310', 'starts': '8',  'podiums': '3'},
      {'rank': '6',  'name': 'Волкова Анна',       'points': '280', 'starts': '7',  'podiums': '2'},
      {'rank': '7',  'name': 'Кузнецов Игорь',    'points': '240', 'starts': '7',  'podiums': '1'},
      {'rank': '8',  'name': 'Морозова Ольга',     'points': '200', 'starts': '6',  'podiums': '1'},
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Season selector
      Row(children: [
        Expanded(child: Text('Сезон 2025/2026', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        AppButton.text(
          text: 'Другой сезон',
          icon: Icons.calendar_month,
          onPressed: () {},
        ),
      ]),
      const SizedBox(height: 8),

      // Top-3 podium
      Row(children: [
        Expanded(child: _podiumCard(theme, cs, rank: '🥈', name: 'Петрова\nМария', points: '480', height: 100)),
        const SizedBox(width: 4),
        Expanded(child: _podiumCard(theme, cs, rank: '🥇', name: 'Иванов\nАлексей', points: '520', height: 120, isFirst: true)),
        const SizedBox(width: 4),
        Expanded(child: _podiumCard(theme, cs, rank: '🥉', name: 'Козлов\nАртём', points: '410', height: 88)),
      ]),
      const SizedBox(height: 16),

      // Table header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const SizedBox(width: 28, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(child: Text('Спортсмен', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          SizedBox(width: 50, child: Text('Очки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.primary), textAlign: TextAlign.center)),
          const SizedBox(width: 44, child: Text('Старты', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
          const SizedBox(width: 44, child: Text('Подиум', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
        ]),
      ),
      const SizedBox(height: 4),

      // Rows
      ...leaderboard.map((e) {
        final isTop3 = e['rank']!.startsWith('🥇') || e['rank']!.startsWith('🥈') || e['rank']!.startsWith('🥉');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.2))),
          ),
          child: Row(children: [
            SizedBox(width: 28, child: Text(e['rank']!, style: TextStyle(fontSize: isTop3 ? 18 : 14, fontWeight: FontWeight.bold))),
            Expanded(child: Row(children: [
              AppAvatar(name: e['name']!, size: 28),
              const SizedBox(width: 8),
              Flexible(child: Text(e['name']!, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ])),
            SizedBox(width: 50, child: Text(e['points']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary), textAlign: TextAlign.center)),
            SizedBox(width: 44, child: Text(e['starts']!, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
            SizedBox(width: 44, child: Text(e['podiums']!, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
          ]),
        );
      }),

      const SizedBox(height: 12),
      Center(child: Text('Рейтинг по итогам сезона обновляется после каждого мероприятия', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline), textAlign: TextAlign.center)),
    ]);
  }

  Widget _podiumCard(ThemeData theme, ColorScheme cs, {required String rank, required String name, required String points, required double height, bool isFirst = false}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isFirst ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isFirst ? Border.all(color: cs.primary.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(rank, style: TextStyle(fontSize: isFirst ? 28 : 22)),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text('$points очков', style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Tab 4: Лента клуба
  // ═══════════════════════════════════════
  Widget _feedTab(ThemeData theme, ColorScheme cs) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Pinned announcement
      AppCard(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(color: cs.primary.withOpacity(0.06)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.push_pin, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Закреплено', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
                  const Spacer(),
                  Text('10 марта', style: TextStyle(fontSize: 11, color: cs.outline)),
                ]),
                const SizedBox(height: 8),
                Text('📢 Регистрация на Ночную гонку открыта!', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Приглашаем всех участников клуба на ночную гонку 22 марта на УТЦ Кавголово. Скидка 20% для членов клуба! Регистрация в разделе Мероприятия.', style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // Results post
      _feedPost(
        theme, cs,
        author: 'Иванов Алексей',
        role: 'Владелец',
        date: '8 марта',
        icon: Icons.emoji_events,
        title: '🏆 Результаты Зимнего Кубка!',
        body: 'Поздравляем наших спортсменов с отличными результатами на Зимнем Кубке «Быстрых лап»!\n\n🥇 Иванов Алексей — 1 место, нарты-6\n🥈 Петрова Мария — 2 место, скиджоринг\n🏅 Козлов Артём — 4 место, нарты-4\n\nВсего 12 наших спортсменов приняли участие. Гордимся командой! 💪',
        likes: 24,
        comments: 8,
      ),

      _feedPost(
        theme, cs,
        author: 'Петрова Мария',
        role: 'Тренер',
        date: '5 марта',
        icon: Icons.fitness_center,
        title: '🏋️ Расписание тренировок на март',
        body: 'Уважаемые участники! Обновлённое расписание тренировок:\n\n• Вторник 18:00 — общая физ. подготовка\n• Четверг 17:00 — работа с собаками\n• Суббота 10:00 — контрольная тренировка\n\nМесто: УТЦ Кавголово. Наличие мед. справки обязательно.',
        likes: 15,
        comments: 3,
      ),

      _feedPost(
        theme, cs,
        author: 'Волкова Анна',
        role: 'Администратор',
        date: '1 марта',
        icon: Icons.payment,
        title: '💳 Напоминание об оплате взносов',
        body: 'Коллеги, напоминаю что до 15 марта необходимо оплатить членский взнос на 2026 год. Размер взноса: 3 000₽ (взрослый), 1 500₽ (ребёнок), 5 000₽ (семейный).\n\nОплата доступна в разделе «О клубе» → «Оплатить взнос».',
        likes: 5,
        comments: 12,
      ),

      _feedPost(
        theme, cs,
        author: 'Иванов Алексей',
        role: 'Владелец',
        date: '20 февраля',
        icon: Icons.person_add,
        title: '👋 Добро пожаловать новым участникам!',
        body: 'Рады приветствовать в нашем клубе:\n• Кузнецов Игорь\n• Морозова Ольга\n• Смирнова Анна\n\nЖелаем успешных тренировок и стартов! 🎉',
        likes: 32,
        comments: 6,
      ),
    ]);
  }

  Widget _feedPost(ThemeData theme, ColorScheme cs, {
    required String author, required String role, required String date,
    required IconData icon, required String title, required String body,
    required int likes, required int comments,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Author
            Row(children: [
              AppAvatar(name: author, size: 32),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(role, style: TextStyle(fontSize: 11, color: cs.outline)),
              ])),
              Text(date, style: TextStyle(fontSize: 11, color: cs.outline)),
            ]),
            const SizedBox(height: 10),

            // Content
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),

            // Actions
            Row(children: [
              Icon(Icons.favorite_border, size: 18, color: cs.outline),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(fontSize: 12, color: cs.outline)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 18, color: cs.outline),
              const SizedBox(width: 4),
              Text('$comments', style: TextStyle(fontSize: 12, color: cs.outline)),
              const Spacer(),
              Icon(Icons.bookmark_border, size: 18, color: cs.outline),
            ]),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Membership section (same as before)
  // ═══════════════════════════════════════
  Widget _buildMembershipSection(ColorScheme cs, ThemeData theme) {
    switch (_membershipStatus) {
      case 'pending':
        return Column(children: [
          AppInfoBanner.warning(
            title: 'Заявка на рассмотрении',
            subtitle: 'Администратор клуба рассмотрит вашу заявку. Обычно это занимает 1-2 дня.',
            action: AppButton.text(text: 'Отозвать', onPressed: () => setState(() => _membershipStatus = null)),
          ),
          const SizedBox(height: 16),
        ]);
      case 'approved':
        return Column(children: [
          AppInfoBanner(title: 'Заявка одобрена! 🎉', subtitle: 'Оплатите членский взнос для активации участия.', icon: Icons.check_circle),
          const SizedBox(height: 8),
          AppCard(padding: const EdgeInsets.all(16), children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Членский взнос', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            AppListRow.detail(label: 'Тариф', value: 'Взрослый'),
            AppListRow.detail(label: 'Сумма', value: '3 000 ₽/год'),
            const SizedBox(height: 12),
            AppButton.primary(
              text: 'Оплатить 3 000 ₽',
              icon: Icons.payment,
              onPressed: () { setState(() => _membershipStatus = 'active'); AppSnackBar.success(context, 'Взнос оплачен! 🎉'); },
            ),
          ])]),
          const SizedBox(height: 16),
        ]);
      case 'active':
        return Column(children: [
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.05)),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: cs.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Активный участник', style: theme.textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                      Text('Взнос оплачен до 31.12.2026', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ])),
                    const StatusBadge(text: '✅ Актив', type: BadgeType.success),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ]);
      default:
        return Column(children: [
          AppCard(padding: const EdgeInsets.all(16), children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant), const SizedBox(width: 8), Text('Вступление в клуб', style: theme.textTheme.titleSmall)]),
            const SizedBox(height: 8),
            Text('Членский взнос: 3 000 ₽/год', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Заявка → Одобрение → Оплата → Участие', style: TextStyle(fontSize: 12, color: cs.outline)),
            const SizedBox(height: 12),
            AppButton.primary(
              text: 'Подать заявку',
              icon: Icons.person_add,
              onPressed: () => _showApplyDialog(context),
            ),
          ])]),
          const SizedBox(height: 16),
        ]);
    }
  }

  void _showApplyDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(context, title: 'Заявка в клуб', actions: [
      AppButton.primary(
        text: 'Отправить заявку',
        icon: Icons.send,
        onPressed: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _membershipStatus = 'pending'); AppSnackBar.success(context, 'Заявка отправлена! ✉️'); },
      ),
    ], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const AppAvatar(name: '🐕', size: 48), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Быстрые лапы', style: Theme.of(context).textTheme.titleMedium),
          Text('Санкт-Петербург', style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
      const SizedBox(height: 16),
      AppCard(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                AppListRow.detail(label: 'Членский взнос', value: '3 000 ₽/год'),
                AppListRow.detail(label: 'Тариф «Ребёнок»', value: '1 500 ₽/год'),
                AppListRow.detail(label: 'Тариф «Семейный»', value: '5 000 ₽/год'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AppInfoBanner(title: 'Как это работает', subtitle: '1. Вы отправляете заявку\n2. Администратор одобряет\n3. Вы оплачиваете взнос\n4. Готово — вы участник!', icon: Icons.route),
      const SizedBox(height: 16),
      const AppTextField(label: 'Сообщение', hintText: 'Расскажите о себе...', maxLines: 3),
    ]));
  }
}

// ═══════════════════════════════════════
// SliverPersistentHeader delegate for PillTabBar
// ═══════════════════════════════════════
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final AppPillTabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

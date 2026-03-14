import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/app_club_card.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: C1 — Клубы (хаб-экран, корень вкладки)
/// Telegram-стиль: два подтаба «Мои клубы» и «Все клубы».
class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _sportFilter = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _myClubs = [
    {'name': 'Быстрые лапы', 'city': 'Санкт-Петербург', 'sport': '🐕 Ездовой', 'role': 'Владелец', 'type': 'warning', 'members': '45', 'id': 'club-1', 'pending': '3', 'logoUrl': 'assets/images/club1.jpeg'},
    {'name': 'Trail Runners SPb', 'city': 'Санкт-Петербург', 'sport': '🏔 Трейл', 'role': 'Участник', 'type': 'neutral', 'members': '120', 'id': 'club-2', 'pending': '0', 'logoUrl': 'assets/images/club2.jpeg'},
    {'name': 'Ski Club North', 'city': 'Мурманск', 'sport': '🎿 Лыжи', 'role': '⏳ Заявка', 'type': 'info', 'members': '67', 'id': 'club-3', 'pending': '0', 'logoUrl': 'assets/images/club3.jpeg'},
  ];

  final List<Map<String, dynamic>> _otherClubs = [
    {'name': 'Быстрые лапы', 'city': 'Санкт-Петербург', 'sport': 'sled', 'sportLabel': '🐕 Ездовой', 'members': '45', 'fee': '3 000 ₽/год', 'id': 'club-1', 'logoUrl': 'assets/images/club1.jpeg'},
    {'name': 'Trail Runners SPb', 'city': 'Санкт-Петербург', 'sport': 'trail', 'sportLabel': '🏔 Трейл', 'members': '120', 'fee': 'Бесплатно', 'id': 'club-2', 'logoUrl': 'assets/images/club2.jpeg'},
    {'name': 'Ski Club North', 'city': 'Мурманск', 'sport': 'ski', 'sportLabel': '🎿 Лыжи', 'members': '67', 'fee': '2 500 ₽/год', 'id': 'club-3', 'logoUrl': 'assets/images/club3.jpeg'},
    {'name': 'Хаски Карелия', 'city': 'Петрозаводск', 'sport': 'sled', 'sportLabel': '🐕 Ездовой', 'members': '32', 'fee': '1 500 ₽/год', 'id': 'club-4', 'logoUrl': 'assets/images/club4.jpeg'},
    {'name': 'Беговой клуб «Заяц»', 'city': 'Москва', 'sport': 'running', 'sportLabel': '🏃 Бег', 'members': '210', 'fee': 'Бесплатно', 'id': 'club-5', 'logoUrl': 'assets/images/club5.jpeg'},
    {'name': 'Tri Force', 'city': 'Казань', 'sport': 'triathlon', 'sportLabel': '🏊 Триатлон', 'members': '55', 'fee': '5 000 ₽/год', 'id': 'club-6', 'logoUrl': 'assets/images/club2.jpeg'},
    {'name': 'CanixPro', 'city': 'Новосибирск', 'sport': 'sled', 'sportLabel': '🐕 Каникросс', 'members': '28', 'fee': '2 000 ₽/год', 'id': 'club-7', 'logoUrl': 'assets/images/club3.jpeg'},
    {'name': 'Водник', 'city': 'Самара', 'sport': 'swimming', 'sportLabel': '🏊 Плавание', 'members': '90', 'fee': '4 000 ₽/год', 'id': 'club-8', 'logoUrl': 'assets/images/club4.jpeg'},
  ];

  static const _sportFilters = <String, String>{
    'all': '⚡ Все',
    'sled': '🐕 Ездовой',
    'trail': '🏔 Трейл',
    'running': '🏃 Бег',
    'ski': '🎿 Лыжи',
    'cycling': '🚴 Вело',
    'triathlon': '🏊 Триатлон',
    'swimming': '🏊 Плавание',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Клубы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Поиск клубов',
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Создать клуб',
            onPressed: () => context.push('/clubs/create'),
          ),
        ],
        bottom: AppPillTabBar(
          controller: _tabController,
          tabs: const ['Мои клубы', 'Все клубы'],
          icons: const [Icons.star_rounded, Icons.explore],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _myClubsTab(theme, cs),
          _allClubsTab(theme, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Tab 1: Мои клубы
  // ═══════════════════════════════════════
  Widget _myClubsTab(ThemeData theme, ColorScheme cs) {
    if (_myClubs.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.groups_outlined, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        Text('Вы пока не состоите в клубах', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Перейдите на вкладку «Все клубы» чтобы найти клуб', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => _tabController.animateTo(1), icon: const Icon(Icons.explore), label: const Text('Найти клуб')),
      ]));
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Summary
      Row(children: [
        AppStatCard(value: '${_myClubs.length}', label: 'Клубов', icon: Icons.groups),
        const SizedBox(width: 8),
        AppStatCard(value: '1', label: 'Владелец', icon: Icons.admin_panel_settings, color: cs.tertiary),
        const SizedBox(width: 8),
        AppStatCard(value: '3', label: 'Заявки', icon: Icons.mail, color: cs.error),
      ]),
      const SizedBox(height: 16),

      // Club list
      ..._myClubs.map((club) {
        final badgeType = switch (club['type']) {
          'warning' => BadgeType.warning,
          'success' => BadgeType.success,
          'info' => BadgeType.info,
          _ => BadgeType.neutral,
        };

        final hasPending = (int.tryParse(club['pending'] ?? '0') ?? 0) > 0;

        return AppClubCard(
          title: club['name']!,
          location: club['city']!,
          sport: club['sport']!,
          members: club['members']!,
          role: club['role'],
          pendingLabel: hasPending ? club['pending'] : null,
          logoUrl: club['logoUrl'],
          roleBadgeType: badgeType,
          onTap: () => context.push('/clubs/${club['id']}'),
          mode: ClubCardMode.bento,
          heroTag: 'club-avatar-${club['id']}',
        );
      }),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 2: Все клубы (каталог)
  // ═══════════════════════════════════════
  Widget _allClubsTab(ThemeData theme, ColorScheme cs) {
    final filtered = _otherClubs.where((c) {
      final matchSport = _sportFilter == 'all' || c['sport'] == _sportFilter;
      final matchSearch = _searchQuery.isEmpty || (c['name']!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchSport && matchSearch;
    }).toList();

    return Column(children: [
      // Sport filter chips
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          children: _sportFilters.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              selected: _sportFilter == e.key,
              onSelected: (_) => setState(() => _sportFilter = _sportFilter == e.key ? 'all' : e.key),
              visualDensity: VisualDensity.compact,
            ),
          )).toList(),
        ),
      ),

      // Results count
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('Найдено ${filtered.length} клубов', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.sort, size: 16),
            label: const Text('По участникам', style: TextStyle(fontSize: 12)),
            onPressed: () {},
          ),
        ]),
      ),

      // Club list
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off, size: 48, color: cs.outlineVariant),
                const SizedBox(height: 8),
                Text('Клубы не найдены', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final club = filtered[i];
                  final isMember = _myClubs.any((c) => c['id'] == club['id']);
                  final isFree = club['fee'] == 'Бесплатно';

                  return AppClubCard(
                    title: club['name']!,
                    location: club['city']!,
                    sport: club['sportLabel']!,
                    members: club['members']!,
                    role: isMember ? 'Участник' : null,
                    roleBadgeType: isMember ? BadgeType.success : null,
                    fee: isFree ? 'Бесплатно' : club['fee'],
                    logoUrl: club['logoUrl'],
                    onTap: () => context.push('/clubs/${club['id']}'),
                    mode: ClubCardMode.bento,
                    heroTag: 'club-avatar-${club['id']}',
                  );
                },
              ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Search modal
  // ═══════════════════════════════════════
  void _showSearch(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Поиск клубов',
      child: Column(children: [
        AppTextField(
          label: 'Название клуба',
          prefixIcon: Icons.search,
          hintText: 'Быстрые лапы...',
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 12),
        Text('Или перейдите на вкладку «Все клубы» для фильтрации по спорту',
          style: TextStyle(fontSize: 12, color: cs.outline),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

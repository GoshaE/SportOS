import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/clubs/${club['id']}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Hero(
                  tag: 'club-avatar-${club['id']}',
                  child: AppAvatar(name: club['name']!, size: 48, imageUrl: club['logoUrl']),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(club['name']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on, size: 12, color: cs.outline),
                    const SizedBox(width: 2),
                    Flexible(child: Text(club['city']!, style: TextStyle(fontSize: 12, color: cs.outline), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(club['sport']!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 2),
                  Text('${club['members']} участников', style: TextStyle(fontSize: 11, color: cs.outline)),
                ])),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  StatusBadge(text: club['role']!, type: badgeType),
                  if (hasPending) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(8)),
                      child: Text('${club['pending']} 📩', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: cs.outlineVariant, size: 20),
              ]),
            ),
          ),
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/clubs/${club['id']}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Hero(
                            tag: 'club-avatar-${club['id']}',
                            child: AppAvatar(name: club['name']!, size: 48, imageUrl: club['logoUrl']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(club['name']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              if (isMember) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 14, color: cs.primary),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.location_on, size: 12, color: cs.outline),
                              const SizedBox(width: 2),
                              Flexible(child: Text(club['city']!, style: TextStyle(fontSize: 12, color: cs.outline), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Flexible(child: Text(club['sportLabel']!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.people, size: 12, color: cs.outline),
                              const SizedBox(width: 3),
                              Text('${club['members']} участников', style: TextStyle(fontSize: 11, color: cs.outline)),
                              const SizedBox(width: 8),
                              Icon(isFree ? Icons.money_off : Icons.attach_money, size: 12, color: isFree ? cs.secondary : cs.outline),
                              const SizedBox(width: 3),
                              Flexible(child: Text(club['fee']!, style: TextStyle(fontSize: 11, color: isFree ? cs.secondary : cs.outline, fontWeight: isFree ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                            ]),
                          ])),
                          if (isMember)
                            const StatusBadge(text: '✓ Состою', type: BadgeType.success)
                          else
                            Icon(Icons.chevron_right, color: cs.outlineVariant, size: 20),
                        ]),
                      ),
                    ),
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

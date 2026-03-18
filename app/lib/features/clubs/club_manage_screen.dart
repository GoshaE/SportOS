import 'package:flutter/material.dart';
import 'package:sportos_app/ui/molecules/app_list_row.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: C3 — Управление клубом (адм. панель)
class ClubManageScreen extends StatefulWidget {
  const ClubManageScreen({super.key});

  @override
  State<ClubManageScreen> createState() => _ClubManageScreenState();
}

class _ClubManageScreenState extends State<ClubManageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 5, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final clubId = GoRouterState.of(context).pathParameters['clubId'] ?? 'club-1';

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Управление: Быстрые лапы'),
        bottom: AppPillTabBar(
          controller: _tabs,
          tabs: const ['Участники', 'Взносы', 'Заявки', 'Объявления', 'Настройки'],
          icons: const [Icons.people, Icons.attach_money, Icons.how_to_reg, Icons.campaign, Icons.settings],
          isScrollable: true,
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _membersTab(), _feesTab(), _applicationsTab(), _announcementsTab(), _settingsTab(clubId),
      ]),
    );
  }

  // ── Вкладка: Участники ──
  Widget _membersTab() {
    final members = [
      {'name': 'Иванов Алексей', 'role': 'owner', 'roleLabel': 'Владелец', 'fee': 'paid', 'since': '2020', 'imageUrl': 'assets/images/avatar1.jpeg'},
      {'name': 'Петрова Мария', 'role': 'coach', 'roleLabel': 'Тренер', 'fee': 'paid', 'since': '2021', 'imageUrl': 'assets/images/avatar2.jpg'},
      {'name': 'Сидоров Дмитрий', 'role': 'coach', 'roleLabel': 'Тренер', 'fee': 'paid', 'since': '2022', 'imageUrl': 'assets/images/avatar3.jpeg'},
      {'name': 'Козлов Артём', 'role': 'member', 'roleLabel': 'Участник', 'fee': 'paid', 'since': '2023', 'imageUrl': 'assets/images/avatar4.jpeg'},
      {'name': 'Васильева Наталья', 'role': 'member', 'roleLabel': 'Участник', 'fee': 'overdue', 'since': '2023', 'imageUrl': 'assets/images/avatar5.jpeg'},
      {'name': 'Орлов Павел', 'role': 'member', 'roleLabel': 'Участник', 'fee': 'paid', 'since': '2024', 'imageUrl': 'assets/images/avatar6.png'},
      {'name': 'Новикова Елена', 'role': 'member', 'roleLabel': 'Участник', 'fee': 'pending', 'since': '2025', 'imageUrl': 'assets/images/avatar8.jpg'},
    ];

    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        AppStatCard(value: '${members.length}', label: 'Всего', color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        AppStatCard(value: '2', label: 'Тренеры', color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(width: 4),
        AppStatCard(value: '5', label: 'Оплачено', color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        AppStatCard(value: '2', label: 'Долг', color: Theme.of(context).colorScheme.error),
      ]),
      const SizedBox(height: 8),
      ...members.map((m) {
        final feeLabel = switch (m['fee']) { 'paid' => '✅', 'overdue' => '❌ Долг', _ => '⏳' };
        final feeColor = switch (m['fee']) { 'paid' => Theme.of(context).colorScheme.primary, 'overdue' => Theme.of(context).colorScheme.error, _ => Theme.of(context).colorScheme.tertiary };
        return AppUserTile(
          name: m['name'] as String,
          subtitle: '${m['roleLabel']} · с ${m['since']}',
          leading: AppAvatar(name: m['name'] as String, imageUrl: m['imageUrl'], size: 40),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(feeLabel, style: TextStyle(fontSize: 12, color: feeColor)),
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'owner', child: Text('👑 Владелец')),
                const PopupMenuItem(value: 'admin', child: Text('🛡 Администратор')),
                const PopupMenuItem(value: 'coach', child: Text('🏋️ Тренер')),
                const PopupMenuItem(value: 'secretary', child: Text('📋 Секретарь')),
                const PopupMenuItem(value: 'member', child: Text('👤 Участник')),
                const PopupMenuItem(value: 'divider', enabled: false, child: Divider()),
                PopupMenuItem(value: 'remove', child: Text('❌ Исключить', style: TextStyle(color: Theme.of(context).colorScheme.error))),
              ],
              onSelected: (v) {
                if (v == 'remove') {
                  AppSnackBar.info(context, '${m['name']} исключён из клуба');
                } else if (v != 'divider') {
                  final roleNames = {'owner': 'Владелец', 'admin': 'Администратор', 'coach': 'Тренер', 'secretary': 'Секретарь', 'member': 'Участник'};
                  AppSnackBar.success(context, '${m['name']}: роль изменена на ${roleNames[v]}');
                }
              },
            ),
          ]),
        );
      }),
      const SizedBox(height: 12),
      AppButton.secondary(text: 'Пригласить', icon: Icons.person_add, onPressed: () {}),
    ]);
  }

  // ── Вкладка: Взносы ──
  Widget _feesTab() {
    final theme = Theme.of(context);

    return ListView(padding: const EdgeInsets.all(16), children: [
      AppCard(padding: const EdgeInsets.all(16), children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Членские взносы', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          AppListRow.detail(label: 'Взрослый', value: '3 000 ₽/год'),
          AppListRow.detail(label: 'Ребёнок (до 14)', value: '1 500 ₽/год'),
          AppListRow.detail(label: 'Семейный', value: '5 000 ₽/год'),
          const Divider(),
          Row(children: [
            Text('Общий сбор 2026:', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('127 500 ₽', style: theme.textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ]),
        ]),
      ]),
      const SizedBox(height: 12),

      AppSectionHeader(title: 'История оплат', icon: Icons.receipt_long),
      ...[
        {'who': 'Орлов Павел', 'date': '10.02.2026', 'sum': '3 000 ₽', 'type': 'Взрослый'},
        {'who': 'Козлов Артём', 'date': '05.01.2026', 'sum': '3 000 ₽', 'type': 'Взрослый'},
        {'who': 'Петрова Мария', 'date': '12.12.2025', 'sum': '5 000 ₽', 'type': 'Семейный'},
      ].map((p) => AppListRow.status(
        icon: Icons.check_circle,
        title: p['who']!,
        subtitle: '${p['date']} · ${p['type']}',
        trailing: Text(p['sum']!, style: theme.textTheme.titleSmall),
      )),
      const SizedBox(height: 12),
      AppButton.primary(text: 'Отметить оплату', icon: Icons.add, onPressed: () {}),
    ]);
  }

  // ── Вкладка: Заявки ──
  Widget _applicationsTab() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Stats
      Row(children: [
        AppStatCard(value: '3', label: 'Новых', color: cs.primary),
        const SizedBox(width: 4),
        AppStatCard(value: '1', label: 'Одобрено', color: cs.secondary),
        const SizedBox(width: 4),
        AppStatCard(value: '2', label: 'Ожидают оплату', color: cs.tertiary),
      ]),
      const SizedBox(height: 12),

      AppInfoBanner(
        title: 'Процесс вступления',
        subtitle: 'Заявка → Одобрение → Оплата взноса → Активный участник',
        icon: Icons.route,
      ),
      const SizedBox(height: 16),

      // ── New applications ──
      AppSectionHeader(title: 'Новые заявки', icon: Icons.fiber_new),
      _applicationCard(
        theme, cs,
        name: 'Кузнецов Игорь',
        date: '8 марта 2026',
        message: 'Занимаюсь ездовым спортом 3 года, есть 2 хаски.',
      ),
      _applicationCard(
        theme, cs,
        name: 'Смирнова Анна',
        date: '10 марта 2026',
        message: 'Хочу тренироваться с вашим клубом, есть маламут.',
      ),

      const SizedBox(height: 16),
      // ── Awaiting payment ──
      AppSectionHeader(title: 'Ожидают оплату', icon: Icons.hourglass_top),
      AppUserTile(
        name: 'Волков Денис',
        subtitle: 'Одобрен 5 марта · Ожидает оплату 3 000 ₽',
        leading: const AppAvatar(name: 'Волков Денис', imageUrl: 'assets/images/avatar3.jpeg', size: 40),
        badge: const StatusBadge(text: '⭐ Оплата', type: BadgeType.info),
        trailing: IconButton(
          icon: Icon(Icons.check_circle, color: cs.secondary),
          tooltip: 'Подтвердить оплату',
          onPressed: () => AppSnackBar.success(context, 'Оплата подтверждена, Волков Денис теперь участник!'),
        ),
      ),
      AppUserTile(
        name: 'Морозова Ольга',
        subtitle: 'Одобрена 2 марта · Семейный тариф 5 000 ₽',
        leading: const AppAvatar(name: 'Морозова Ольга', imageUrl: 'assets/images/avatar5.jpeg', size: 40),
        badge: const StatusBadge(text: '⭐ Оплата', type: BadgeType.info),
        trailing: IconButton(
          icon: Icon(Icons.check_circle, color: cs.secondary),
          tooltip: 'Подтвердить оплату',
          onPressed: () => AppSnackBar.success(context, 'Оплата подтверждена, Морозова Ольга теперь участница!'),
        ),
      ),
    ]);
  }

  Widget _applicationCard(ThemeData theme, ColorScheme cs, {required String name, required String date, required String message}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppUserTile(
            name: name,
            subtitle: 'Подана $date',
            leading: AppAvatar(name: name, imageUrl: 'assets/images/avatar1.jpeg', size: 40),
            badge: const StatusBadge(text: 'Новая', type: BadgeType.warning),
            contentPadding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppButton.secondary(text: 'Отклонить', icon: Icons.close, onPressed: () {})),
            const SizedBox(width: 8),
            Expanded(child: AppButton.primary(text: 'Одобрить', icon: Icons.check, onPressed: () {
              AppSnackBar.success(context, '$name одобрен! Ожидаем оплату взноса.');
            })),
          ]),
        ]),
      ),
    );
  }

  // ── Вкладка: Объявления ──
  Widget _announcementsTab() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Create announcement
      Card(
        color: cs.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.campaign, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text('Новое объявление', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const AppTextField(label: 'Заголовок', hintText: 'Название объявления'),
            const SizedBox(height: 8),
            const AppTextField(label: 'Текст', hintText: 'Напишите объявление для участников клуба...', maxLines: 4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(label: const Text('📌 Закрепить'), selected: false, onSelected: (_) {}),
                    FilterChip(label: const Text('🔔 Push всем'), selected: true, onSelected: (_) {}),
                  ],
                ),
                AppButton.primary(
                  text: 'Отправить',
                  icon: Icons.send,
                  onPressed: () => AppSnackBar.success(context, 'Объявление опубликовано! 📢'),
                ),
              ],
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // Stats
      Row(children: [
        AppStatCard(value: '12', label: 'Объявлений', icon: Icons.campaign, color: cs.primary),
        const SizedBox(width: 8),
        AppStatCard(value: '89%', label: 'Прочитано', icon: Icons.visibility, color: cs.secondary),
      ]),
      const SizedBox(height: 16),

      // Past announcements
      AppSectionHeader(title: 'Опубликованные', icon: Icons.history),
      _announcementRow(theme, cs, title: '📢 Регистрация на Ночную гонку', date: '10 марта', reads: '42/45', pinned: true),
      _announcementRow(theme, cs, title: '🏋️ Расписание тренировок на март', date: '5 марта', reads: '40/45', pinned: false),
      _announcementRow(theme, cs, title: '💳 Напоминание об оплате взносов', date: '1 марта', reads: '38/45', pinned: false),
      _announcementRow(theme, cs, title: '👋 Добро пожаловать новым участникам!', date: '20 февр.', reads: '45/45', pinned: false),
    ]);
  }

  Widget _announcementRow(ThemeData theme, ColorScheme cs, {required String title, required String date, required String reads, required bool pinned}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(pinned ? Icons.push_pin : Icons.article, size: 20, color: pinned ? cs.primary : cs.outline),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text('$date · Прочитано $reads', style: TextStyle(fontSize: 11, color: cs.outline)),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'pin', child: Text('📌 Закрепить/Открепить')),
            const PopupMenuItem(value: 'edit', child: Text('✏️ Редактировать')),
            PopupMenuItem(value: 'delete', child: Text('🗑 Удалить', style: TextStyle(color: cs.error))),
          ],
          onSelected: (v) {},
        ),
      ),
    );
  }

  // ── Вкладка: Настройки ──
  Widget _settingsTab(String clubId) {
    final theme = Theme.of(context);

    return ListView(padding: const EdgeInsets.all(16), children: [
      const AppTextField(label: 'Название клуба', prefixIcon: Icons.badge),
      const SizedBox(height: 12),
      const AppTextField(label: 'Город', prefixIcon: Icons.location_city),
      const SizedBox(height: 12),
      const AppTextField(label: 'Описание', prefixIcon: Icons.description, maxLines: 3),
      const SizedBox(height: 12),
      const AppTextField(label: 'Telegram', prefixIcon: Icons.telegram),
      const SizedBox(height: 12),
      const AppTextField(label: 'VK', prefixIcon: Icons.language),
      const SizedBox(height: 12),
      const AppTextField(label: 'Email', prefixIcon: Icons.email),
      const SizedBox(height: 16),
      AppButton.primary(text: 'Сохранить', onPressed: () => AppSnackBar.success(context, 'Настройки сохранены')),

      const SizedBox(height: 32),
      // Danger zone
      AppSectionHeader(title: 'Опасная зона', icon: Icons.warning_amber),
      AppButton.secondary(
        text: 'Передать владение',
        icon: Icons.swap_horiz,
        onPressed: () {},
      ),
      const SizedBox(height: 8),
      Center(child: AppButton.text(
        text: 'Удалить клуб',
        onPressed: () {},
      )),
    ]);
  }
}

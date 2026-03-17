import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E1 — Обзор мероприятия (Организатор Dashboard)
class EventOverviewScreen extends StatelessWidget {
  const EventOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest, // Lighter background for dashboard feel
        appBar: AppAppBar(
          forceBackButton: true,
          onBackButtonPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my');
            }
          },
          title: const Text('Чемпионат Урала 2026'),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          ],
          bottom: AppPillTabBar(
            isScrollable: true,
            tabs: const ['Обзор', 'Настройки', 'Ресурсы'],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(context, cs, isDark, eventId, theme),
            _buildSetupTab(context, cs, isDark, eventId, theme),
            _buildManagementTab(context, cs, isDark, eventId, theme),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ТАБ 1: Обзор (Dashboard)
  // ===========================================================================
  Widget _buildDashboardTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Bento KPI Grid (Top)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Main KPI (Participants)
            Expanded(
              flex: 3,
              child: _buildGlassCard(
                cs: cs,
                isDark: isDark,
                height: 140,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primaryContainer.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups, color: cs.onPrimary.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Регистрация открыта',
                            style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('48 / 60', style: TextStyle(color: cs.onPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        ),
                        Text('Участников (12 мест)', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.8), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right: Smaller KPIs
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildGlassCard(
                    cs: cs,
                    isDark: isDark,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('5 дней', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('До старта', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    cs: cs,
                    isDark: isDark,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('157.5К', style: TextStyle(color: cs.tertiary, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Собрано ₽', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Quick Actions Carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickAction(context, Icons.qr_code_scanner, 'Чек-ин\nQR', () => context.push('/manage/$eventId/checkin'), cs),
              _buildQuickAction(context, Icons.campaign, 'Отправить\nPush', () => _showAnnouncementsModal(context, cs), cs),
              // Участники и Финансы переехали в "Ресурсы", но для скорости можно оставить их и тут (или убрать и сделать быстрый линк)
              _buildQuickAction(context, Icons.people, 'Участники', () => context.push('/manage/$eventId/participants'), cs),
              // _buildQuickAction(context, Icons.settings, 'Настройки', () => DefaultTabController.of(context).animateTo(1), cs),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 4. Preparation Checklist
        Text('Подготовка перед стартом', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 12),
        _buildGlassCard(
          cs: cs,
          isDark: isDark,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildChecklistItem(cs, 'Жеребьёвка', 'Утверждена', true, () => context.push('/manage/$eventId/draw')),
              _buildChecklistItem(cs, 'Стартовый лист', 'Опубликован', true, () => context.push('/manage/$eventId/startlist')),
              _buildChecklistItem(cs, 'BIB номера', '7 из 8 назначено', false, () => context.push('/manage/$eventId/bibs')),
              _buildChecklistItem(cs, 'Ветконтроль', '35 из 48 прошли', false, () => context.push('/manage/$eventId/vetcheck')),
              _buildChecklistItem(cs, 'Мандатная комиссия', '30 допущено', false, () => context.push('/manage/$eventId/mandate')),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  // ===========================================================================
  // ТАБ 2: Настройки (Setup)
  // ===========================================================================
  Widget _buildSetupTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Быстрые конфигурации (были на старом Overview)
        Text('Регламент гонки', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 12),
        AppMenuGroup(title: 'Классы и расписание', items: [
          AppMenuItem(icon: Icons.sports, label: 'Дисциплины и классы', badge: '6', color: cs.primary, onTap: () => context.push('/manage/$eventId/disciplines')),
          AppMenuItem(icon: Icons.calendar_month, label: 'Многодневная гонка', badge: 'Выкл', color: cs.tertiary, onTap: () => context.push('/manage/$eventId/multiday')),
        ]),
        const SizedBox(height: 24),

        // 2. Общие (из EventSettingsScreen)
        _sectionTitle(theme, 'Публичность', Icons.tune),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                AppSettingsTile.toggle(title: 'Регистрация открыта', value: true, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Публичный стартовый лист', value: true, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Публичные результаты', value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Категории
        _sectionTitle(theme, 'Категории', Icons.category),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            AppSettingsTile.nav(
              title: 'Настройка категорий',
              subtitle: 'Возраст, вес, пол (24 активных)',
              trailing: Icons.settings,
              onTap: () => _showCategoriesConstructor(context, cs),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Лимиты и правила участия
        _sectionTitle(theme, 'Правила участия', Icons.groups),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                AppSettingsTile.nav(title: 'Макс. участников', subtitle: '60'),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.nav(title: 'Waitlist', subtitle: 'Включен (макс. 20)'),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Возврат оплаты', subtitle: 'До 48ч до старта', value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 5. Ветконтроль
        _sectionTitle(theme, 'Ветеринарный контроль', Icons.pets),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                AppSettingsTile.toggle(title: 'Обязательный ветконтроль', value: true, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.nav(title: 'Grace-period вакцинации', subtitle: '30 дней'),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Замена собаки разрешена', value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 6. Хронометраж и Безопасность
        _sectionTitle(theme, 'Система судейства', Icons.timer),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                AppSettingsTile.nav(title: 'Точность отсечки', subtitle: 'Миллисекунды (0.001)'),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.nav(title: 'Формат времени', subtitle: 'HH:mm:ss.S'),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Двойной хронометраж', subtitle: 'Мастер + Контрольный', value: true, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'GPS трекинг', value: false, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Аудит лог', value: true, onChanged: (_) {}),
                const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(title: 'Двойное подтверждение DNF', value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  // ===========================================================================
  // ТАБ 3: Ресурсы (Management)
  // ===========================================================================
  Widget _buildManagementTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        AppMenuGroup(title: 'Организация', items: [
          AppMenuItem(icon: Icons.payments, label: 'Финансы и сборы', badge: '157.5К', color: cs.primary, onTap: () => context.push('/manage/$eventId/finances')),
          AppMenuItem(icon: Icons.people, label: 'Участники', badge: '48 чел', color: cs.secondary, onTap: () => context.push('/manage/$eventId/participants')),
          AppMenuItem(icon: Icons.badge, label: 'Команда организаторов', badge: '5 чел', color: cs.secondary, onTap: () => context.push('/manage/$eventId/team')),
          AppMenuItem(icon: Icons.description, label: 'Документы и положения', badge: '4', color: cs.onSurfaceVariant, onTap: () => context.push('/manage/$eventId/documents')),
        ]),
        const SizedBox(height: 24),

        // Post-race: Results & Ceremonies (Highlighted)
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary.withValues(alpha: 0.3), cs.secondary.withValues(alpha: 0.3)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: _buildGlassCard(
            cs: cs,
            isDark: isDark,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppMenuGroup(title: 'Итоги и награждение', items: [
                  AppMenuItem(icon: Icons.leaderboard, label: 'Live результаты и сплиты', color: cs.primary, onTap: () => context.push('/results/$eventId/live')),
                  AppMenuItem(icon: Icons.article, label: 'Официальные протоколы', color: cs.secondary, onTap: () => context.push('/results/$eventId/protocol')),
                  AppMenuItem(icon: Icons.gavel, label: 'Протесты и апелляции', badge: '0', color: cs.tertiary, onTap: () => context.push('/results/$eventId/protests')),
                  AppMenuItem(icon: Icons.workspace_premium, label: 'Генерация дипломов', color: cs.primary, onTap: () => context.push('/results/$eventId/diplomas')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  // ===========================================================================
  // Вспомогательные виджеты
  // ===========================================================================

  Widget _buildGlassCard({
    required ColorScheme cs,
    required bool isDark,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadiusGeometry? borderRadius,
    Gradient? gradient,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null ? null : (isDark ? cs.surfaceContainerHigh.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9)),
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: gradient != null ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.1) : cs.outlineVariant.withValues(alpha: 0.3)),
          width: 1,
        ),
        boxShadow: gradient != null ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ColorScheme cs, String title, String subtitle, bool isDone, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? cs.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isDone ? cs.primary : cs.outlineVariant),
              ),
              child: isDone ? Icon(Icons.check, size: 16, color: cs.onPrimary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, decoration: isDone ? TextDecoration.lineThrough : null)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementsModal(BuildContext context, ColorScheme cs) {
    AppBottomSheet.show(
      context,
      title: 'Push-уведомления',
      initialHeight: 0.85,
      actions: [
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Уведомление отправлено');
          },
          icon: const Icon(Icons.send),
          label: const Text('Отправить Push-уведомление'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        )),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Массовая рассылка важных сообщений', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        const Text('Получатели', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilterChip(label: const Text('Все участники (48)'), selected: true, onSelected: (_) {}),
          FilterChip(label: const Text('Судьи и волонтёры (5)'), selected: false, onSelected: (_) {}),
          FilterChip(label: const Text('Скиджоринг 5км (21)'), selected: false, onSelected: (_) {}),
        ]),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder(), hintText: 'Важное изменение в расписании')),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Текст сообщения', border: OutlineInputBorder(), hintText: 'Старт дистанции 5км переносится на 10:30...'), maxLines: 4),
      ]),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  void _showCategoriesConstructor(BuildContext context, ColorScheme cs) {
    final List<Map<String, dynamic>> categories = [
      {'gender': 'Мужчины', 'minAge': '18', 'maxAge': '34', 'weight': 'Любой', 'name': 'M 18-34'},
      {'gender': 'Женщины', 'minAge': '18', 'maxAge': '34', 'weight': 'Любой', 'name': 'Ж 18-34'},
      {'gender': 'Мужчины', 'minAge': '35', 'maxAge': '99', 'weight': 'Любой', 'name': 'M 35+'},
      {'gender': 'Женщины', 'minAge': '35', 'maxAge': '99', 'weight': 'Любой', 'name': 'Ж 35+'},
    ];

    AppBottomSheet.show(context, title: 'Конструктор категорий', initialHeight: 0.8, actions: [
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Сохранить категории'))),
    ], child: StatefulBuilder(builder: (ctx, setModal) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Настройте возрастные и весовые группы. Система автоматически распределит участников.', style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
      Row(children: [
        const Text('Категории (Скиджоринг)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        FilledButton.icon(
          onPressed: () => setModal(() => categories.add({'gender': 'Мужчины', 'minAge': '18', 'maxAge': '99', 'weight': 'Любой', 'name': 'Новая'})),
          icon: const Icon(Icons.add, size: 16), label: const Text('Добавить'),
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ]),
      const SizedBox(height: 8),
      ...categories.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [
              Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              IconButton(icon: Icon(Icons.delete, color: cs.error, size: 20), onPressed: () => setModal(() => categories.removeAt(i)), visualDensity: VisualDensity.compact),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(flex: 2, child: DropdownButtonFormField<String>(
                initialValue: c['gender'],
                decoration: const InputDecoration(labelText: 'Пол', border: OutlineInputBorder(), isDense: true),
                items: ['Мужчины', 'Женщины', 'Смешанная', 'Любой'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setModal(() => c['gender'] = v!),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: c['minAge'], decoration: const InputDecoration(labelText: 'От (лет)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) => c['minAge'] = v)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: c['maxAge'], decoration: const InputDecoration(labelText: 'До', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) => c['maxAge'] = v)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextFormField(initialValue: c['weight'], decoration: const InputDecoration(labelText: 'Вес / Класс', border: OutlineInputBorder(), isDense: true), onChanged: (v) => c['weight'] = v)),
            ]),
          ])),
        );
      }),
    ])));
  }
}

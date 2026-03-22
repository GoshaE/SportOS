import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E4 — Команда / Роли (3 таба)
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isTableView = false;
  bool _initialized = false;

  static const _roleRegistry = [
    {
      'id': 'organizer',
      'label': 'Организатор',
      'icon': '👑',
      'color': 0xFFFF9800,
      'screens': 'Все',
    },
    {
      'id': 'head_judge',
      'label': 'Главный судья',
      'icon': '⚖️',
      'color': 0xFF9C27B0,
      'screens': 'Протесты, Протокол, Штрафы',
    },
    {
      'id': 'secretary',
      'label': 'Секретарь',
      'icon': '📝',
      'color': 0xFF2196F3,
      'screens': 'Регистрация, Старт. лист, Протокол, Финансы',
    },
    {
      'id': 'starter',
      'label': 'Стартёр',
      'icon': '⏱',
      'color': 0xFF4CAF50,
      'screens': 'Стартёр',
    },
    {
      'id': 'finish_judge',
      'label': 'Судья на финише',
      'icon': '🏁',
      'color': 0xFF009688,
      'screens': 'Финиш',
    },
    {
      'id': 'marshal',
      'label': 'Маршал',
      'icon': '🚩',
      'color': 0xFFFF5722,
      'screens': 'Маршал (чекпоинт)',
    },
    {
      'id': 'vet',
      'label': 'Ветеринар',
      'icon': '🩺',
      'color': 0xFF00BCD4,
      'screens': 'Ветконтроль',
    },
    {
      'id': 'announcer',
      'label': 'Диктор',
      'icon': '🎙',
      'color': 0xFFE91E63,
      'screens': 'Диктор, Live',
    },
    {
      'id': 'timekeeper',
      'label': 'Хронометрист',
      'icon': '⏱',
      'color': 0xFF795548,
      'screens': 'Финиш (только метки)',
    },
    {
      'id': 'volunteer',
      'label': 'Волонтёр',
      'icon': '🤝',
      'color': 0xFF607D8B,
      'screens': 'Только назначенный экран',
    },
  ];

  final List<Map<String, dynamic>> _team = [];

  static const _screenNames = [
    'Стартёр',
    'Финиш',
    'Маршал',
    'Диктор',
    'Live',
    'Протесты',
    'Протокол',
    'Ветконтроль',
    'Регистрация',
    'Финансы',
  ];
  static const _accessMatrix = {
    'organizer': [true, true, true, true, true, true, true, true, true, true],
    'head_judge': [
      true,
      true,
      true,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
    ],
    'secretary': [
      false,
      false,
      false,
      false,
      true,
      false,
      true,
      false,
      true,
      true,
    ],
    'starter': [
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    'finish_judge': [
      false,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    'marshal': [
      false,
      false,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    'vet': [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      true,
      false,
      false,
    ],
    'announcer': [
      false,
      false,
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
    ],
    'timekeeper': [
      false,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    'volunteer': [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Map<String, dynamic> _roleDef(String id) => _roleRegistry.firstWhere(
    (r) => r['id'] == id,
    orElse: () => _roleRegistry.last,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Команда / Роли'),
        bottom: AppPillTabBar(
          controller: _tabs,
          tabs: const ['Команда', 'Роли', 'QR'],
          icons: const [Icons.people, Icons.security, Icons.qr_code_2],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignRole(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Назначить'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildTeamTab(context),
          _buildRolesTab(context),
          _buildQrTab(context),
        ],
      ),
    );
  }

  // TAB 1: Команда
  Widget _buildTeamTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final judges = _team
        .where((m) => ['head_judge', 'finish_judge'].contains(m['role']))
        .toList();
    final operators = _team
        .where(
          (m) => [
            'starter',
            'announcer',
            'timekeeper',
            'secretary',
          ].contains(m['role']),
        )
        .toList();
    final field = _team
        .where((m) => ['marshal', 'vet'].contains(m['role']))
        .toList();
    final volunteers = _team.where((m) => m['role'] == 'volunteer').toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            AppStatCard(
              value: '${_team.length}',
              label: 'Всего',
              color: cs.primary,
            ),
            const SizedBox(width: 4),
            AppStatCard(
              value: '${_team.where((m) => m['status'] == 'online').length}',
              label: 'Online',
              color: cs.primary,
            ),
            const SizedBox(width: 4),
            AppStatCard(
              value: '${_team.where((m) => m['status'] == 'offline').length}',
              label: 'Offline',
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (judges.isNotEmpty) _section(cs, 'Судьи', judges, context),
        if (operators.isNotEmpty) _section(cs, 'Операторы', operators, context),
        if (field.isNotEmpty) _section(cs, 'Полевые', field, context),
        if (volunteers.isNotEmpty)
          _section(cs, 'Волонтёры', volunteers, context),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _section(
    ColorScheme cs,
    String title,
    List<Map<String, dynamic>> members,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...members.map((m) => _memberCard(m, context, cs)),
      ],
    );
  }

  Widget _memberCard(
    Map<String, dynamic> member,
    BuildContext context,
    ColorScheme cs,
  ) {
    final role = _roleDef(member['role']);
    final color = Color(role['color'] as int);
    final online = member['status'] == 'online';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          AppUserProfileSheet.show(
            context,
            user: member,
            isOrganizer: true,
            contextActionsBuilder: (innerCtx) => [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.security, size: 20, color: cs.primary),
                ),
                title: const Text(
                  'Роль / Доступ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  role['label'] as String,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(innerCtx).push(
                    AppGlassRoute(
                      child: Builder(
                        builder: (c) => Scaffold(
                          backgroundColor: Colors.transparent,
                          appBar: AppAppBar(
                            title: const Text(
                              'Настройки участника',
                              style: TextStyle(fontSize: 18),
                            ),
                            leading: const BackButton(),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                          ),
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _buildAssignRoleBody(c, member),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, size: 20, color: cs.secondary),
                ),
                title: const Text(
                  'Пост / Чекпоинт',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  member['checkpoint'] ?? 'Не назначен',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(innerCtx).push(
                    AppGlassRoute(
                      child: Builder(
                        builder: (c) => Scaffold(
                          backgroundColor: Colors.transparent,
                          appBar: AppAppBar(
                            title: const Text(
                              'Выбор поста',
                              style: TextStyle(fontSize: 18),
                            ),
                            leading: const BackButton(),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                          ),
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _buildAssignCheckpointBody(c, cs, member, (
                              newCp,
                            ) {
                              setState(() => member['checkpoint'] = newCp);
                              Navigator.of(c).pop(); // pop inner
                            }),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        child: AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        role['icon'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    if (online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          if (member['checkpoint'] != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                member['checkpoint'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: Роли и доступ
  Widget _buildRolesTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 12,
            right: 12,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppInfoBanner.info(
                  title:
                      'Матрица определяет какие экраны видны каждой роли. Организатор имеет полный доступ.',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows),
                tooltip: 'Вид таблицы',
                onPressed: () => setState(() => _isTableView = !_isTableView),
              ),
            ],
          ),
        ),
        AppProtocolTable(
          itemCount: _roleRegistry.where((r) => r['id'] != 'organizer').length,
          forceTableView: _isTableView,
          headerRow: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Роль',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                ..._screenNames.map(
                  (s) => Expanded(
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(s, style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context, index, isCard) {
            final roleList = _roleRegistry
                .where((r) => r['id'] != 'organizer')
                .toList();
            final r = roleList[index];
            final access = _accessMatrix[r['id']]!;
            final color = Color(r['color'] as int);

            if (isCard) {
              final allowedScreens = [];
              for (int i = 0; i < access.length; i++) {
                if (access[i]) allowedScreens.add(_screenNames[i]);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            r['icon'] as String,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allowedScreens
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r['icon'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          r['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...access.map(
                    (has) => Expanded(
                      child: Center(
                        child: Icon(
                          has
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          size: 16,
                          color: has ? cs.primary : cs.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 24,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Описание ролей:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ..._roleRegistry.map((r) {
          final color = Color(r['color'] as int);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 12, right: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      r['icon'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                      Text(
                        r['screens'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 3: QR
  Widget _buildQrTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.link, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Пригласить по ссылке',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Отправьте эту ссылку коллегам',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'sportos.app/invite/evt-1/abc123',
                      style: TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.all(8),
                    ),
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        AppSnackBar.success(context, 'Ссылка скопирована!'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Роль при переходе:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                DropdownButton<String>(
                  value: 'volunteer',
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  items: _roleRegistry
                      .where((r) => r['id'] != 'organizer')
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text('${r['icon']} ${r['label']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Выдать доступ вручную',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            AppTextField(
              label: 'ФИО, email или телефон',
              prefixIcon: Icons.search,
            ),
            const SizedBox(height: 12),
            AppUserTile(
              dense: true,
              name: 'Маркова А.А.',
              subtitle: 'markova@email.com',
              trailing: AppButton.small(
                text: '+ Добавить',
                onPressed: () => _showAssignRole(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          'Быстрые доступы (Сканируй QR)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Откройте нужный QR и дайте волонтеру отсканировать его с камеры телефона.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _qrRoleCard(
              cs,
              'Маршал',
              'Полевой судья',
              Icons.flag_circle,
              cs.tertiary,
            ),
            _qrRoleCard(cs, 'Стартёр', 'Зона старта', Icons.timer, cs.primary),
            _qrRoleCard(
              cs,
              'Финиш',
              'Зона финиша',
              Icons.sports_score,
              cs.secondary,
            ),
            _qrRoleCard(
              cs,
              'Ветконтроль',
              'Осмотр',
              Icons.pets,
              const Color(0xFF00BCD4),
            ),
          ],
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _qrRoleCard(
    ColorScheme cs,
    String role,
    String desc,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _showQrDialog(context, cs, role, desc, color),
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          Text(
            desc,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 16, color: cs.onSurface),
                const SizedBox(width: 6),
                const Text(
                  'Показать',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(
    BuildContext context,
    ColorScheme cs,
    String role,
    String desc,
    Color color,
  ) {
    AppBottomSheet.show(
      context,
      title: 'Быстрый доступ: $role',
      initialHeight: 0.55,
      child: Column(
        children: [
          Text(desc, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: const Center(
              child: Icon(Icons.qr_code, size: 120, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Действителен 5 минут',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      actions: [
        AppButton.secondary(
          text: 'Закрыть',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  void _showAssignRole(BuildContext context, {Map<String, dynamic>? existing}) {
    AppBottomSheet.show(
      context,
      title: existing != null ? 'Настройки участника' : 'Назначить роль',
      initialHeight: 0.7,
      child: _buildAssignRoleBody(context, existing),
    );
  }

  Widget _buildAssignRoleBody(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) {
    final cs = Theme.of(context).colorScheme;
    String? selectedRole = existing?['role'];
    String? currentCheckpoint = existing?['checkpoint'];
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');

    return StatefulBuilder(
      builder: (ctx, setModal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (existing == null) ...[
            AppTextField(
              label: 'ФИО, телефон или email',
              controller: nameCtrl,
              prefixIcon: Icons.search,
            ),
            const SizedBox(height: 16),
          ] else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    existing['name'].toString().isNotEmpty
                        ? existing['name'].toString()[0]
                        : '?',
                    style: TextStyle(fontSize: 20, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${existing['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Команда организаторов',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'Режим доступа (Роль)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roleRegistry
                    .where((r) => r['id'] != 'organizer')
                    .map((r) {
                      final color = Color(r['color'] as int);
                      final sel = selectedRole == r['id'];
                      return ChoiceChip(
                        avatar: Text(
                          r['icon'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(
                          r['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: sel ? cs.onPrimary : color,
                          ),
                        ),
                        selected: sel,
                        selectedColor: color,
                        backgroundColor: color.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        onSelected: (_) =>
                            setModal(() => selectedRole = r['id'] as String),
                      );
                    })
                    .toList(),
              ),
              if (selectedRole != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Экраны, к которым будет доступ:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _roleDef(selectedRole!)['screens'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Координация',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(4),
            children: [
              ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: currentCheckpoint != null
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                title: const Text(
                  'Привязка к посту',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  currentCheckpoint ??
                      'Пост не назначен (свободное перемещение)',
                  style: TextStyle(
                    color: currentCheckpoint != null
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // We need to push the assign checkpoint view instead of showing a dialog
                  Navigator.of(ctx).push(
                    AppGlassRoute(
                      child: Builder(
                        builder: (c) => Scaffold(
                          backgroundColor: Colors.transparent,
                          appBar: AppAppBar(
                            title: const Text(
                              'Выбор поста',
                              style: TextStyle(fontSize: 18),
                            ),
                            leading: const BackButton(),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                          ),
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _buildAssignCheckpointBody(
                              c,
                              cs,
                              {'checkpoint': currentCheckpoint},
                              (newCp) {
                                setModal(() => currentCheckpoint = newCp);
                                Navigator.of(c).pop();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
          if (existing != null) ...[
            AppButton.smallDanger(
              text: 'Снять все роли и удалить',
              icon: Icons.person_remove,
              onPressed: () {
                setState(() => _team.remove(existing));
                Navigator.pop(ctx);
                if (Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                AppSnackBar.success(
                  context,
                  '${existing['name']} удален из команды',
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          AppButton.primary(
            text: existing != null ? 'Сохранить изменения' : 'Выдать доступ',
            onPressed: selectedRole != null
                ? () {
                    if (existing != null) {
                      setState(() {
                        existing['role'] = selectedRole;
                        existing['checkpoint'] = currentCheckpoint;
                      });
                    } else if (nameCtrl.text.isNotEmpty) {
                      setState(
                        () => _team.add({
                          'name': nameCtrl.text,
                          'role': selectedRole,
                          'checkpoint': currentCheckpoint,
                          'status': 'offline',
                        }),
                      );
                    }
                    Navigator.pop(ctx);
                    AppSnackBar.success(
                      context,
                      '${existing != null ? 'Роль обновлена' : 'Назначен'}: ${_roleDef(selectedRole!)['label']}',
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignCheckpointBody(
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> member,
    void Function(String?) onApply,
  ) {
    final ctrl = TextEditingController(text: member['checkpoint'] ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelect<String>(
          label: 'Быстрый выбор',
          value:
              member['checkpoint'] != null &&
                  [
                    'CP1 — 3км',
                    'CP2 — 6км',
                    'Старт',
                    'Финиш',
                    'Зона регистрации',
                    'Ветзона',
                  ].contains(member['checkpoint'])
              ? member['checkpoint']
              : null,
          items: const [
            SelectItem(value: 'CP1 — 3км', label: 'CP1 — 3км'),
            SelectItem(value: 'CP2 — 6км', label: 'CP2 — 6км'),
            SelectItem(value: 'Старт', label: 'Старт'),
            SelectItem(value: 'Финиш', label: 'Финиш'),
            SelectItem(value: 'Зона регистрации', label: 'Зона регистрации'),
            SelectItem(value: 'Ветзона', label: 'Ветзона'),
          ],
          onChanged: (v) => ctrl.text = v,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Свой вариант (или ID поста)',
          controller: ctrl,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            AppButton.text(
              text: 'Очистить пост',
              onPressed: () => onApply(null),
            ),
            const Spacer(),
            AppButton.small(
              text: 'Применить',
              onPressed: () => onApply(ctrl.text.isNotEmpty ? ctrl.text : null),
            ),
          ],
        ),
      ],
    );
  }
}

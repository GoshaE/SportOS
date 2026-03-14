import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_colors.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR1 — Профиль пользователя
/// Refactored to use Design System atoms: AppAvatar, AppCard, AppSectionHeader,
/// AppInfoBanner, AppDialog, AppSnackBar, AppBottomSheet, AppTextField.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Данные профиля (TODO: заменить на Riverpod провайдер)
  String _name = 'Александр Иванов';
  String _city = 'Екатеринбург';
  String _phone = '+7 912 345-67-89';
  String _email = 'alex@example.com';
  String _birthDate = '15.05.1990';

  // Разряды по видам спорта
  final List<Map<String, String>> _ranks = [
    {'sport': '🐕 Ездовой спорт', 'rank': 'КМС', 'since': '2024'},
    {'sport': '⛷ Лыжные гонки', 'rank': '1 разряд', 'since': '2022'},
  ];

  // Незаклеймленные результаты гостя
  final List<Map<String, String>> _unclaimedResults = [
    {
      'event': 'Ночная гонка 2025',
      'disc': 'Скиджоринг 6км',
      'bib': '42',
      'time': '23:15',
      'place': '3',
      'date': '22.12.2025',
    },
  ];

  // Семья
  final List<Map<String, String>> _family = [
    {'name': 'Иванов Иван (Сын)', 'birthDate': '25.08.2015'},
  ];

  static const _allSports = [
    '🐕 Ездовой спорт',
    '🏃🐕 Каникросс',
    '🏔 Трейл',
    '🏃 Лёгкая атлетика',
    '⛷ Лыжные гонки',
    '🚴 Велоспорт',
    '🏊 Плавание',
    '🏅 Триатлон',
  ];

  static const _allRanks = [
    'Без разряда',
    '3 юношеский',
    '2 юношеский',
    '1 юношеский',
    '3 разряд',
    '2 разряд',
    '1 разряд',
    'КМС',
    'МС',
    'МСМК',
    'ЗМС',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: _showEditProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Аватар + Информация ──
          _buildHeader(theme),
          const SizedBox(height: 16),

          // ── Незаклеймленные результаты ──
          if (_unclaimedResults.isNotEmpty) ...[
            _buildUnclaimedBanner(),
            const SizedBox(height: 12),
          ],

          // ── Спортивные разряды ──
          _buildRanksSection(theme),
          const SizedBox(height: 8),

          // ── Семья ──
          _buildFamilySection(theme),
          const SizedBox(height: 16),

          // ── Навигация ──
          AppCard(
            children: [
              AppCard.item(
                icon: Icons.folder_shared,
                label: 'Мои документы',
                onTap: () => context.go('/profile/documents'),
              ),
              AppCard.item(
                icon: Icons.pets,
                label: 'Мои собаки',
                onTap: () => context.go('/profile/dogs'),
              ),
              AppCard.item(
                icon: Icons.emoji_events,
                label: 'Мои результаты',
                onTap: () => context.go('/profile/results'),
              ),
              AppCard.item(
                icon: Icons.workspace_premium,
                label: 'Мои дипломы',
                onTap: () => context.go('/profile/diplomas'),
              ),
              AppCard.item(
                icon: Icons.sports,
                label: 'Тренер',
                onTap: () => context.go('/profile/trainer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            children: [
              AppCard.item(
                icon: Icons.settings,
                label: 'Настройки',
                onTap: () => context.go('/profile/settings'),
              ),
              AppCard.item(
                icon: Icons.qr_code_scanner,
                label: 'QR Pairing',
                onTap: () => context.go('/pair'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD SECTIONS
  // ─────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        AppAvatar(name: _name, imageUrl: 'assets/images/avatar3.jpeg', size: 88, editable: true, onEdit: () {}),
        const SizedBox(height: 10),
        Text(
          _name,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '$_city · $_birthDate',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _phone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.email, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnclaimedBanner() {
    final r = _unclaimedResults.first;
    return AppInfoBanner.warning(
      title: 'Результаты без аккаунта (${_unclaimedResults.length})',
      subtitle: '${r['event']} · ${r['disc']} · #${r['place']} (${r['time']})',
      action: TextButton(
        onPressed: _showClaimDialog,
        child: const Text('Привязать', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildRanksSection(ThemeData theme) {
    return AppCard(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Спортивные разряды',
                icon: Icons.military_tech,
                action: 'Добавить',
                onAction: _showAddRank,
                padding: EdgeInsets.zero,
              ),
              if (_ranks.isEmpty)
                AppEmptyState(
                  icon: Icons.military_tech,
                  title: 'Нет разрядов',
                  subtitle: 'Нажмите «Добавить»',
                )
              else
                ..._ranks.asMap().entries.map((e) {
                  final r = e.value;
                  final color = _rankColor(r['rank']!);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        _rankAbbr(r['rank']!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    title: Text(r['sport']!, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      '${r['rank']} · с ${r['since']} г.',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Изменить'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить'),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'delete') {
                          setState(() => _ranks.removeAt(e.key));
                        }
                        if (v == 'edit') {
                          _showEditRank(e.key);
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection(ThemeData theme) {
    return AppCard(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Моя семья',
                icon: Icons.family_restroom,
                action: 'Добавить',
                onAction: _showAddChild,
                padding: EdgeInsets.zero,
              ),
              if (_family.isEmpty)
                AppEmptyState(
                  icon: Icons.family_restroom,
                  title: 'Нет привязанных',
                  subtitle: 'Привяжите профили детей для быстрой регистрации',
                )
              else
                ..._family.asMap().entries.map((e) {
                  final f = e.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: AppAvatar(name: f['name']!, imageUrl: 'assets/images/avatar4.jpeg', size: 36),
                    title: Text(f['name']!, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      'Дата рождения: ${f['birthDate']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => setState(() => _family.removeAt(e.key)),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // DIALOGS & SHEETS
  // ─────────────────────────────────────────

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final cityCtrl = TextEditingController(text: _city);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);
    final birthCtrl = TextEditingController(text: _birthDate);

    AppBottomSheet.show(
      context,
      title: 'Редактировать профиль',
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            setState(() {
              _name = nameCtrl.text;
              _city = cityCtrl.text;
              _phone = phoneCtrl.text;
              _email = emailCtrl.text;
              _birthDate = birthCtrl.text;
            });
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Профиль обновлён');
          },
        ),
      ],
      child: Column(
        children: [
          Center(
            child: AppAvatar(
              name: _name,
              imageUrl: 'assets/images/avatar3.jpeg',
              size: 80,
              editable: true,
              onEdit: () {},
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Имя и фамилия', controller: nameCtrl),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Дата рождения',
            controller: birthCtrl,
            prefixIcon: Icons.cake,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Город',
            controller: cityCtrl,
            prefixIcon: Icons.location_city,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Телефон',
            controller: phoneCtrl,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Email',
            controller: emailCtrl,
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  void _showAddChild() {
    final nameCtrl = TextEditingController();
    final birthCtrl = TextEditingController();

    AppBottomSheet.show(
      context,
      title: 'Добавить ребёнка',
      initialHeight: 0.55,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            if (nameCtrl.text.isNotEmpty && birthCtrl.text.isNotEmpty) {
              setState(
                () => _family.add({
                  'name': nameCtrl.text,
                  'birthDate': birthCtrl.text,
                }),
              );
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'Аккаунт ребёнка создан');
            } else {
              AppSnackBar.error(context, 'Заполните все поля');
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Создайте сабаккаунт для быстрой регистрации на детские старты.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                label: 'ФИО ребёнка',
                controller: nameCtrl,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Дата рождения (ДД.ММ.ГГГГ)',
                controller: birthCtrl,
                prefixIcon: Icons.cake,
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRank() {
    String? selectedSport;
    String selectedRank = 'Без разряда';
    final yearCtrl = TextEditingController(text: '2025');
    final available = _allSports
        .where((s) => !_ranks.any((r) => r['sport'] == s))
        .toList();
    if (available.isNotEmpty) selectedSport = available.first;

    AppBottomSheet.show(
      context,
      title: 'Добавить разряд',
      initialHeight: 0.55,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () {
            if (selectedSport != null) {
              setState(
                () => _ranks.add({
                  'sport': selectedSport!,
                  'rank': selectedRank,
                  'since': yearCtrl.text,
                }),
              );
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'Спортивный разряд добавлен');
            }
          },
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите дисциплину и актуальное звание для формирования вашего рейтинга.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSport,
                  decoration: InputDecoration(
                    labelText: 'Вид спорта',
                    prefixIcon: const Icon(Icons.sports),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: available
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedSport = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRank,
                  decoration: InputDecoration(
                    labelText: 'Разряд / Звание',
                    prefixIcon: const Icon(Icons.military_tech),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _allRanks
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setModal(() => selectedRank = v ?? selectedRank),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Год присвоения',
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              text: 'Прикрепить документ (опционально)',
              icon: Icons.upload_file,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRank(int idx) {
    final r = _ranks[idx];
    String selectedRank = r['rank']!;
    final yearCtrl = TextEditingController(text: r['since']!);

    AppBottomSheet.show(
      context,
      title: 'Разряд: ${r['sport']}',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Сохранить изменения',
          onPressed: () {
            setState(() {
              _ranks[idx] = {
                'sport': r['sport']!,
                'rank': selectedRank,
                'since': yearCtrl.text,
              };
            });
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRank,
                  decoration: InputDecoration(
                    labelText: 'Разряд / Звание',
                    prefixIcon: const Icon(Icons.military_tech),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _allRanks
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setModal(() => selectedRank = v ?? selectedRank),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Год присвоения',
                  controller: yearCtrl,
                  prefixIcon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimDialog() {
    // TODO: Wizard-flow для привязки результатов (Email/Telegram)
    // Вынести в отдельный виджет ClaimWizard при реализации с Riverpod
    AppDialog.confirm(
      context,
      title: 'Привязка результатов',
      message:
          'Привязать результаты гостевого участия к вашему профилю? '
          'Вам потребуется подтверждение через Email или Telegram.',
      confirmText: 'Привязать',
      onConfirm: () {
        setState(() => _unclaimedResults.clear());
        AppSnackBar.success(context, 'Результат привязан к профилю!');
      },
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  Color _rankColor(String rank) {
    final cs = Theme.of(context).colorScheme;
    return switch (rank) {
      'МСМК' || 'ЗМС' => cs.error,
      'МС' => AppColors.primary,
      'КМС' => cs.primary,
      '1 разряд' => cs.secondary,
      '2 разряд' => cs.tertiary,
      '3 разряд' => AppColors.success,
      _ => cs.onSurfaceVariant,
    };
  }

  String _rankAbbr(String rank) => switch (rank) {
    'МСМК' => 'МСМК',
    'ЗМС' => 'ЗМС',
    'МС' => 'МС',
    'КМС' => 'КМС',
    '1 разряд' => 'I',
    '2 разряд' => 'II',
    '3 разряд' => 'III',
    '1 юношеский' => 'Iю',
    '2 юношеский' => 'IIю',
    '3 юношеский' => 'IIIю',
    _ => '—',
  };
}

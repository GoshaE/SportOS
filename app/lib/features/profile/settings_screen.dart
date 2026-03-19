import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR6 — Настройки пользователя
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _tgLinked = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ Оформление ═══
          AppSectionHeader(title: 'Оформление', icon: Icons.palette),
          AppCard(children: [
            AppCard.item(
              icon: Icons.palette,
              label: 'Тема и цвета',
              subtitle: _themeModeName(themeState.mode),
              onTap: () => context.go('/profile/settings/theme'),
            ),
            AppCard.item(
              icon: Icons.language,
              label: 'Язык',
              subtitle: 'Русский',
            ),
          ]),
          const SizedBox(height: 16),

          // ═══ Уведомления и поведение ═══
          AppSectionHeader(title: 'Уведомления и поведение', icon: Icons.tune),
          AppCard(children: [
            AppCard.item(
              icon: Icons.notifications,
              label: 'Уведомления',
              subtitle: 'Push, Email, Telegram, тихий режим',
              onTap: () => context.go('/profile/settings/notifications'),
            ),
            AppCard.item(
              icon: Icons.timer,
              label: 'Режим гонки',
              subtitle: 'Звук отсечки, вибрация',
              onTap: () {}, // TODO: → отдельный экран или bottom sheet
            ),
          ]),
          const SizedBox(height: 16),

          // ═══ Привязанные аккаунты ═══
          AppSectionHeader(title: 'Привязанные аккаунты', icon: Icons.link),
          AppCard(children: [
            _accountTile(
              icon: Icons.telegram,
              color: const Color(0xFF0088CC),
              name: 'Telegram',
              subtitle: _tgLinked ? '@alex_ivanov · @SportOS_bot' : 'Не привязан',
              linked: _tgLinked,
              onLink: _linkTelegram,
              onUnlink: () => setState(() => _tgLinked = false),
            ),
            _accountTile(
              icon: Icons.g_mobiledata,
              color: Theme.of(context).colorScheme.error,
              name: 'Google',
              subtitle: 'alex@gmail.com',
              linked: true,
            ),
            _accountTile(
              icon: Icons.apple,
              color: theme.colorScheme.onSurface,
              name: 'Apple ID',
              subtitle: 'Не привязан',
              linked: false,
              onLink: () {},
            ),
          ]),
          const SizedBox(height: 16),

          // ═══ Безопасность ═══
          AppSectionHeader(title: 'Безопасность', icon: Icons.shield_outlined),
          AppCard(children: [
            AppCard.item(
              icon: Icons.devices,
              label: 'Активные сессии',
              badge: '3',
              onTap: _showSessions,
            ),
            AppCard.item(
              icon: Icons.download,
              label: 'Экспорт данных',
              subtitle: 'Профиль + результаты (JSON/CSV)',
              onTap: () => AppSnackBar.info(context, 'Экспорт данных запущен...'),
            ),
          ]),
          const SizedBox(height: 16),

          // ═══ Правовое ═══
          AppSectionHeader(title: 'Правовое', icon: Icons.gavel),
          AppCard(children: [
            AppCard.item(icon: Icons.description, label: 'Согласия и документы', onTap: _showConsents),
            AppCard.item(icon: Icons.privacy_tip, label: 'Политика конфиденциальности', trailing: const Icon(Icons.open_in_new, size: 18)),
            AppCard.item(icon: Icons.gavel, label: 'Пользовательское соглашение', trailing: const Icon(Icons.open_in_new, size: 18)),
          ]),
          const SizedBox(height: 16),

          // ═══ О приложении ═══
          AppSectionHeader(title: 'О приложении', icon: Icons.info_outline),
          AppCard(children: [
            AppCard.item(
              icon: Icons.info,
              label: 'SportOS',
              subtitle: 'Версия 1.0.0 (build 1)',
            ),
          ]),
          const SizedBox(height: 24),

          // ═══ Выйти (с подтверждением) ═══
          AppButton.secondary(
            text: 'Выйти из аккаунта',
            icon: Icons.logout,
            onPressed: _confirmLogout,
          ),
          const SizedBox(height: 32),

          // ═══ Danger Zone ═══
          Center(
            child: AppButton.text(
              text: 'Удалить аккаунт',
              onPressed: _showDeleteAccount,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // ACCOUNT TILE
  // ─────────────────────────────────────────

  Widget _accountTile({
    required IconData icon,
    required Color color,
    required String name,
    required String subtitle,
    required bool linked,
    VoidCallback? onLink,
    VoidCallback? onUnlink,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(name),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: linked
          ? (onUnlink != null
              ? AppButton.text(
                  text: 'Отвязать',
                  onPressed: onUnlink,
                )
              : Icon(Icons.check_circle, color: cs.primary, size: 20))
          : AppButton.text(text: 'Привязать', onPressed: onLink ?? () {}),
    );
  }

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────

  void _confirmLogout() {
    AppDialog.confirm(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Вы можете войти обратно в любой момент.',
      confirmText: 'Выйти',
      onConfirm: () => context.go('/welcome'),
    );
  }

  void _linkTelegram() {
    
    AppBottomSheet.show(
      context,
      title: 'Привязать Telegram',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Готово',
          onPressed: () {
            setState(() => _tgLinked = true);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Откройте бот @SportOS_bot и отправьте команду:'),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              const SelectableText(
                '/link X9K3M7',
                style: TextStyle(fontFamily: 'Roboto Mono', fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton.secondary(
            text: 'Открыть @SportOS_bot',
            icon: Icons.open_in_new,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _showSessions() {
    AppBottomSheet.show(
      context,
      title: 'Активные сессии',
      initialHeight: 0.45,
      actions: [
        AppButton.secondary(
          text: 'Завершить все кроме текущей',
          icon: Icons.logout,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.warning(context, 'Все сессии кроме текущей завершены');
          },
        ),
      ],
      child: Column(children: [
        _sessionTile('iPhone 14 Pro', 'Этот телефон', 'Сейчас', true),
        _sessionTile('MacBook Pro', 'macOS · Chrome', '2 часа назад', false),
        _sessionTile('iPad Air', 'iPadOS · Safari', '3 дня назад', false),
      ]),
    );
  }

  Widget _sessionTile(String device, String info, String time, bool current) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        current ? Icons.phone_iphone : Icons.devices,
        color: current ? cs.primary : cs.outline,
      ),
      title: Text(device, style: theme.textTheme.titleSmall),
      subtitle: Text('$info · $time', style: theme.textTheme.bodySmall),
      trailing: current ? const StatusBadge(text: 'Текущая', type: BadgeType.success) : null,
    );
  }

  void _showConsents() {
    AppBottomSheet.show(
      context,
      title: 'Согласия и документы',
      initialHeight: 0.45,
      child: Column(children: [
        _consentRow('Обработка персональных данных', true, true),
        _consentRow('Обработка данных собаки', true, true),
        _consentRow('Фото/видео на мероприятиях', true, false),
        _consentRow('Маркетинговые рассылки', false, false),
      ]),
    );
  }

  Widget _consentRow(String label, bool given, bool required) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: required
          ? Text('Обязательное', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline))
          : null,
      trailing: given
          ? Icon(Icons.check_circle, color: cs.primary, size: 20)
          : AppButton.secondary(text: 'Дать', onPressed: () {}),
    );
  }

  void _showDeleteAccount() {
    AppDialog.confirm(
      context,
      title: 'Удалить аккаунт?',
      message: 'Все данные будут удалены: результаты станут анонимными, данные собак удалены, '
          'членство в клубах снято. У вас будет 30 дней на восстановление.',
      confirmText: 'Удалить аккаунт',
      isDanger: true,
      onConfirm: () => AppSnackBar.info(context, 'Ссылка для подтверждения отправлена на email'),
    );
  }

  String _themeModeName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Светлая тема',
    ThemeMode.dark => 'Тёмная тема',
    ThemeMode.system => 'Системная',
  };
}

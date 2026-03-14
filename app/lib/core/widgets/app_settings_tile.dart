import 'package:flutter/material.dart';

/// AppSettingsTile: Unified settings row with multiple variants.
///
/// Replaces 20+ ad-hoc SwitchListTile, ListTile+chevron, RadioListTile
/// across event_settings_screen, multi_day_config, settings_screen.
///
/// Usage:
/// ```dart
/// AppSettingsTile.toggle(title: 'GPS трекинг', value: false, onChanged: (_) {})
/// AppSettingsTile.nav(title: 'Точность', subtitle: '0.001', onTap: () {})
/// AppSettingsTile.radio(title: 'Обратный', value: 'reverse', groupValue: _v, onChanged: (_) {})
/// AppSettingsTile.account(icon: Icons.telegram, name: 'Telegram', subtitle: '@alex', linked: true)
/// ```
class AppSettingsTile extends StatelessWidget {
  final Widget child;

  const AppSettingsTile._({required this.child});

  /// Toggle switch setting
  static Widget toggle({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return AppSettingsTile._(child: SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    ));
  }

  /// Navigation setting (opens sub-screen or picker)
  static Widget nav({
    required String title,
    String? subtitle,
    IconData trailing = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return AppSettingsTile._(child: ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(trailing),
      onTap: onTap,
    ));
  }

  /// Radio option setting
  static Widget radio<T>({
    required String title,
    String? subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return AppSettingsTile._(child: Builder(builder: (context) {
      return RadioGroup<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: RadioListTile<T>(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          value: value,
        ),
      );
    }));
  }

  /// Linked account setting (Telegram, Google, Apple)
  static Widget account({
    required IconData icon,
    required Color color,
    required String name,
    required String subtitle,
    required bool linked,
    VoidCallback? onLink,
    VoidCallback? onUnlink,
  }) {
    return AppSettingsTile._(child: Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: linked
            ? (onUnlink != null
                ? TextButton(
                    onPressed: onUnlink,
                    child: Text('Отвязать', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.error)),
                  )
                : Icon(Icons.check_circle, color: cs.primary, size: 20))
            : TextButton(onPressed: onLink, child: Text('Привязать', style: Theme.of(context).textTheme.labelMedium)),
      );
    }));
  }

  @override
  Widget build(BuildContext context) => child;
}

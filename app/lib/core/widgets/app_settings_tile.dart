import 'package:flutter/material.dart';

/// AppSettingsTile: Telegram-style settings rows.
///
/// Clean, compact cells with title on the left and value/control on the right.
/// Designed for use inside `AppCard(padding: EdgeInsets.zero, ...)`.
///
/// Usage:
/// ```dart
/// AppSettingsTile.toggle(title: 'GPS трекинг', value: false, onChanged: (_) {})
/// AppSettingsTile.nav(title: 'Точность', subtitle: '0.001', onTap: () {})
/// AppSettingsTile.radio(title: 'Обратный', value: 'reverse', groupValue: _v, onChanged: (_) {})
/// ```
class AppSettingsTile extends StatelessWidget {
  final Widget child;

  const AppSettingsTile._({required this.child});

  /// Toggle switch setting — Telegram-style: title left, switch right.
  static Widget toggle({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return AppSettingsTile._(child: Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return InkWell(
        onTap: onChanged != null ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 15, color: cs.onSurface)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
              ],
            )),
            const SizedBox(width: 12),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch(value: value, onChanged: onChanged),
              ),
            ),
          ]),
        ),
      );
    }));
  }

  /// Navigation setting — Telegram-style: title left, value + chevron right.
  static Widget nav({
    required String title,
    String? subtitle,
    String? badge,
    IconData trailing = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return AppSettingsTile._(child: Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: cs.onSurface))),
            if (subtitle != null) ...[
              Text(subtitle, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
              const SizedBox(width: 4),
            ],
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
            ],
            Icon(trailing, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          ]),
        ),
      );
    }));
  }

  /// Radio option — Telegram-style: title left, checkmark right when selected.
  static Widget radio<T>({
    required String title,
    String? subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return AppSettingsTile._(child: Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final selected = value == groupValue;
      return InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 15,
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                )),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
              ],
            )),
            if (selected)
              Icon(Icons.check, size: 20, color: cs.primary),
          ]),
        ),
      );
    }));
  }

  /// Linked account setting (Telegram, Google, Apple).
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(fontSize: 15, color: cs.onSurface)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          )),
          if (linked)
            onUnlink != null
              ? TextButton(
                  onPressed: onUnlink,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text('Отвязать', style: TextStyle(fontSize: 13, color: cs.error)),
                )
              : Icon(Icons.check_circle, color: cs.primary, size: 20)
          else
            TextButton(
              onPressed: onLink,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Привязать', style: TextStyle(fontSize: 13)),
            ),
        ]),
      );
    }));
  }

  @override
  Widget build(BuildContext context) => child;
}

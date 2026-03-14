import 'package:flutter/material.dart';

/// Semantic status for AppStatusRow
enum AppStatus {
  ok,      // ✅ Green check
  warning, // ⚠️ Orange/amber warning
  error,   // ❌ Red error
  pending, // ⏳ Grey hourglass
}

/// AppStatusRow: Status row with icon, title, and optional subtitle.
///
/// Replaces 7+ different ListTile(dense, leading: Icon(check/warning), ...)
/// across participants_screen, vet_check, starter, finish, protocol,
/// profile_documents, settings.
///
/// Usage:
/// ```dart
/// AppStatusRow(title: 'Оплата', subtitle: '2 500 ₽', status: AppStatus.ok)
/// AppStatusRow(title: 'Ветпаспорт', status: AppStatus.warning)
/// AppStatusRow.custom(icon: Icons.pets, iconColor: cs.primary, title: 'Собака', subtitle: 'Rex')
/// ```
class AppStatusRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const AppStatusRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Creates a status row from a semantic status enum.
  factory AppStatusRow.fromStatus({
    Key? key,
    required String title,
    String? subtitle,
    required AppStatus status,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final (icon, _) = _statusIcon(status);
    return AppStatusRow(
      key: key,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  static (IconData, Color?) _statusIcon(AppStatus status) => switch (status) {
    AppStatus.ok      => (Icons.check_circle, null),
    AppStatus.warning => (Icons.warning, null),
    AppStatus.error   => (Icons.cancel, null),
    AppStatus.pending => (Icons.hourglass_empty, null),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedColor = iconColor ?? _resolveColor(cs);

    return ListTile(
      dense: true,
      contentPadding: contentPadding,
      leading: Icon(icon, color: resolvedColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Color _resolveColor(ColorScheme cs) {
    // Attempt auto-detection from icon
    return switch (icon) {
      Icons.check_circle || Icons.check || Icons.verified => cs.primary,
      Icons.warning || Icons.hourglass_empty || Icons.hourglass_top => cs.tertiary,
      Icons.cancel || Icons.error || Icons.block => cs.error,
      _ => cs.onSurfaceVariant,
    };
  }
}

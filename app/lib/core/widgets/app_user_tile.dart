import 'package:flutter/material.dart';

/// AppUserTile: Unified user/participant row with avatar, name, and actions.
///
/// Replaces 9+ different user row implementations across team_screen,
/// club_manage, draw_screen, dictator, inbox, trainer, settings.
///
/// Usage:
/// ```dart
/// AppUserTile(
///   name: 'Иванов А.А.',
///   subtitle: 'Тренер · с 2021',
///   onTap: () {},
/// )
/// AppUserTile(
///   name: 'Петров Б.Б.',
///   subtitle: 'Online',
///   leading: CircleAvatar(child: Text('⚖️')),
///   trailing: PopupMenuButton(...),
///   showOnlineDot: true,
///   isOnline: true,
/// )
/// ```
class AppUserTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;
  final bool showOnlineDot;
  final bool isOnline;
  final EdgeInsetsGeometry? contentPadding;

  const AppUserTile({
    super.key,
    required this.name,
    this.subtitle,
    this.leading,
    this.trailing,
    this.badge,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.showOnlineDot = false,
    this.isOnline = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget leadingWidget = leading ?? _defaultAvatar(context, cs);

    if (showOnlineDot) {
      leadingWidget = Stack(
        children: [
          leadingWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? cs.primary : cs.onSurfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return ListTile(
      dense: dense,
      contentPadding: contentPadding,
      leading: leadingWidget,
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?badge,
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall)
          : null,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _defaultAvatar(BuildContext context, ColorScheme cs) {
    // Generate initials from name
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length > 1
        ? '${parts[0].characters.first}${parts[1].characters.first}'.toUpperCase()
        : parts[0].characters.first.toUpperCase();

    return CircleAvatar(
      radius: dense ? 16 : 20,
      backgroundColor: cs.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: dense ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

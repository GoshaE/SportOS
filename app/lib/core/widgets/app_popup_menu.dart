import 'package:flutter/material.dart';

/// Item for AppPopupMenu.
class PopupItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDanger;
  final bool isDivider;

  const PopupItem({
    this.icon,
    required this.label,
    this.onTap,
    this.isDanger = false,
    this.isDivider = false,
  });

  /// Separator between groups.
  const PopupItem.divider()
      : icon = null,
        label = '',
        onTap = null,
        isDanger = false,
        isDivider = true;
}

/// AppPopupMenu: Clean popup menu with consistent styling.
///
/// Replaces raw `PopupMenuButton` with Apple-inspired appearance.
///
/// Usage:
/// ```dart
/// AppPopupMenu(
///   items: [
///     PopupItem(icon: Icons.edit, label: 'Редактировать', onTap: _edit),
///     PopupItem(icon: Icons.copy, label: 'Дублировать', onTap: _copy),
///     const PopupItem.divider(),
///     PopupItem(icon: Icons.delete, label: 'Удалить', onTap: _delete, isDanger: true),
///   ],
/// )
/// ```
class AppPopupMenu extends StatelessWidget {
  final List<PopupItem> items;
  final Widget? child;
  final IconData triggerIcon;
  final double? iconSize;

  const AppPopupMenu({
    super.key,
    required this.items,
    this.child,
    this.triggerIcon = Icons.more_vert_rounded,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<int>(
      icon: child == null ? Icon(triggerIcon, size: iconSize ?? 22) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      offset: const Offset(0, 8),
      itemBuilder: (_) {
        final entries = <PopupMenuEntry<int>>[];
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item.isDivider) {
            entries.add(const PopupMenuDivider(height: 1));
            continue;
          }
          entries.add(PopupMenuItem<int>(
            value: i,
            height: 44,
            child: Row(children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 20,
                  color: item.isDanger ? cs.error : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: item.isDanger ? cs.error : cs.onSurface,
                ),
              ),
            ]),
          ));
        }
        return entries;
      },
      onSelected: (i) => items[i].onTap?.call(),
      child: child,
    );
  }
}

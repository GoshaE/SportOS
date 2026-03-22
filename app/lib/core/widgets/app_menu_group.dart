import 'package:flutter/material.dart';

/// A navigation group card with title and list of tappable items.
/// Each item has an icon, label, optional badge, and chevron.
/// Used in event_overview_screen for organizing screen sections.
class AppMenuGroup extends StatelessWidget {
  final String title;
  final List<AppMenuItem> items;

  const AppMenuGroup({
    super.key,
    required this.title,
    required this.items,
  });

  static AppMenuItem item(
    IconData icon,
    String label, {
    String? badge,
    Color? color,
    VoidCallback? onTap,
  }) => AppMenuItem(icon: icon, label: label, badge: badge, color: color, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          final color = item.color ?? cs.primary;

          return Column(children: [
            ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: color, size: 20),
              ),
              title: Text(item.label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
              subtitle: item.subtitle != null ? Text(item.subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)) : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badge!,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
              ]),
              onTap: item.onTap,
            ),
            if (!isLast)
              Divider(height: 1, indent: 60, endIndent: 16, color: cs.outlineVariant.withOpacity(0.3)),
          ]);
        }),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class AppMenuItem {
  final IconData icon;
  final String label;
  final String? badge;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;

  const AppMenuItem({
    required this.icon,
    required this.label,
    this.badge,
    this.subtitle,
    this.color,
    this.onTap,
  });
}


import 'package:flutter/material.dart';

/// AppCard: Grouped card container (Apple Settings style / Glassmorphic).
///
/// Usage:
/// ```dart
/// AppCard(children: [
///   AppCard.item(icon: Icons.pets, label: 'Мои собаки', onTap: ...),
///   AppCard.item(icon: Icons.emoji_events, label: 'Результаты', badge: '12', onTap: ...),
/// ])
/// ```
class AppCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.children,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
  });

  /// Convenience: a single-child card with padding
  factory AppCard.padded({Key? key, required Widget child, EdgeInsetsGeometry? padding}) {
    return AppCard(key: key, padding: padding ?? const EdgeInsets.all(16), children: [child]);
  }

  /// Convenience: Creates a standard navigation item inside a card
  static Widget item({
    required IconData icon,
    required String label,
    String? subtitle,
    String? badge,
    VoidCallback? onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return _AppCardItem(
      icon: icon,
      label: label,
      subtitle: subtitle,
      badge: badge,
      onTap: onTap,
      iconColor: iconColor,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultRadius = BorderRadius.circular(20);
    final clipRadius = borderRadius ?? defaultRadius;
    
    // We assume if someone passes BorderRadius, we should map it to BorderRadius cleanly if it's already one.
    // ClipRRect requires BorderRadius (not just Geometry typically), so we resolve it:
    final resolvedRadius = clipRadius.resolve(Directionality.of(context));

    BorderSide borderSide = BorderSide.none;
    if (borderColor != null) {
      borderSide = BorderSide(color: borderColor!, width: 1);
    } else if (theme.cardTheme.shape is RoundedRectangleBorder) {
      borderSide = (theme.cardTheme.shape as RoundedRectangleBorder).side;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHigh,
      elevation: theme.cardTheme.elevation ?? 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: resolvedRadius,
        side: borderSide,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: _insertDividers(children),
        ),
      ),
    );
  }

  List<Widget> _insertDividers(List<Widget> items) {
    if (items.length <= 1) return items;
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(const Divider(height: 1, indent: 52, endIndent: 0));
      }
    }
    return result;
  }
}

class _AppCardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  const _AppCardItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 22),
      title: Text(label, style: theme.textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: trailing ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badge!, style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600, color: theme.colorScheme.primary,
            )),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
      onTap: onTap,
    );
  }
}

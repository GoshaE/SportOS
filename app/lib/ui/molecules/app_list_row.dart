import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/// Semantic meaning of a row — controls auto-styling.
enum RowSemantic {
  normal,   // Default
  success,  // Green tint/icon
  warning,  // Amber tint/icon
  error,    // Red tint/icon
  muted,    // Greyed out (disabled/past)
}

/// AppListRow: Universal list row — replaces 5 legacy widgets.
///
/// Replaces:
/// - `AppStatusRow` — use `AppListRow.status()`
/// - `AppDetailRow` — use `AppListRow.detail()`
/// - `AppSyncRow` — use `AppListRow()`
/// - `AppQueueItem` — use `AppListRow()`
/// - `AppChecklistItem` — use `AppListRow.check()`
///
/// Usage:
/// ```dart
/// // Status row
/// AppListRow.status(title: 'Оплата', subtitle: '2 500 ₽', semantic: RowSemantic.success)
///
/// // Detail row (label: value)
/// AppListRow.detail(label: 'Дистанция', value: '6 км')
///
/// // Checklist item
/// AppListRow.check(title: 'Ветпаспорт', done: true, onChanged: (_) {})
///
/// // Queue item with custom leading/trailing
/// AppListRow(
///   leading: Icon(Icons.timer),
///   title: 'BIB 07 — Петров',
///   subtitle: 'Lap 2/3',
///   trailing: AppChip.status('На трассе', type: ChipType.info),
///   backgroundColor: cs.primaryContainer.withAlpha(13),
/// )
/// ```
class AppListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final RowSemantic semantic;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const AppListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.semantic = RowSemantic.normal,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.contentPadding,
  });

  // ─── Factory: Status row ────────────────────────────────────

  /// Status row with auto-icon from [semantic], or custom [icon].
  factory AppListRow.status({
    Key? key,
    required String title,
    String? subtitle,
    RowSemantic semantic = RowSemantic.normal,
    IconData? icon,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final Widget? leading = icon != null
        ? Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            final resolvedColor = iconColor ?? _iconAutoColor(icon, cs);
            return Icon(icon, color: resolvedColor, size: 22);
          })
        : (semantic != RowSemantic.normal ? _semanticIcon(semantic) : null);

    return AppListRow(
      key: key,
      leading: leading,
      title: title,
      subtitle: subtitle,
      semantic: semantic,
      trailing: trailing,
      onTap: onTap,
      dense: true,
      contentPadding: contentPadding,
    );
  }

  // ─── Factory: Detail row (label: value) ─────────────────────

  /// Key-value detail row with optional copy button.
  factory AppListRow.detail({
    Key? key,
    required String label,
    required String value,
    IconData? icon,
    bool copyable = false,
    VoidCallback? onTap,
  }) {
    return AppListRow(
      key: key,
      leading: icon != null ? Icon(icon) : null,
      title: label,
      subtitle: value,
      trailing: copyable
          ? Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Скопировано: $value'), duration: const Duration(seconds: 1)),
                );
              },
            ))
          : null,
      onTap: onTap,
      dense: true,
    );
  }

  // ─── Factory: Checklist item ────────────────────────────────

  /// Checkbox item for checklists (vet check, registration steps).
  factory AppListRow.check({
    Key? key,
    required String title,
    String? subtitle,
    required bool done,
    ValueChanged<bool?>? onChanged,
  }) {
    return AppListRow(
      key: key,
      leading: Checkbox(value: done, onChanged: onChanged),
      title: title,
      subtitle: subtitle,
      semantic: done ? RowSemantic.success : RowSemantic.normal,
      onTap: onChanged != null ? () => onChanged(!done) : null,
    );
  }

  // ─── Factory: Navigation row ────────────────────────────────

  /// Navigation row with chevron (settings, menu items).
  factory AppListRow.nav({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? badge,
    required VoidCallback onTap,
  }) {
    return AppListRow(
      key: key,
      leading: icon != null ? Icon(icon) : null,
      title: title,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[badge, const SizedBox(width: 4)],
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedBg = backgroundColor ?? _semanticBg(cs);

    Widget row = Container(
      decoration: BoxDecoration(
        color: resolvedBg,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(0.15),
          ),
        ),
      ),
      child: ListTile(
        dense: dense,
        contentPadding: contentPadding,
        leading: leading ?? _autoLeading(cs),
        title: Text(title, style: _titleStyle(context)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: _subtitleStyle(context))
            : null,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );

    return row;
  }

  // ─── Private helpers ────────────────────────────────────────

  Widget? _autoLeading(ColorScheme cs) {
    if (semantic == RowSemantic.normal) return null;
    return _semanticIcon(semantic);
  }

  static Widget _semanticIcon(RowSemantic semantic) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final (icon, color) = switch (semantic) {
        RowSemantic.success => (Icons.check_circle, cs.primary),
        RowSemantic.warning => (Icons.warning_amber, cs.tertiary),
        RowSemantic.error   => (Icons.cancel, cs.error),
        RowSemantic.muted   => (Icons.hourglass_empty, cs.onSurfaceVariant),
        RowSemantic.normal  => (Icons.circle_outlined, cs.onSurfaceVariant),
      };
      return Icon(icon, color: color, size: 22);
    });
  }

  /// Auto-detect color from well-known icon constants.
  static Color _iconAutoColor(IconData icon, ColorScheme cs) => switch (icon) {
    Icons.check_circle || Icons.check || Icons.verified => cs.primary,
    Icons.warning || Icons.warning_amber || Icons.hourglass_empty => cs.tertiary,
    Icons.cancel || Icons.error || Icons.block => cs.error,
    _ => cs.onSurfaceVariant,
  };

  Color? _semanticBg(ColorScheme cs) => switch (semantic) {
    RowSemantic.error   => cs.errorContainer.withOpacity(0.06),
    RowSemantic.warning => cs.tertiaryContainer.withOpacity(0.06),
    RowSemantic.success => cs.primaryContainer.withOpacity(0.04),
    RowSemantic.muted   => cs.surfaceContainerHighest.withOpacity(0.1),
    RowSemantic.normal  => null,
  };

  TextStyle? _titleStyle(BuildContext context) {
    final theme = Theme.of(context);
    if (semantic == RowSemantic.muted) {
      return theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return null; // default
  }

  TextStyle? _subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall;
  }
}

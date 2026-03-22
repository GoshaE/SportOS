import 'package:flutter/material.dart';

/// Type of placeholder content.
enum PlaceholderType {
  empty,    // No data yet — hint to create/add
  error,    // Something went wrong — offer retry
  loading,  // Loading state — spinner
  noResults,// Search returned nothing
}

/// AppPlaceholder: Universal placeholder for empty/error/loading states.
///
/// Replaces:
/// - `AppEmptyState` (icon + title + subtitle + action)
/// - `AppErrorWidget` (error message + retry button)
///
/// Usage:
/// ```dart
/// AppPlaceholder.empty(
///   icon: Icons.event,
///   title: 'Нет мероприятий',
///   subtitle: 'Создайте первое мероприятие',
///   actionLabel: 'Создать',
///   onAction: () {},
/// )
///
/// AppPlaceholder.error(
///   message: 'Не удалось загрузить',
///   onRetry: () {},
/// )
///
/// const AppPlaceholder.loading()
/// ```
class AppPlaceholder extends StatelessWidget {
  final PlaceholderType type;
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppPlaceholder({
    super.key,
    this.type = PlaceholderType.empty,
    this.icon,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Empty state with icon, title, and optional action.
  factory AppPlaceholder.empty({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppPlaceholder(
      key: key,
      type: PlaceholderType.empty,
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Error state with retry button.
  factory AppPlaceholder.error({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppPlaceholder(
      key: key,
      type: PlaceholderType.error,
      icon: Icons.error_outline,
      title: message ?? 'Что-то пошло не так',
      subtitle: 'Попробуйте ещё раз',
      actionLabel: onRetry != null ? 'Повторить' : null,
      onAction: onRetry,
    );
  }

  /// Loading state — centered spinner.
  const AppPlaceholder.loading({super.key})
      : type = PlaceholderType.loading,
        icon = null,
        title = null,
        subtitle = null,
        actionLabel = null,
        onAction = null;

  /// No search results.
  factory AppPlaceholder.noResults({Key? key, String query = ''}) {
    return AppPlaceholder(
      key: key,
      type: PlaceholderType.noResults,
      icon: Icons.search_off,
      title: 'Ничего не найдено',
      subtitle: query.isNotEmpty ? 'По запросу «$query»' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == PlaceholderType.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final iconColor = switch (type) {
      PlaceholderType.error => cs.error,
      _ => cs.onSurfaceVariant.withOpacity(0.4),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 64, color: iconColor),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

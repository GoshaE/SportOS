import 'package:flutter/material.dart';

/// AppInfoBanner: Colored informational banner for alerts, warnings, and status messages.
///
/// Usage:
/// ```dart
/// AppInfoBanner.warning(title: 'Нет VET', subtitle: 'Пройдите ветконтроль')
/// AppInfoBanner.success(title: 'Оплачено', subtitle: 'Квитанция подтверждена')
/// AppInfoBanner.error(title: 'Долг', subtitle: 'Оплатите 2000 руб.')
/// AppInfoBanner.info(title: 'Совет', subtitle: 'Привяжите Telegram')
/// ```
enum BannerType { info, success, warning, error }

class AppInfoBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final BannerType type;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onTap;

  const AppInfoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.type = BannerType.info,
    this.icon,
    this.action,
    this.onTap,
  });

  factory AppInfoBanner.info({Key? key, required String title, String? subtitle, Widget? action, VoidCallback? onTap}) =>
      AppInfoBanner(key: key, title: title, subtitle: subtitle, type: BannerType.info, icon: Icons.info_outline, action: action, onTap: onTap);

  factory AppInfoBanner.success({Key? key, required String title, String? subtitle, Widget? action, VoidCallback? onTap}) =>
      AppInfoBanner(key: key, title: title, subtitle: subtitle, type: BannerType.success, icon: Icons.check_circle_outline, action: action, onTap: onTap);

  factory AppInfoBanner.warning({Key? key, required String title, String? subtitle, Widget? action, VoidCallback? onTap}) =>
      AppInfoBanner(key: key, title: title, subtitle: subtitle, type: BannerType.warning, icon: Icons.warning_amber_rounded, action: action, onTap: onTap);

  factory AppInfoBanner.error({Key? key, required String title, String? subtitle, Widget? action, VoidCallback? onTap}) =>
      AppInfoBanner(key: key, title: title, subtitle: subtitle, type: BannerType.error, icon: Icons.error_outline, action: action, onTap: onTap);

  (Color bg, Color accent, Color border) _colors(ColorScheme cs) => switch (type) {
    BannerType.info    => (cs.primaryContainer.withValues(alpha: 0.3), cs.primary, cs.primary.withValues(alpha: 0.3)),
    BannerType.success => (cs.tertiaryContainer.withValues(alpha: 0.3), cs.tertiary, cs.tertiary.withValues(alpha: 0.3)),
    BannerType.warning => (cs.secondaryContainer.withValues(alpha: 0.3), cs.secondary, cs.secondary.withValues(alpha: 0.3)),
    BannerType.error   => (cs.errorContainer.withValues(alpha: 0.3), cs.error, cs.error.withValues(alpha: 0.3)),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, accent, borderColor) = _colors(cs);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600, color: accent,
                  )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent.withValues(alpha: 0.8),
                    )),
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

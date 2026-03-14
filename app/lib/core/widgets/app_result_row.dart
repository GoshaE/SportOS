import 'package:flutter/material.dart';

/// A row displaying a competition result: place/medal, name, time, optional details.
/// Used in event_detail, my_results, dog_detail, trainer, live_results screens.
class AppResultRow extends StatelessWidget {
  final int? place;
  final String? medal;
  final String name;
  final String time;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppResultRow({
    super.key,
    this.place,
    this.medal,
    required this.name,
    required this.time,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  String get _medal => medal ?? switch (place) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasMedal = _medal.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: hasMedal
                ? Text(_medal, style: const TextStyle(fontSize: 18))
                : Text(
                    '${place ?? '-'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: place == 1 ? cs.primary : null,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// AppStatCard: Mini stat card with a large value, label, and optional icon.
///
/// Replaces 6+ different ad-hoc implementations across team_screen,
/// participants_screen, club_profile/manage, vet_check, finances.
///
/// Usage:
/// ```dart
/// Row(children: [
///   AppStatCard(value: '48', label: 'Всего', color: cs.primary),
///   AppStatCard(value: '42', label: 'Online', color: cs.primary, icon: Icons.wifi),
/// ])
/// ```
class AppStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final IconData? icon;
  final bool expanded;

  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.icon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;

    final content = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: c, size: 20),
              const SizedBox(height: 4),
            ],
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: c,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}

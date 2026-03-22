import 'package:flutter/material.dart';
import 'package:sportos_app/core/theme/app_typography.dart';

/// AppTimelineRow: A single row in a chronological event schedule.
/// 
/// Enhanced to display a connected vertical timeline (nodes + lines).
/// Designed with solid colors and high contrast for outdoor readability,
/// avoiding thin faint lines that bleed out in sunlight.
class AppTimelineRow extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final bool isCurrent;
  final IconData? icon;

  const AppTimelineRow({
    super.key,
    required this.time,
    required this.title,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.isPast = false,
    this.isCurrent = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Determine colors based on status
    final dotColor = isCurrent 
        ? cs.primary 
        : (isPast ? cs.onSurfaceVariant : cs.surfaceContainerHighest);
    
    final lineColor = isPast || (isCurrent && !isLast)
        ? cs.primary.withOpacity(0.5) 
        : cs.surfaceContainerHighest;

    final textColor = isCurrent
        ? cs.onSurface
        : (isPast ? cs.onSurfaceVariant : cs.onSurface);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Time Column ──
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                time,
                style: AppTypography.monoTiming.copyWith(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Timeline Node & Line Column ──
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top line (omitted if first)
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : (isCurrent ? cs.primary.withOpacity(0.5) : lineColor),
                  ),
                ),
                // Node
                Container(
                  width: isCurrent ? 16 : 12,
                  height: isCurrent ? 16 : 12,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent 
                        ? Border.all(color: cs.primaryContainer, width: 4) 
                        : null,
                  ),
                ),
                // Bottom line (omitted if last)
                Expanded(
                  flex: 5,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Content Column ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 16,
                          color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

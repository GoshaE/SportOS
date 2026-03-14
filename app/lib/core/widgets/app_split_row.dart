import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// AppSplitRow: Split-time or lap row with time (monospace) and optional delta.
///
/// Replaces _splitRow in dictator_screen and time-delta patterns in protocol.
///
/// Usage:
/// ```dart
/// AppSplitRow(label: 'Круг 1', time: '00:12:45')
/// AppSplitRow(label: 'Круг 2', time: '00:12:30', delta: '-15с')
/// AppSplitRow(label: 'Круг 3', time: '00:12:57', delta: '+12с')
/// ```
class AppSplitRow extends StatelessWidget {
  final String label;
  final String time;
  final String? delta;
  final double labelWidth;

  const AppSplitRow({
    super.key,
    required this.label,
    required this.time,
    this.delta,
    this.labelWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final faster = delta != null && delta!.startsWith('-');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: labelWidth, child: Text(label, style: theme.textTheme.bodySmall)),
        Text(
          time,
          style: AppTypography.monoTiming.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (delta != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: (faster ? cs.primary : cs.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              delta!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: faster ? cs.primary : cs.error),
            ),
          ),
        ],
      ]),
    );
  }
}

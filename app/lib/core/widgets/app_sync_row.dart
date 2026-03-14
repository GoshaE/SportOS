import 'package:flutter/material.dart';

/// A sync/connection status row showing device name, status, and detail.
/// Used in ops_dashboard and ops_timing_hub for mesh network monitoring.
class AppSyncRow extends StatelessWidget {
  final String name;
  final String status;
  final String? detail;
  final Color color;

  const AppSyncRow({
    super.key,
    required this.name,
    required this.status,
    this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            status,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ]),
      ]),
    );
  }
}

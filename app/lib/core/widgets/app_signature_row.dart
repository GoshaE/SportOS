import 'package:flutter/material.dart';

/// AppSignatureRow: Displays a signature status for officials (judge, secretary).
///
/// Replaces _signRow in protocol_screen and _previewSignature.
///
/// Usage:
/// ```dart
/// AppSignatureRow(role: 'Главный судья', name: 'Иванов П.К.', signed: true)
/// AppSignatureRow(role: 'Секретарь', name: 'Смирнова А.А.', signed: false)
/// ```
class AppSignatureRow extends StatelessWidget {
  final String role;
  final String name;
  final bool signed;

  const AppSignatureRow({
    super.key,
    required this.role,
    required this.name,
    required this.signed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(children: [
      Icon(
        signed ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: signed ? cs.primary : cs.outline,
      ),
      const SizedBox(width: 6),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          Text(name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      )),
    ]);
  }
}

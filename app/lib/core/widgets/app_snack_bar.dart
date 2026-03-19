import 'package:flutter/material.dart';

/// AppSnackBar: Semantic snackbar helper replacing 84 inline ScaffoldMessenger calls.
///
/// Usage:
/// ```dart
/// AppSnackBar.success(context, 'Сохранено!')
/// AppSnackBar.error(context, 'Ошибка сети')
/// AppSnackBar.info(context, 'Код отправлен на email')
/// AppSnackBar.warning(context, 'Слабое соединение')
/// ```
class AppSnackBar {
  static void success(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    _show(context, message, Icons.check_circle, cs.primary);
  }

  static void error(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    _show(context, message, Icons.error_outline, cs.error);
  }

  static void info(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    _show(context, message, Icons.info_outline, cs.tertiary);
  }

  static void warning(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    _show(context, message, Icons.warning_amber_rounded, cs.secondary);
  }

  /// Show a snackbar with an undo action.
  static void withUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(label: 'Отменить', onPressed: onUndo),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
}

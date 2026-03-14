import 'dart:ui';
import 'package:flutter/material.dart';

/// AppDialog: Standardized dialog patterns for the entire app.
///
/// Usage:
/// ```dart
/// AppDialog.confirm(context, title: 'Удалить?', message: '...', onConfirm: () => ...)
/// AppDialog.info(context, title: 'Готово', message: 'Данные сохранены')
/// AppDialog.custom(context, title: 'Выбор', child: Column(...), actions: [...])
/// ```
class AppDialog {
  /// Simple informational dialog with OK button.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1),
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm/cancel dialog with destructive option.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    bool isDanger = false,
    VoidCallback? onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1),
            ),
            title: Text(title),
            content: message != null ? Text(message) : null,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(cancelText),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx, true);
                  onConfirm?.call();
                },
                style: isDanger
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                child: Text(confirmText),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Custom dialog with arbitrary child and actions.
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool scrollable = false,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1),
            ),
            title: Text(title),
            content: scrollable
                ? SingleChildScrollView(child: child)
                : child,
            actions: actions ??
                [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Закрыть'),
                  ),
                ],
            scrollable: false, // We handle scrolling ourselves if needed
          ),
        ),
      ),
    );
  }

  /// Dialog with text input — returns entered text or null.
  static Future<String?> input(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String hint = '',
    String confirmText = 'Сохранить',
    String cancelText = 'Отмена',
    String? Function(String?)? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1),
            ),
            title: Text(title),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message != null) ...[
                    Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: controller,
                    validator: validator,
                    autofocus: true,
                    decoration: InputDecoration(hintText: hint),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(cancelText),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? true) {
                    Navigator.pop(ctx, controller.text);
                  }
                },
                child: Text(confirmText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'app_dialog.dart';

/// Persistent orange banner shown at the top of every Ops-mode screen.
/// Provides a clear visual indicator of "Work Mode" and a one-tap exit,
/// while taking up minimal vertical space (~28px).
class OpsContextBanner extends StatelessWidget {
  final String eventName;

  const OpsContextBanner({super.key, this.eventName = 'Чемпионат Урала 2026'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // We use AnnotatedRegion to color the system status bar
    // to give a strong visual cue without taking up app space.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: cs.errorContainer, // Ops mode status bar
        statusBarIconBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light, 
      ),
      child: Container(
        width: double.infinity,
        // Minimal padding to save vertical space
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(Icons.work, color: cs.onErrorContainer, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'РЕЖИМ СУДЬИ  •  $eventName',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Compact exit button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showExitDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.onErrorContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 12, color: cs.onErrorContainer),
                        const SizedBox(width: 4),
                        Text(
                          'ВЫХОД',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    AppDialog.confirm(
      context,
      title: 'Завершить смену?',
      message: 'Вы вернётесь в обычный режим участника.',
      confirmText: 'Выйти',
      cancelText: 'Остаться',
      isDanger: true,
      onConfirm: () => context.go('/hub'),
    );
  }
}


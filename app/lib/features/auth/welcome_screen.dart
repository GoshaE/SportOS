import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';

/// Screen ID: A1 — Welcome
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_score, size: 80, color: cs.primary),
              const SizedBox(height: 24),
              Text('SportOS', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: cs.primary)),
              const SizedBox(height: 8),
              Text('Система спортивного хронометража', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 48),
              AppButton.primary(text: 'Войти через Telegram', icon: Icons.send, onPressed: () => context.go('/login')),
              const SizedBox(height: 16),
              AppButton.secondary(text: 'Продолжить как гость → Хаб', onPressed: () => context.go('/hub')),
            ],
          ),
        ),
      ),
    );
  }
}

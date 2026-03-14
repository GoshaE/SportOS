import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.send),
                label: const Text('Войти через Telegram'),
              )),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
                onPressed: () => context.go('/hub'),
                child: const Text('Продолжить как гость → Хаб'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: W6 — Забыл пароль
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Восстановление пароля')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_sent ? Icons.mark_email_read : Icons.lock_reset, size: 64, color: _sent ? cs.primary : cs.secondary),
            const SizedBox(height: 16),
            Text(_sent ? 'Ссылка отправлена!' : 'Введите email', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _sent ? 'Проверьте вашу почту и перейдите по ссылке для сброса пароля. Ссылка действительна 1 час.'
                    : 'Мы отправим ссылку для сброса пароля на ваш email.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!_sent) ...[
              const TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => setState(() => _sent = true), child: const Text('Отправить ссылку'))),
            ],
            if (_sent) ...[
              SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Вернуться к входу'))),
              const SizedBox(height: 8),
              TextButton(onPressed: () => AppSnackBar.success(context, 'Ссылка отправлена повторно'), child: const Text('Отправить повторно', style: TextStyle(fontSize: 13))),
            ],
            const SizedBox(height: 16),
            TextButton(onPressed: () => context.go('/login'), child: const Text('← Назад к входу')),
          ]),
        ),
      ),
    );
  }
}

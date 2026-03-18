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
              AppTextField(label: 'Email', hintText: 'example@mail.com', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              AppButton.primary(text: 'Отправить ссылку', onPressed: () => setState(() => _sent = true)),
            ],
            if (_sent) ...[
              AppButton.primary(text: 'Вернуться к входу', onPressed: () => context.go('/login')),
              const SizedBox(height: 8),
              AppButton.text(text: 'Отправить повторно', onPressed: () => AppSnackBar.success(context, 'Ссылка отправлена повторно')),
            ],
            const SizedBox(height: 16),
            AppButton.text(text: '← Назад к входу', onPressed: () => context.go('/login')),
          ]),
        ),
      ),
    );
  }
}

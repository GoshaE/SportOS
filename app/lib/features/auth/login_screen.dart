import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: W2 — Вход (с OAuth)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: Text(_isLogin ? 'Вход' : 'Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          AppButton.secondary(text: 'Войти через Google', icon: Icons.g_mobiledata, onPressed: () => context.go('/hub')),
          const SizedBox(height: 10),
          AppButton.secondary(text: 'Войти через Apple', icon: Icons.apple, onPressed: () => context.go('/hub')),
          const SizedBox(height: 10),
          AppButton.secondary(text: 'Войти через VK ID', onPressed: () => context.go('/hub')),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Divider(color: cs.outlineVariant)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
            Expanded(child: Divider(color: cs.outlineVariant)),
          ]),
          const SizedBox(height: 20),
          AppTextField(label: 'Email', hintText: 'example@mail.com', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          AppTextField(label: 'Пароль', hintText: '••••••••', prefixIcon: Icons.lock, obscureText: true),
          if (!_isLogin) ...[
            const SizedBox(height: 12),
            AppTextField(label: 'Имя и фамилия', hintText: 'Иван Иванов', prefixIcon: Icons.person),
            const SizedBox(height: 12),
            AppTextField(label: 'Повторите пароль', hintText: '••••••••', prefixIcon: Icons.lock_outline, obscureText: true),
            const SizedBox(height: 12),
            AppCheckbox(label: 'Я согласен с обработкой персональных данных и условиями использования', value: true, onChanged: (_) {}),
          ],
          if (_isLogin) Align(alignment: Alignment.centerRight, child: AppButton.text(
            text: 'Забыли пароль?',
            onPressed: () => context.go('/forgot-password'),
          )),
          const SizedBox(height: 12),
          AppButton.primary(text: _isLogin ? 'Войти' : 'Создать аккаунт', onPressed: () => _isLogin ? context.go('/hub') : _showSuccess()),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_isLogin ? 'Нет аккаунта?' : 'Уже есть аккаунт?', style: const TextStyle(fontSize: 13)),
            AppButton.text(text: _isLogin ? 'Создать' : 'Войти', onPressed: () => setState(() => _isLogin = !_isLogin)),
          ]),
          const SizedBox(height: 8),
          AppButton.text(text: '← Назад', onPressed: () => context.go('/welcome')),
        ]),
      ),
    );
  }

  void _showSuccess() {
    AppDialog.custom(context, title: 'Аккаунт создан!',
      child: const Text('Проверьте email для подтверждения. Вы можете начать использовать SportOS прямо сейчас.'),
      actions: [AppButton.small(text: 'Начать', onPressed: () { Navigator.of(context, rootNavigator: true).pop(); context.go('/hub'); })],
    );
  }
}

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
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
            onPressed: () => context.go('/hub'),
            icon: Icon(Icons.g_mobiledata, color: cs.error, size: 24),
            label: const Text('Войти через Google'),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
            onPressed: () => context.go('/hub'),
            icon: const Icon(Icons.apple, size: 22),
            label: const Text('Войти через Apple'),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
            onPressed: () => context.go('/hub'),
            icon: Text('VK', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16)),
            label: const Text('Войти через VK ID'),
          )),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Divider(color: cs.outlineVariant)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
            Expanded(child: Divider(color: cs.outlineVariant)),
          ]),
          const SizedBox(height: 20),
          const TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(), suffixIcon: Icon(Icons.visibility_off)), obscureText: true),
          if (!_isLogin) ...[
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Имя и фамилия', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Повторите пароль', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: true, onChanged: (_) {}),
              const Expanded(child: Text('Я согласен с обработкой персональных данных и условиями использования', style: TextStyle(fontSize: 12))),
            ]),
          ],
          if (_isLogin) Align(alignment: Alignment.centerRight, child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text('Забыли пароль?', style: TextStyle(fontSize: 13)),
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: FilledButton(
            onPressed: () => _isLogin ? context.go('/hub') : _showSuccess(),
            child: Text(_isLogin ? 'Войти' : 'Создать аккаунт'),
          )),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_isLogin ? 'Нет аккаунта?' : 'Уже есть аккаунт?', style: const TextStyle(fontSize: 13)),
            TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Создать' : 'Войти', style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.go('/welcome'), child: const Text('← Назад', style: TextStyle(fontSize: 13))),
        ]),
      ),
    );
  }

  void _showSuccess() {
    AppDialog.custom(context, title: 'Аккаунт создан!',
      child: const Text('Проверьте email для подтверждения. Вы можете начать использовать SportOS прямо сейчас.'),
      actions: [FilledButton(onPressed: () { Navigator.of(context, rootNavigator: true).pop(); context.go('/hub'); }, child: const Text('Начать'))],
    );
  }
}

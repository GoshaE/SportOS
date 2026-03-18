import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

/// Screen ID: A3 — Подтверждение OTP
class OtpVerifyScreen extends StatelessWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: const Text('📱 Подтверждение')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Введите код из Telegram', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Код подтверждения',
                hintText: '000000',
                prefixIcon: Icons.lock,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              AppButton.primary(text: 'Подтвердить → Хаб', onPressed: () => context.go('/hub')),
              const SizedBox(height: 16),
              AppButton.text(text: '← Назад к вводу номера', onPressed: () => context.go('/login')),
            ],
          ),
        ),
      ),
    );
  }
}

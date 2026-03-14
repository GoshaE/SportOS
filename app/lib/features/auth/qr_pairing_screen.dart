import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: QR — QR Pairing для волонтёра/маршала
class QrPairingScreen extends StatelessWidget {
  const QrPairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('QR Pairing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.qr_code_scanner, size: 80, color: cs.primary),
            const SizedBox(height: 24),
            const Text('Отсканируйте QR-код', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Секретарь покажет QR-код на своём устройстве.\nОтсканируйте его для получения роли.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            OutlinedButton(onPressed: () => context.go('/profile'), child: const Text('← Назад к профилю')),
          ]),
        ),
      ),
    );
  }
}

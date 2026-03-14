import 'package:flutter/material.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E-Shell
class EventManageShell extends StatelessWidget {
  const EventManageShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: const Text('Управление')),
      body: const Center(
        child: Text(
          'Управление\n[E-Shell]',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

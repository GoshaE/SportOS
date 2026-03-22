import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_colors.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR4 — Мои дипломы (с предпросмотром)
class MyDiplomasScreen extends StatefulWidget {
  const MyDiplomasScreen({super.key});

  @override
  State<MyDiplomasScreen> createState() => _MyDiplomasScreenState();
}

class _MyDiplomasScreenState extends State<MyDiplomasScreen> {
  String _sort = 'date';

  final _diplomas = [
    {'place': '1', 'emoji': '🥇', 'event': 'Чемпионат Урала 2026', 'disc': 'Скиджоринг 5км', 'date': '15.03.2026', 'time': '38:12', 'type': BadgeType.warning},
    {'place': '2', 'emoji': '🥈', 'event': 'Кубок Сибири 2025', 'disc': 'Скиджоринг 10км', 'date': '20.12.2025', 'time': '1:12:45', 'type': BadgeType.neutral},
    {'place': '3', 'emoji': '🥉', 'event': 'Кубок Урала 2025', 'disc': 'Каникросс 3км', 'date': '20.10.2025', 'time': '18:05', 'type': BadgeType.neutral},
    {'place': '4', 'emoji': '📜', 'event': 'Кубок Москвы', 'disc': 'Скиджоринг 5км', 'date': '15.11.2025', 'time': '42:30', 'type': BadgeType.info},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Мои дипломы'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'date', checked: _sort == 'date', child: const Text('По дате')),
              CheckedPopupMenuItem(value: 'place', checked: _sort == 'place', child: const Text('По месту')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _diplomas.length,
        itemBuilder: (_, i) {
          final d = _diplomas[i];
          final place = d['place'] as String;
          Color medalColor = Theme.of(context).colorScheme.surfaceContainerHighest;
          if (place == '1') medalColor = AppColors.gold.withOpacity(0.2);
          if (place == '2') medalColor = AppColors.silver.withOpacity(0.2);
          if (place == '3') medalColor = AppColors.bronze.withOpacity(0.2);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AppCard(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: medalColor, borderRadius: BorderRadius.circular(12)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(d['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      Text('${d['place']} м.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  title: Text(d['event'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('${d['disc']} · ${d['time']}\n${d['date']}', style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf, color: cs.error, size: 24),
                      tooltip: 'PDF',
                      onPressed: () => AppSnackBar.info(context, 'Скачивание PDF...'),
                    ),
                    IconButton(icon: const Icon(Icons.share, size: 24), tooltip: 'Поделиться', onPressed: () {}),
                  ]),
                  onTap: () => _showPreview(d),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPreview(Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final place = d['place'] as String;
    Color medalColor = cs.tertiary;
    if (place == '1') medalColor = AppColors.gold;
    if (place == '2') medalColor = AppColors.silver;
    if (place == '3') medalColor = AppColors.bronze;

    AppDialog.custom(
      context,
      title: '', // Custom header inside
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Certificate representation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: medalColor.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.workspace_premium, size: 56, color: medalColor),
              const SizedBox(height: 12),
              Text('ДИПЛОМ', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 4, color: medalColor)),
              const SizedBox(height: 16),
              Text(d['event'] as String, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const Divider(height: 32),
              Text('${d['emoji']} ${d['place']} МЕСТО', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 16),
              Text('Иванов Александр', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${d['disc']} · ${d['time']}', style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(d['date'] as String, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: AppButton.secondary(text: 'PDF', icon: Icons.picture_as_pdf, onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: AppButton.primary(text: 'Поделиться', icon: Icons.share, onPressed: () {})),
        ]),
      ]),
      actions: [
        AppButton.text(text: 'Закрыть', onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
      ],
    );
  }
}

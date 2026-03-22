import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: RS4 — Генерация дипломов
class DiplomaGenScreen extends StatelessWidget {
  const DiplomaGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Генерация дипломов'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), tooltip: 'Шаблон', onPressed: () => context.push('/manage/$eventId/documents')),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          backgroundColor: cs.tertiaryContainer.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, size: 48, color: cs.tertiary),
                const SizedBox(height: 12),
                Text('ДИПЛОМ', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 4, color: cs.primary)),
                const SizedBox(height: 8),
                Text('Чемпионат Урала 2026', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Text(
                    '{ФИО}  ·  {Дисциплина}  ·  {Место}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontFamily: 'Courier'),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Настройки генерации ──
        AppSectionHeader(title: 'Настройки', icon: Icons.tune),
        const SizedBox(height: 4),
        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            AppSelect<String>(
              label: 'Дисциплина',
              value: 'Все дисциплины',
              items: ['Все дисциплины', 'Скиджоринг 5км', 'Скиджоринг 10км', 'Каникросс 3км', 'Нарты 15км'].map((e) => SelectItem(value: e, label: e)).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            AppSelect<String>(
              label: 'Кому генерировать',
              value: 'Топ-3',
              items: ['Топ-3', 'Топ-5', 'Топ-10', 'Все финишировавшие', 'Все участники'].map((e) => SelectItem(value: e, label: e)).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Кнопки генерации ──
        AppButton.primary(
          text: 'Сгенерировать все дипломы',
          icon: Icons.auto_awesome,
          onPressed: () => AppSnackBar.success(context, 'Массовая генерация: 15 дипломов создано'),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: AppButton.secondary(text: 'Скачать PDF', icon: Icons.picture_as_pdf, onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: AppButton.secondary(text: 'Email', icon: Icons.email, onPressed: () {})),
        ]),
        const SizedBox(height: 20),

        // ── Предпросмотр ──
        AppSectionHeader(title: 'Предпросмотр', icon: Icons.preview),
        const SizedBox(height: 4),
        _diplomaRow(context, '🥇', '1', 'Петров А.А.', 'Скидж. 5км · 38:12', true),
        _diplomaRow(context, '🥈', '2', 'Иванов В.В.', 'Скидж. 5км · 39:45', true),
        _diplomaRow(context, '🥉', '3', 'Волков Е.Е.', 'Скидж. 5км · 41:02', false),
        _diplomaRow(context, '🥇', '1', 'Козлов Г.Г.', 'Каникросс · 15:30', false),
        _diplomaRow(context, '🥈', '2', 'Новиков З.З.', 'Каникросс · 16:45', false),
        const SizedBox(height: 12),
        AppButton.secondary(text: '← Протоколы', icon: Icons.description, onPressed: () => context.push('/results/$eventId/protocol')),
      ]),
    );
  }

  Widget _diplomaRow(BuildContext context, String emoji, String place, String name, String detail, bool generated) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AppCard(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            dense: true,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            title: Text('$place место — $name', style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
            trailing: generated
              ? Icon(Icons.check_circle, color: cs.primary, size: 24)
              : AppButton.secondary(text: 'Создать', onPressed: () {}),
          ),
        ],
      ),
    );
  }
}

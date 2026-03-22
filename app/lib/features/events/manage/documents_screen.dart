import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/event/config_providers.dart';

/// Screen ID: E6 — Документы
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(eventConfigProvider);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Документы')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Обязательные документы', cs),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                _docTile(cs, 'Waiver (отказ от претензий)', 'Загружен · PDF · 245 КБ', true, Icons.description),
                const Divider(height: 1, indent: 16),
                _docTile(cs, 'Соглашение ПД', 'Загружен · PDF · 128 КБ', true, Icons.security),
                const Divider(height: 1, indent: 16),
                _docTile(cs, 'Регламент', 'Не загружен', false, Icons.rule),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        _sectionTitle('Награждение', cs),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                _docTile(cs, 'Шаблон диплома', 'Настроен', true, Icons.workspace_premium),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Предпросмотр диплома', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, height: 200,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.3),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium, size: 48, color: cs.primary),
                              const SizedBox(height: 12),
                              Text('ДИПЛОМ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: cs.onSurface)),
                              Text(config.name, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              Text('{ФИО} · {Дисциплина} · {Место}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500)),
                            ]
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton.secondary(text: 'Редактировать шаблон', icon: Icons.edit, onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }

  Widget _docTile(ColorScheme cs, String title, String subtitle, bool loaded, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: loaded ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: loaded ? cs.primary : cs.onSurfaceVariant, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: loaded ? cs.onSurfaceVariant : cs.error)),
      trailing: loaded 
        ? Icon(Icons.check_circle, color: cs.primary) 
        : AppButton.small(text: 'Загрузить', onPressed: () {}),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sportos_app/ui/molecules/app_list_row.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR-DOCS — Документы профиля
class ProfileDocumentsScreen extends StatefulWidget {
  const ProfileDocumentsScreen({super.key});

  @override
  State<ProfileDocumentsScreen> createState() => _ProfileDocumentsScreenState();
}

class _ProfileDocumentsScreenState extends State<ProfileDocumentsScreen> {
  final List<Map<String, dynamic>> _documents = [
    {'title': 'Спортивная страховка', 'type': 'insurance', 'expiry': '15.12.2026', 'status': 'Активен', 'ok': true},
    {'title': 'Медицинская справка', 'type': 'medical', 'expiry': '01.05.2026', 'status': 'Активен', 'ok': true},
    {'title': 'Согласие родителей', 'type': 'consent', 'expiry': '—', 'status': 'Не загружен', 'ok': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: const Text('Мои документы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Загрузить'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppInfoBanner.info(
            title: 'Автоматическая проверка',
            subtitle: 'Загрузите документы один раз — они будут автоматически прикреплены при заявке на мероприятия',
          ),
          const SizedBox(height: 16),
          ..._documents.map(_buildDocCard),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final theme = Theme.of(context);
    final bool hasFile = doc['ok'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: AppAvatar(
          name: doc['title'],
          size: 44,
        ),
        title: Text(doc['title'], style: theme.textTheme.titleSmall),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          AppListRow.detail(label: 'Действует до', value: doc['expiry'], icon: Icons.event),
          const SizedBox(height: 2),
          StatusBadge(
            text: doc['status'],
            type: hasFile ? BadgeType.success : BadgeType.neutral,
          ),
        ]),
        trailing: hasFile
            ? PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('Просмотреть')),
                  const PopupMenuItem(value: 'replace', child: Text('Обновить')),
                  PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ],
                onSelected: (val) {
                  if (val == 'delete') {
                    setState(() {
                      doc['status'] = 'Не загружен';
                      doc['ok'] = false;
                      doc['expiry'] = '—';
                    });
                  }
                },
              )
            : AppButton.text(text: 'Загрузить', onPressed: _showUpload),
        isThreeLine: true,
      ),
    );
  }


  void _showUpload() {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Загрузка документа',
      initialHeight: 0.55,
      child: Column(children: [
        AppSelect<String>(
          label: 'Тип документа',
          items: const [
            SelectItem(value: 'insurance', label: 'Спортивная страховка'),
            SelectItem(value: 'medical', label: 'Медицинская справка'),
            SelectItem(value: 'consent', label: 'Согласие родителей'),
            SelectItem(value: 'other', label: 'Иное'),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        const AppTextField(label: 'Действует до (ДД.ММ.ГГГГ)', prefixIcon: Icons.calendar_today),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Документ загружен и отправлен на проверку');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Icon(Icons.cloud_upload, size: 48, color: cs.primary),
              const SizedBox(height: 8),
              Text('Нажмите, чтобы выбрать файл\nили сделать фото',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('PDF, JPG, PNG (до 5 МБ)', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ]),
    );
  }
}

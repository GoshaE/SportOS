import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E3 — Участники (с E3.1 карточка заявки, E3.2 добавить вручную)
class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  bool _isTableView = false; // By default depends on screen width, but we can toggle
  bool _initialized = false;

  void _showApplicationCard(BuildContext context, ColorScheme cs, String bib, String name, String disc, String dog, String status, String payment) {
    final isPaid = payment == '✅';
    final isApproved = status == '✅';
    
    final map = {
      'name': name,
      'club': 'Собака: $dog • Дисциплина: $disc',
      'role': 'competitor',
      'bib': bib,
    };
    
    AppUserProfileSheet.show(
      context,
      user: map,
      isOrganizer: true,
      contextActionsBuilder: (innerCtx) => [
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.check_circle, size: 20, color: cs.primary)),
          title: const Text('Статус заявки', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isApproved ? 'Подтверждена' : 'Ожидает подтверждения', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (!isApproved) AppSnackBar.success(context, '$name — заявка подтверждена');
          },
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle), child: Icon(Icons.payment, size: 20, color: cs.secondary)),
          title: const Text('Оплата', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isPaid ? 'Оплачено (2 500 ₽)' : 'Не оплачено', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (!isPaid) AppSnackBar.success(context, 'Напоминание об оплате отправлено');
          },
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.tertiaryContainer, shape: BoxShape.circle), child: Icon(Icons.confirmation_number, size: 20, color: cs.tertiary)),
          title: const Text('Стартовый номер', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(bib, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Configure bib logic
          },
        ),
      ],
    );
  }

  void _showAddParticipant(BuildContext context) {
    AppBottomSheet.show(context, title: 'Добавить участника', actions: [
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.success(context, 'Участник добавлен'); },
        child: const Text('Добавить', style: TextStyle(fontSize: 16)),
      )),
    ], child: Column(mainAxisSize: MainAxisSize.min, children: [
      const TextField(decoration: InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      const TextField(decoration: InputDecoration(labelText: 'Телефон / Email', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField(decoration: const InputDecoration(labelText: 'Дисциплина *', border: OutlineInputBorder()), items: const [
        DropdownMenuItem(value: 's5', child: Text('Скиджоринг 5км')),
        DropdownMenuItem(value: 's10', child: Text('Скиджоринг 10км')),
        DropdownMenuItem(value: 'c3', child: Text('Каникросс 3км')),
        DropdownMenuItem(value: 'n15', child: Text('Нарты 15км')),
      ], onChanged: (_) {}),
      const SizedBox(height: 12),
      const TextField(decoration: InputDecoration(labelText: 'Кличка собаки', border: OutlineInputBorder())),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final w = MediaQuery.of(context).size.width;

    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }

    final data = [
      ['07', 'Петров А.А.', 'Скидж. 5км', 'Rex', '✅', '✅'],
      ['12', 'Сидоров Б.Б.', 'Скидж. 5км', 'Luna', '✅', '✅'],
      ['24', 'Иванов В.В.', 'Скидж. 10км', 'Storm', '✅', '✅'],
      ['31', 'Козлов Г.Г.', 'Нарты 15км', 'Wolf', '✅', '❌'],
      ['42', 'Морозов Д.Д.', 'Каникросс', 'Buddy', '⏳', '✅'],
      ['55', 'Волков Е.Е.', 'Скидж. 5км', 'Alaska', '✅', '✅'],
      ['63', 'Лебедев Ж.Ж.', 'Нарты 15км', 'Max', '⏳', '❌'],
      ['77', 'Новиков З.З.', 'Каникросс', 'Rocky', '✅', '✅'],
    ];


    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Участники'),
        actions: [
          IconButton(icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows), tooltip: 'Вид таблицы', onPressed: () => setState(() => _isTableView = !_isTableView)),
          IconButton(icon: const Icon(Icons.person_add), tooltip: 'Добавить вручную', onPressed: () => _showAddParticipant(context)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        AppInfoPanel(
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          children: [
            AppInfoPanel.stat('48', 'Всего', cs.onSurface),
            AppInfoPanel.stat('42', 'Подтв.', cs.primary),
            AppInfoPanel.stat('3', 'Ожидает', cs.tertiary),
            AppInfoPanel.stat('3', 'Не опл.', cs.error),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Все'), selected: true, onSelected: (_) {}),
            FilterChip(label: const Text('Скиджоринг'), selected: false, onSelected: (_) {}),
            FilterChip(label: const Text('Каникросс'), selected: false, onSelected: (_) {}),
            FilterChip(label: const Text('Нарты'), selected: false, onSelected: (_) {}),
          ]),
        ),
        Expanded(
          child: AppProtocolTable(
            forceTableView: _isTableView,
            headerRow: const _ParticipantRow(isHeader: true, data: []),
            itemCount: data.length,
            itemBuilder: (context, index, isCard) {
              final d = data[index];
              return _ParticipantRow(
                isCardView: isCard,
                data: d,
                onTap: () => _showApplicationCard(context, cs, d[0], d[1], d[2], d[3], d[4], d[5]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final List<String> data;
  final bool isHeader;
  final bool isCardView;
  final VoidCallback? onTap;

  const _ParticipantRow({
    required this.data,
    this.isHeader = false,
    this.isCardView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isHeader) {
      if (isCardView) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 50, child: _headerText('BIB', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 200, child: _headerText('ФИО', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: _headerText('Дисциплина', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: _headerText('Собака', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: _headerText('Оплата', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: _headerText('Статус', theme, cs)),
          ],
        ),
      );
    }

    final bib = data[0];
    final name = data[1];
    final cat = data[2];
    final dog = data[3];
    final status = data[4];
    final payment = data[5];
    final isApproved = status == '✅';
    final isPaid = payment == '✅';

    Widget content;
    if (isCardView) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
                  child: Center(child: Text(bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                  child: Text(cat, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.pets, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(dog, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                _statusBadge(cs, isPaid ? 'Оплачено' : 'Не оплачено', isPaid ? cs.primary : cs.error),
                const SizedBox(width: 8),
                _statusBadge(cs, isApproved ? 'Подтвержден' : 'Ожидает', isApproved ? cs.primary : cs.tertiary),
              ],
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 50, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: Text(bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            )),
            const SizedBox(width: 16),
            SizedBox(width: 200, child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: Container(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                child: Text(cat, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            )),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: Text(dog, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(cs, isPaid ? 'Оплачено' : 'Не оплачено', isPaid ? cs.primary : cs.error))),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(cs, isApproved ? 'Подтвержден' : 'Ожидает', isApproved ? cs.primary : cs.tertiary))),
          ],
        ),
      );
    }

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _headerText(String text, ThemeData theme, ColorScheme cs) {
    return Text(text, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 0.5));
  }

  Widget _statusBadge(ColorScheme cs, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

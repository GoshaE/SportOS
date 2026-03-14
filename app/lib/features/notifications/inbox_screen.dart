import 'package:flutter/material.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';


/// Screen ID: N1 — Уведомления (Inbox)
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _filter = 'Все';

  final _items = <Map<String, dynamic>>[
    {'icon': Icons.emoji_events, 'title': 'Результат: 3 место!', 'sub': 'Ночная гонка · Скиджоринг 6км · 23:15', 'time': '2 мин', 'read': false, 'cat': 'Мероприятия'},
    {'icon': Icons.assignment, 'title': 'Стартовый лист опубликован', 'sub': 'Чемпионат Урала 2026 · BIB 42 · Старт 10:15', 'time': '1 час', 'read': false, 'cat': 'Мероприятия'},
    {'icon': Icons.pets, 'title': 'Ветконтроль Rex', 'sub': 'Ночная гонка · Допущен', 'time': '3 часа', 'read': true, 'cat': 'Мероприятия'},
    {'icon': Icons.groups, 'title': 'Заявка в клуб принята', 'sub': '«Быстрые лапы» — добро пожаловать!', 'time': '1 день', 'read': true, 'cat': 'Клубы'},
    {'icon': Icons.payments, 'title': 'Напоминание: членский взнос', 'sub': '«Быстрые лапы» · 3 000₽ до 31.03', 'time': '2 дня', 'read': false, 'cat': 'Клубы'},
    {'icon': Icons.person_add, 'title': 'Заявка на тренерство', 'sub': 'Козлов Андрей хочет стать воспитанником', 'time': '3 дня', 'read': true, 'cat': 'Система'},
    {'icon': Icons.link, 'title': 'Найден ваш результат', 'sub': 'Лесная гонка 2025 — возможно это вы (BIB 15)', 'time': '5 дней', 'read': true, 'cat': 'Система'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = _items.where((i) => !(i['read'] as bool)).length;
    final filtered = _filter == 'Все' ? _items : _items.where((i) => i['cat'] == _filter).toList();

    return Scaffold(
      appBar: AppAppBar(
        title: Row(children: [
          const Text('Уведомления'),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(10)),
              child: Text('$unread', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onError, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => setState(() { for (var i in _items) { i['read'] = true; } }), child: Text('Прочитать все', style: Theme.of(context).textTheme.labelMedium)),
        ],
      ),
      body: Column(children: [
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          _chip(context, cs, 'Все'), _chip(context, cs, 'Мероприятия'), _chip(context, cs, 'Клубы'), _chip(context, cs, 'Система'),
        ])),
        const Divider(height: 1),
        Expanded(child: filtered.isEmpty
          ? Center(child: Text('Нет уведомлений', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
              itemBuilder: (ctx, i) {
                final n = filtered[i];
                final bool read = n['read'] as bool;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: cs.primaryContainer.withValues(alpha: 0.4), child: Icon(n['icon'] as IconData, color: cs.primary, size: 20)),
                  title: Text(n['title'] as String, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(n['sub'] as String, style: Theme.of(context).textTheme.bodySmall),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(n['time'] as String, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    if (!read) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                  ]),
                  onTap: () => setState(() => n['read'] = true),
                );
              },
            ),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext context, ColorScheme cs, String label) {
    final sel = _filter == label;
    return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
      label: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: sel ? cs.onPrimary : null)),
      selected: sel, onSelected: (_) => setState(() => _filter = label),
    ));
  }
}

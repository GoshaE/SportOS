import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: P5 — Мандатная комиссия
class MandateScreen extends StatelessWidget {
  const MandateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Мандатная комиссия'), actions: [
        Badge(label: const Text('2'), child: IconButton(icon: Icon(Icons.warning, color: cs.tertiary), onPressed: () {})),
      ]),
      body: Column(children: [
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('30', 'Допущены', cs.primary),
            _stat('12', 'Ожидают', cs.tertiary),
            _stat('2', 'Отказ', cs.error),
            _stat('44', 'Всего', cs.onSurface),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(8), child: TextField(decoration: InputDecoration(
          hintText: 'Поиск по BIB, ФИО...', prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ))),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
          _mandateCard(context, cs, 'BIB 07 Петров А.А.', [_checkItem('Паспорт / удостоверение личности', true), _checkItem('Медицинская справка', true), _checkItem('Страховка', true), _checkItem('Лицензия федерации', true), _checkItem('Согласие на обработку ПД', true)], 'passed'),
          _mandateCard(context, cs, 'BIB 24 Иванов В.В.', [_checkItem('Паспорт / удостоверение личности', true), _checkItem('Медицинская справка', false), _checkItem('Страховка', true), _checkItem('Лицензия федерации', true), _checkItem('Согласие на обработку ПД', true)], 'incomplete'),
          _mandateCard(context, cs, 'BIB 31 Козлов Г.Г.', [_checkItem('Паспорт / удостоверение личности', true), _checkItem('Медицинская справка', true), _checkItem('Страховка', false), _checkItem('Лицензия федерации', false), _checkItem('Согласие на обработку ПД', true)], 'failed'),
          _mandateCard(context, cs, 'BIB 42 Морозов Д.Д.', [_checkItem('Паспорт / удостоверение личности', false), _checkItem('Медицинская справка', false), _checkItem('Страховка', false), _checkItem('Лицензия федерации', false), _checkItem('Согласие на обработку ПД', false)], 'pending'),
        ])),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 11, color: color)),
  ]);

  Widget _mandateCard(BuildContext context, ColorScheme cs, String name, List<Widget> checks, String status) {
    final color = status == 'passed' ? cs.primary : status == 'incomplete' ? cs.tertiary : status == 'failed' ? cs.error : cs.onSurfaceVariant;
    final icon = status == 'passed' ? Icons.check_circle : status == 'incomplete' ? Icons.warning : status == 'failed' ? Icons.cancel : Icons.hourglass_empty;
    return Card(
      shape: RoundedRectangleBorder(side: BorderSide(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status == 'passed' ? 'Все документы OK' : status == 'incomplete' ? 'Не все документы' : status == 'failed' ? 'Отказ' : 'Ожидает проверки'),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: checks)),
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () => AppSnackBar.success(context, '$name — допущен'),
              icon: const Icon(Icons.check), label: const Text('Допустить'),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: cs.error),
              onPressed: () => AppSnackBar.error(context, '$name — не допущен'),
              icon: const Icon(Icons.close), label: const Text('Отказать'),
            )),
          ])),
        ],
      ),
    );
  }

  Widget _checkItem(String label, bool checked) {
    return CheckboxListTile(title: Text(label), value: checked, onChanged: (_) {}, controlAffinity: ListTileControlAffinity.leading, dense: true);
  }
}

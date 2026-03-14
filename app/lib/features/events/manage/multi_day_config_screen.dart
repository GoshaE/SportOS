import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: E-MultiDay — Настройка многодневного мероприятия
class MultiDayConfigScreen extends StatefulWidget {
  const MultiDayConfigScreen({super.key});

  @override
  State<MultiDayConfigScreen> createState() => _MultiDayConfigScreenState();
}

class _MultiDayConfigScreenState extends State<MultiDayConfigScreen> {
  bool _isMultiDay = true;
  int _days = 2;
  String _day2Order = 'same';
  String _aggregation = 'sum';
  String _dnfPolicy = 'exclude';
  bool _vetDay2 = true;
  bool _bibKeep = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return Scaffold(
      appBar: AppAppBar(title: const Text('Многодневность')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Column(
              children: [
                AppSettingsTile.toggle(
                  title: 'Многодневное мероприятие',
                  subtitle: 'Несколько дней, общий зачёт',
                  value: _isMultiDay,
                  onChanged: (v) => setState(() => _isMultiDay = v),
                ),
                if (_isMultiDay) ...[
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: const Text('Количество дней'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _days > 2 ? () => setState(() => _days--) : null),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('$_days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.secondary)),
                      ),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _days++)),
                    ]),
                  ),
                ],
              ],
            ),
          ],
        ),
        if (_isMultiDay) ...[
          const SizedBox(height: 16),

          _sectionTitle('Стартовый порядок дня 2', cs),
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              Column(
                children: [
                  AppSettingsTile.radio(title: 'Такой же как день 1', subtitle: 'Тот же порядок, те же BIB', value: 'same', groupValue: _day2Order, onChanged: (v) => setState(() => _day2Order = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Обратный к дню 1 (лидер последний)', subtitle: 'Первое место → последний старт', value: 'reverse', groupValue: _day2Order, onChanged: (v) => setState(() => _day2Order = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(
                    title: 'Гундерсен (старт по отставанию)',
                    subtitle: 'Лидер стартует первым, остальные стартуют с отставанием от дня 1. Pursuit Start: кто пересёк финиш первым = победитель.',
                    value: 'gundersen', groupValue: _day2Order, onChanged: (v) => setState(() => _day2Order = v!),
                  ),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Новая жеребьёвка', subtitle: 'Полная пережеребьёвка на день 2', value: 'new_draw', groupValue: _day2Order, onChanged: (v) => setState(() => _day2Order = v!)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionTitle('Итоговый результат', cs),
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              Column(
                children: [
                  AppSettingsTile.radio(title: 'Сумма всех дней', subtitle: 'TotalTime = Σ NetTime[day_i]', value: 'sum', groupValue: _aggregation, onChanged: (v) => setState(() => _aggregation = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Лучший из дней', value: 'best', groupValue: _aggregation, onChanged: (v) => setState(() => _aggregation = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Среднее', value: 'average', groupValue: _aggregation, onChanged: (v) => setState(() => _aggregation = v!)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionTitle('DNF в один из дней', cs),
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              Column(
                children: [
                  AppSettingsTile.radio(title: 'Strict — выбывает из общего зачёта', subtitle: 'Результат другого дня сохраняется отдельно', value: 'exclude', groupValue: _dnfPolicy, onChanged: (v) => setState(() => _dnfPolicy = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Penalized — стартует последним', subtitle: 'DNF Day 1 → стартует последним Day 2 с макс. временем', value: 'penalized', groupValue: _dnfPolicy, onChanged: (v) => setState(() => _dnfPolicy = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Open — допущен', subtitle: 'DNS/DNF Day 1 → допущен Day 2 с фикс. интервалом', value: 'open', groupValue: _dnfPolicy, onChanged: (v) => setState(() => _dnfPolicy = v!)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionTitle('Дополнительно', cs),
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              Column(
                children: [
                  AppSettingsTile.radio(title: 'Сохранить те же номера', subtitle: 'Новый стартовый порядок, те же BIB', value: true, groupValue: _bibKeep, onChanged: (v) => setState(() => _bibKeep = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.radio(title: 'Новая нумерация', subtitle: 'Новые BIB + новый порядок', value: false, groupValue: _bibKeep, onChanged: (v) => setState(() => _bibKeep = v!)),
                  const Divider(height: 1, indent: 16),
                  AppSettingsTile.toggle(title: 'Ветконтроль день 2', subtitle: 'Обязательная проверка чипа (защита от подмены)', value: _vetDay2, onChanged: (v) => setState(() => _vetDay2 = v)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () { AppSnackBar.success(context, 'Настройки многодневности сохранены'); context.go('/manage/$eventId'); },
            icon: const Icon(Icons.save), label: const Text('Сохранить'),
          )),
        ],
      ]),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }
}

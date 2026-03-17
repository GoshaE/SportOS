import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';
import '../../../domain/timing/models.dart';

/// Screen ID: E-MultiDay — Настройка многодневного мероприятия
///
/// Глобальные настройки (зачёт, DNF, BIB) + список Day-карточек.
/// Tap → per-day editing sheet (дисциплины, стартовый порядок, время).
class MultiDayConfigScreen extends ConsumerWidget {
  const MultiDayConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventConfig = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Многодневность')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Toggle ───
        AppCard(padding: EdgeInsets.zero, children: [
          AppSettingsTile.toggle(
            title: 'Многодневное мероприятие',
            subtitle: 'Несколько дней соревнований',
            value: eventConfig.isMultiDay,
            onChanged: (v) => ref.read(eventConfigProvider.notifier).toggleMultiDay(v),
          ),
        ]),

        if (eventConfig.isMultiDay) ...[
          const SizedBox(height: 16),

          // ─── Глобальные настройки ───
          _sectionTitle(cs, 'Общие правила'),
          AppCard(padding: EdgeInsets.zero, children: [
            Column(children: [
              AppSettingsTile.nav(
                title: 'Итоговый зачёт',
                subtitle: _scoringLabel(eventConfig.scoringMode),
                onTap: () => _showScoringPicker(context, ref, eventConfig),
              ),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.nav(
                title: 'DNF в один из дней',
                subtitle: _dayPolicyLabel(eventConfig.dnfDayPolicy),
                onTap: () => _showDnfPicker(context, ref, eventConfig),
              ),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.nav(
                title: 'BIB номера',
                subtitle: _bibPolicyLabel(eventConfig.bibDayPolicy),
                onTap: () => _showBibPicker(context, ref, eventConfig),
              ),
            ]),
          ]),
          const SizedBox(height: 24),

          // ─── Дни ───
          _sectionTitle(cs, 'Дни соревнований'),
          ...eventConfig.days.map((day) {
            final dayDiscs = disciplines.where((d) => day.disciplineIds.contains(d.id)).toList();
            final discNames = dayDiscs.take(3).map((d) => d.name.split(' ').first).join(', ')
                + (dayDiscs.length > 3 ? '…' : '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(padding: EdgeInsets.zero, children: [
                InkWell(
                  onTap: () => _showDayEditor(context, ref, day, disciplines),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header: Day N — Date
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('${day.dayNumber}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('День ${day.dayNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(_formatDate(day.date), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ])),
                        Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
                      ]),
                      const SizedBox(height: 12),

                      // Disciplines
                      Row(children: [
                        Icon(Icons.sports, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text(
                          dayDiscs.isEmpty ? 'Нет дисциплин' : '${dayDiscs.length} дисц.: $discNames',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        )),
                      ]),
                      const SizedBox(height: 4),

                      // Start order + time
                      Row(children: [
                        Icon(Icons.format_list_numbered, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(_startOrderLabel(day.startOrder), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(day.startTime.format(), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        if (day.vetCheck) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.pets, size: 14, color: cs.tertiary),
                          const SizedBox(width: 4),
                          Text('Ветконтроль', style: TextStyle(fontSize: 12, color: cs.tertiary)),
                        ],
                      ]),
                    ]),
                  ),
                ),
              ]),
            );
          }),

          // Add day button
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _showAddDayPicker(context, ref, eventConfig),
            icon: const Icon(Icons.add),
            label: const Text('Добавить день'),
          ),
        ],
      ]),
    );
  }

  // ─── Day Editor Sheet ───

  void _showDayEditor(BuildContext context, WidgetRef ref, RaceDay day, List<DisciplineConfig> allDiscs) {
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(context, title: 'День ${day.dayNumber}', initialHeight: 0.85, child: StatefulBuilder(
      builder: (ctx, setSheetState) {
        final currentDay = ref.watch(eventConfigProvider).days.firstWhere((d) => d.dayNumber == day.dayNumber);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── Дисциплины ───
          Text('Дисциплины этого дня', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
          const SizedBox(height: 8),
          ...allDiscs.map((disc) {
            final enabled = currentDay.disciplineIds.contains(disc.id);
            return CheckboxListTile(
              dense: true,
              value: enabled,
              title: Text(disc.displayName, style: const TextStyle(fontSize: 14)),
              subtitle: Text('${disc.distanceKm} км', style: TextStyle(fontSize: 12, color: cs.outline)),
              onChanged: (v) {
                final newIds = List<String>.from(currentDay.disciplineIds);
                if (v == true) { newIds.add(disc.id); } else { newIds.remove(disc.id); }
                ref.read(eventConfigProvider.notifier).updateDay(day.dayNumber, (d) => d.copyWith(disciplineIds: newIds));
              },
            );
          }),
          const SizedBox(height: 16),

          // ─── Стартовый порядок ───
          Text('Стартовый порядок', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
          const SizedBox(height: 8),
          ...StartOrder.values.map((order) {
            final isFirst = day.dayNumber == 1;
            final disabledForDay1 = isFirst && (order == StartOrder.reverse || order == StartOrder.pursuit || order == StartOrder.same);
            return RadioListTile<StartOrder>(
              dense: true,
              value: order,
              groupValue: currentDay.startOrder,
              title: Text(_startOrderLabel(order), style: TextStyle(fontSize: 14, color: disabledForDay1 ? cs.onSurface.withValues(alpha: 0.3) : null)),
              subtitle: Text(_startOrderDesc(order), style: TextStyle(fontSize: 11, color: cs.outline)),
              onChanged: disabledForDay1 ? null : (v) {
                if (v != null) ref.read(eventConfigProvider.notifier).updateDay(day.dayNumber, (d) => d.copyWith(startOrder: v));
              },
            );
          }),
          const SizedBox(height: 16),

          // ─── Доп. настройки ───
          Text('Дополнительно', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
          const SizedBox(height: 8),
          AppSettingsTile.toggle(
            title: 'Ветконтроль',
            subtitle: 'Обязательная проверка чипа',
            value: currentDay.vetCheck,
            onChanged: (v) => ref.read(eventConfigProvider.notifier).updateDay(day.dayNumber, (d) => d.copyWith(vetCheck: v)),
          ),

          // ─── Удалить ───
          if (day.dayNumber > 1) ...[
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () {
                ref.read(eventConfigProvider.notifier).removeDay(day.dayNumber);
                Navigator.of(ctx).pop();
              },
              icon: Icon(Icons.delete_outline, color: cs.error),
              label: Text('Удалить день ${day.dayNumber}', style: TextStyle(color: cs.error)),
            )),
          ],
        ]);
      },
    ));
  }

  // ─── Add Day Picker ───

  void _showAddDayPicker(BuildContext context, WidgetRef ref, EventConfig config) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(context, title: 'Добавить день', child: Column(children: [
      ListTile(
        leading: Icon(Icons.content_copy, color: cs.primary),
        title: const Text('Копировать из предыдущего дня'),
        subtitle: const Text('Те же дисциплины, обратный стартовый порядок'),
        onTap: () {
          ref.read(eventConfigProvider.notifier).addDayFromTemplate();
          Navigator.of(context).pop();
        },
      ),
      if (config.days.length > 1) ...[
        const Divider(height: 1, indent: 16),
        ...config.days.map((day) => ListTile(
          leading: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text('${day.dayNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.secondary))),
          ),
          title: Text('Копировать из дня ${day.dayNumber}'),
          subtitle: Text('${day.disciplineIds.length} дисц.', style: TextStyle(fontSize: 12, color: cs.outline)),
          onTap: () {
            ref.read(eventConfigProvider.notifier).addDayFromTemplate(copyFromDayNumber: day.dayNumber);
            Navigator.of(context).pop();
          },
        )),
      ],
    ]));
  }

  // ─── Scoring, DNF, BIB Pickers ───

  void _showScoringPicker(BuildContext context, WidgetRef ref, EventConfig config) {
    AppBottomSheet.show(context, title: 'Итоговый зачёт', child: Column(children: [
      ...ScoringMode.values.map((mode) => RadioListTile<ScoringMode>(
        value: mode,
        groupValue: config.scoringMode,
        title: Text(_scoringLabel(mode)),
        onChanged: (v) {
          if (v != null) ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(scoringMode: v));
          Navigator.of(context).pop();
        },
      )),
    ]));
  }

  void _showDnfPicker(BuildContext context, WidgetRef ref, EventConfig config) {
    AppBottomSheet.show(context, title: 'DNF в один из дней', child: Column(children: [
      ...DayPolicy.values.map((policy) => RadioListTile<DayPolicy>(
        value: policy,
        groupValue: config.dnfDayPolicy,
        title: Text(_dayPolicyLabel(policy)),
        subtitle: Text(_dayPolicyDesc(policy), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
        onChanged: (v) {
          if (v != null) ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(dnfDayPolicy: v));
          Navigator.of(context).pop();
        },
      )),
    ]));
  }

  void _showBibPicker(BuildContext context, WidgetRef ref, EventConfig config) {
    AppBottomSheet.show(context, title: 'BIB номера', child: Column(children: [
      ...BibDayPolicy.values.map((policy) => RadioListTile<BibDayPolicy>(
        value: policy,
        groupValue: config.bibDayPolicy,
        title: Text(_bibPolicyLabel(policy)),
        onChanged: (v) {
          if (v != null) ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(bibDayPolicy: v));
          Navigator.of(context).pop();
        },
      )),
    ]));
  }

  // ─── Labels ───

  String _scoringLabel(ScoringMode mode) => switch (mode) {
    ScoringMode.cumulative => 'Суммарное время',
    ScoringMode.perDay => 'Отдельно по дням',
    ScoringMode.pursuit => 'Преследование (Гундерсен)',
  };

  String _dayPolicyLabel(DayPolicy policy) => switch (policy) {
    DayPolicy.strict => 'Strict — выбывает',
    DayPolicy.penalized => 'Penalized — стартует последним',
    DayPolicy.open => 'Open — допущен',
  };

  String _dayPolicyDesc(DayPolicy policy) => switch (policy) {
    DayPolicy.strict => 'Выбывает из общего зачёта',
    DayPolicy.penalized => 'Стартует последним с макс. временем',
    DayPolicy.open => 'Допущен с фиксированным интервалом',
  };

  String _bibPolicyLabel(BibDayPolicy policy) => switch (policy) {
    BibDayPolicy.keep => 'Сохранить номера',
    BibDayPolicy.redraw => 'Новая нумерация',
    BibDayPolicy.pursuit => 'Порядок по отставанию',
  };

  String _startOrderLabel(StartOrder order) => switch (order) {
    StartOrder.draw => 'Жеребьёвка',
    StartOrder.same => 'Как предыдущий день',
    StartOrder.reverse => 'Обратный порядок',
    StartOrder.pursuit => 'Гундерсен',
  };

  String _startOrderDesc(StartOrder order) => switch (order) {
    StartOrder.draw => 'Новый случайный порядок',
    StartOrder.same => 'Тот же стартовый порядок',
    StartOrder.reverse => 'Лидер стартует последним',
    StartOrder.pursuit => 'Стартовый интервал = отставание',
  };

  String _formatDate(DateTime date) {
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }
}

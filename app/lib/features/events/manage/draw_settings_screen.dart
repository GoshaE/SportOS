import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

/// Screen: Настройки жеребьёвки — подключено к DrawConfig + Manual Start.
class DrawSettingsScreen extends ConsumerWidget {
  const DrawSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(eventConfigProvider);
    final draw = config.drawConfig;
    final disciplines = ref.watch(disciplineConfigsProvider);

    void updateDraw(DrawConfig Function(DrawConfig d) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(drawConfig: fn(c.drawConfig)),
      );
    }

    return Scaffold(
      appBar: AppAppBar(title: const Text('Жеребьёвка')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ─── Режим ───
        _section(cs, 'Режим'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.radio(
              title: 'Авто жеребьёвка',
              subtitle: 'Случайный порядок',
              value: DrawMode.auto,
              groupValue: draw.mode,
              onChanged: (_) => updateDraw((d) => d.copyWith(mode: DrawMode.auto)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(
              title: 'Ручная',
              subtitle: 'Организатор назначает',
              value: DrawMode.manual,
              groupValue: draw.mode,
              onChanged: (_) => updateDraw((d) => d.copyWith(mode: DrawMode.manual)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(
              title: 'Комбинированная',
              subtitle: 'Посев + авто',
              value: DrawMode.combined,
              groupValue: draw.mode,
              onChanged: (_) => updateDraw((d) => d.copyWith(mode: DrawMode.combined)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Группировка ───
        _section(cs, 'Группировка'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.radio(
              title: 'Совместная',
              subtitle: 'Все категории вместе',
              value: DrawGrouping.joint,
              groupValue: draw.grouping,
              onChanged: (_) => updateDraw((d) => d.copyWith(grouping: DrawGrouping.joint)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.radio(
              title: 'По категориям',
              subtitle: 'CEC → OPEN → Юн...',
              value: DrawGrouping.byCategory,
              groupValue: draw.grouping,
              onChanged: (_) => updateDraw((d) => d.copyWith(grouping: DrawGrouping.byCategory)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Дополнительно ───
        _section(cs, 'Дополнительно'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(
              title: 'Буфер между группами',
              subtitle: '${draw.bufferMinutes} мин.',
              onTap: () => _editBuffer(context, draw.bufferMinutes, updateDraw),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Только подтверждённые',
              subtitle: 'Неподтв. заявки не участвуют',
              value: draw.onlyApproved,
              onChanged: (v) => updateDraw((d) => d.copyWith(onlyApproved: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 24),

        // ─── Ручной старт по дисциплинам ───
        _section(cs, 'Ручной старт'),
        Text(
          'Стартёр подтверждает «УШЁЛ» для каждого участника',
          style: TextStyle(fontSize: 11, color: cs.outline),
        ),
        const SizedBox(height: 8),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            ...disciplines.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              // Manual start only makes sense for individual start
              final isIndividual = d.startType == StartType.individual;
              return Column(children: [
                if (i > 0) const Divider(height: 1, indent: 16),
                AppSettingsTile.toggle(
                  title: d.name,
                  subtitle: isIndividual
                      ? (d.manualStart ? 'Ручной' : 'Авто по таймеру')
                      : 'Масс-старт — не применимо',
                  value: d.manualStart,
                  onChanged: isIndividual ? (v) {
                    ref.read(eventConfigProvider.notifier).updateDiscipline(
                      d.id, (old) => old.copyWith(manualStart: v),
                    );
                  } : null,
                ),
              ]);
            }),
          ]),
        ]),
        const SizedBox(height: 32),

        // ─── Multi-day start order (only if multi-day) ───
        if (config.isMultiDay && config.days.isNotEmpty) ...[
          _section(cs, 'Стартовый порядок по дням'),
          Text(
            'Как формируется стартовый порядок для каждого дня',
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
          const SizedBox(height: 8),
          AppCard(padding: EdgeInsets.zero, children: [
            Column(children: [
              ...config.days.asMap().entries.map((entry) {
                final i = entry.key;
                final day = entry.value;
                return Column(children: [
                  if (i > 0) const Divider(height: 1, indent: 16),
                  AppSettingsTile.nav(
                    title: 'День ${day.dayNumber}',
                    subtitle: _startOrderLabel(day.startOrder),
                    onTap: () => _pickStartOrder(context, ref, day),
                  ),
                ]);
              }),
            ]),
          ]),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  Widget _section(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }

  void _editBuffer(BuildContext context, int currentMinutes, void Function(DrawConfig Function(DrawConfig)) updateDraw) {
    final ctrl = TextEditingController(text: '$currentMinutes');
    AppBottomSheet.show(context, title: 'Буфер между группами', child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'Минуты', border: OutlineInputBorder(), suffixText: 'мин'),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          final mins = int.tryParse(ctrl.text) ?? 5;
          updateDraw((d) => d.copyWith(bufferMinutes: mins.clamp(0, 60)));
          Navigator.pop(context);
        },
        child: const Text('Сохранить'),
      )),
    ]));
  }

  String _startOrderLabel(StartOrder order) => switch (order) {
    StartOrder.draw    => 'Жеребьёвка (случайный)',
    StartOrder.same    => 'Такой же (как вчера)',
    StartOrder.reverse => 'Обратный (лидер последним)',
    StartOrder.pursuit => 'Преследование (Гундерсен)',
  };

  void _pickStartOrder(BuildContext context, WidgetRef ref, RaceDay day) {
    AppBottomSheet.show(context, title: 'День ${day.dayNumber} — стартовый порядок', child: Column(
      mainAxisSize: MainAxisSize.min,
      children: StartOrder.values.map((order) => ListTile(
        title: Text(_startOrderLabel(order)),
        trailing: order == day.startOrder ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
        onTap: () {
          ref.read(eventConfigProvider.notifier).updateDay(
            day.dayNumber, (d) => d.copyWith(startOrder: order),
          );
          Navigator.pop(context);
        },
      )).toList(),
    ));
  }
}

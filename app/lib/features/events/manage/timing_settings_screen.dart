import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// Настройки хронометража — подключено к Config Engine.
///
/// TimingConfig (precision, dual, GPS, audit, photo-finish)
/// + minLapTime per-discipline + PenaltyTemplate library.
class TimingSettingsScreen extends ConsumerWidget {
  const TimingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(eventConfigProvider);
    final timing = config.timingConfig;
    final disciplines = ref.watch(disciplineConfigsProvider);
    final penalties = config.penaltyTemplates;

    void updateTiming(TimingConfig Function(TimingConfig t) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(timingConfig: fn(c.timingConfig)),
      );
    }

    return Scaffold(
      appBar: AppAppBar(title: const Text('Хронометраж')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ─── Точность ───
        _section(cs, 'Точность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(
              title: 'Точность отсечки',
              subtitle: _precisionLabel(timing.precision),
              onTap: () => _pickPrecision(context, timing.precision, updateTiming),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Min Lap Time по дисциплинам ───
        _section(cs, 'Минимальное время круга'),
        Text('Отсечки быстрее этого порога игнорируются', style: TextStyle(fontSize: 11, color: cs.outline)),
        const SizedBox(height: 8),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            ...disciplines.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Column(children: [
                if (i > 0) const Divider(height: 1, indent: 16),
                AppSettingsTile.nav(
                  title: d.name,
                  subtitle: '${d.minLapTime.inSeconds} сек',
                  onTap: () => _editMinLap(context, ref, d),
                ),
              ]);
            }),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Режим работы ───
        _section(cs, 'Режим работы'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Двойной хронометраж',
              subtitle: 'Мастер + Контрольный',
              value: timing.dualTiming,
              onChanged: (v) => updateTiming((t) => t.copyWith(dualTiming: v)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'GPS трекинг',
              value: timing.gpsTracking,
              onChanged: (v) => updateTiming((t) => t.copyWith(gpsTracking: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Безопасность ───
        _section(cs, 'Безопасность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Аудит лог',
              subtitle: 'Запись всех изменений',
              value: timing.auditLog,
              onChanged: (v) => updateTiming((t) => t.copyWith(auditLog: v)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Двойное подтверждение DNF',
              value: timing.doubleDnfConfirm,
              onChanged: (v) => updateTiming((t) => t.copyWith(doubleDnfConfirm: v)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Photo-Finish',
              subtitle: 'Два судьи',
              value: timing.photoFinish,
              onChanged: (v) => updateTiming((t) => t.copyWith(photoFinish: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 24),

        // ─── Библиотека штрафов ───
        _section(cs, 'Библиотека штрафов'),
        Text('Судьи выбирают из этих шаблонов при назначении', style: TextStyle(fontSize: 11, color: cs.outline)),
        const SizedBox(height: 8),
        ...penalties.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(padding: EdgeInsets.zero, children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.isDsq ? cs.error.withValues(alpha: 0.15) : cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(p.code, style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 11,
                    color: p.isDsq ? cs.error : cs.tertiary,
                  )),
                ),
                title: Text(p.description, style: const TextStyle(fontSize: 13)),
                subtitle: Text(p.displayTime, style: TextStyle(
                  fontSize: 11,
                  color: p.isDsq ? cs.error : cs.tertiary,
                  fontWeight: FontWeight.bold,
                )),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  onPressed: () {
                    final updated = List<PenaltyTemplate>.from(penalties)..removeAt(i);
                    ref.read(eventConfigProvider.notifier).update(
                      (c) => c.copyWith(penaltyTemplates: updated),
                    );
                  },
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addPenalty(context, ref, penalties),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Добавить штраф'),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }

  String _precisionLabel(TimingPrecision p) => switch (p) {
    TimingPrecision.seconds => 'Секунды (1)',
    TimingPrecision.tenths => 'Десятые (0.1)',
    TimingPrecision.hundredths => 'Сотые (0.01)',
    TimingPrecision.milliseconds => 'Миллисекунды (0.001)',
  };

  void _pickPrecision(BuildContext context, TimingPrecision current, void Function(TimingConfig Function(TimingConfig)) updateTiming) {
    AppBottomSheet.show(context, title: 'Точность', child: Column(mainAxisSize: MainAxisSize.min, children: [
      ...TimingPrecision.values.map((p) => ListTile(
        title: Text(_precisionLabel(p)),
        trailing: p == current ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
        onTap: () {
          updateTiming((t) => t.copyWith(precision: p));
          Navigator.pop(context);
        },
      )),
    ]));
  }

  void _editMinLap(BuildContext context, WidgetRef ref, dynamic disc) {
    final ctrl = TextEditingController(text: '${disc.minLapTime.inSeconds}');
    AppBottomSheet.show(context, title: '${disc.name} — мин. время круга', child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'Секунды', border: OutlineInputBorder(), suffixText: 'сек'),
        keyboardType: TextInputType.number, autofocus: true,
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          final secs = int.tryParse(ctrl.text) ?? 20;
          ref.read(eventConfigProvider.notifier).updateDiscipline(
            disc.id, (d) => d.copyWith(minLapTime: Duration(seconds: secs.clamp(1, 600))),
          );
          Navigator.pop(context);
        },
        child: const Text('Сохранить'),
      )),
    ]));
  }

  void _addPenalty(BuildContext context, WidgetRef ref, List<PenaltyTemplate> templates) {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final secsCtrl = TextEditingController(text: '15');
    var isDsq = false;

    AppBottomSheet.show(context, title: 'Новый штраф', child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SizedBox(width: 80, child: TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Код *', border: OutlineInputBorder(), hintText: 'P9'),
            textCapitalization: TextCapitalization.characters,
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Описание *', border: OutlineInputBorder()),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            title: const Text('DSQ (дисквалификация)', style: TextStyle(fontSize: 13)),
            value: isDsq,
            onChanged: (v) => setModal(() => isDsq = v!),
          )),
          if (!isDsq)
            SizedBox(width: 100, child: TextField(
              controller: secsCtrl,
              decoration: const InputDecoration(labelText: 'Сек.', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            )),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (codeCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
              AppSnackBar.error(ctx, 'Заполните код и описание');
              return;
            }
            final template = PenaltyTemplate(
              id: 'pt-${DateTime.now().millisecondsSinceEpoch}',
              code: codeCtrl.text.trim().toUpperCase(),
              description: descCtrl.text.trim(),
              timePenalty: isDsq ? null : Duration(seconds: int.tryParse(secsCtrl.text) ?? 15),
              sortOrder: templates.length + 1,
            );
            ref.read(eventConfigProvider.notifier).update(
              (c) => c.copyWith(penaltyTemplates: [...c.penaltyTemplates, template]),
            );
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        )),
      ]),
    ));
  }
}

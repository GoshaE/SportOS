import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';

/// Screen: Настройки отображения таблиц (per-discipline)
///
/// Dropdown дисциплины → toggles для DisplaySettings.
class DisplaySettingsScreen extends ConsumerStatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  ConsumerState<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends ConsumerState<DisplaySettingsScreen> {
  String? _selectedDiscId;

  @override
  Widget build(BuildContext context) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    _selectedDiscId ??= disciplines.isNotEmpty ? disciplines.first.id : null;
    final selectedDisc = disciplines.where((d) => d.id == _selectedDiscId).firstOrNull;
    final ds = selectedDisc?.displaySettings;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Отображение таблиц')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Discipline selector
        Text('Дисциплина', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: disciplines.map((d) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(d.displayName, style: const TextStyle(fontSize: 12)),
              selected: _selectedDiscId == d.id,
              onSelected: (_) => setState(() => _selectedDiscId = d.id),
              visualDensity: VisualDensity.compact,
            ),
          )).toList()),
        ),
        const SizedBox(height: 16),

        if (ds != null && selectedDisc != null) ...[
          // Columns section
          _sectionTitle(cs, 'Колонки протокола'),
          AppCard(padding: EdgeInsets.zero, children: [
            Column(children: [
              AppSettingsTile.toggle(title: 'Сплиты по кругам', subtitle: 'Кр.1, Кр.2...', value: ds.showLapSplits, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showLapSplits: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Контрольные точки (КП)', subtitle: 'Маршальские сплиты', value: ds.showCheckpoints, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showCheckpoints: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Средняя скорость', subtitle: 'км/ч', value: ds.showSpeed, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showSpeed: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Темп (мин/км)', subtitle: 'Для бега/трейла', value: ds.showPace, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showPace: v),
                ));
              }),
            ]),
          ]),
          const SizedBox(height: 16),

          // Gap & info section
          _sectionTitle(cs, 'Отставание и информация'),
          AppCard(padding: EdgeInsets.zero, children: [
            Column(children: [
              AppSettingsTile.toggle(title: 'Отставание от лидера', value: ds.showGapToLeader, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showGapToLeader: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Разрыв с предыдущим', value: ds.showGapToPrev, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showGapToPrev: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Клички собак', subtitle: 'Для ездового спорта', value: ds.showDogNames, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showDogNames: v),
                ));
              }),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.toggle(title: 'Клуб / город', value: ds.showClub, onChanged: (v) {
                ref.read(eventConfigProvider.notifier).updateDiscipline(selectedDisc.id, (old) => old.copyWith(
                  displaySettings: old.displaySettings.copyWith(showClub: v),
                ));
              }),
            ]),
          ]),
        ],
      ]),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/ui/molecules/app_list_row.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen ID: P4 — Ветконтроль
///
/// Читает участников из [participantsProvider].
/// Кнопки «Допустить» / «Не допустить» → обновляют [Participant.vetStatus].
class VetCheckScreen extends ConsumerStatefulWidget {
  const VetCheckScreen({super.key});

  @override
  ConsumerState<VetCheckScreen> createState() => _VetCheckScreenState();
}

class _VetCheckScreenState extends ConsumerState<VetCheckScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all | passed | pending | failed

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final participants = ref.watch(participantsProvider);

    // Only show participants that have dogs
    final withDogs = participants.where((p) => p.dogName != null && p.dogName!.isNotEmpty).toList();

    final passedCount = withDogs.where((p) => p.vetStatus == VetStatus.passed).length;
    final pendingCount = withDogs.where((p) => p.vetStatus == VetStatus.pending).length;
    final failedCount = withDogs.where((p) => p.vetStatus == VetStatus.failed).length;

    final filtered = withDogs.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !(p.dogName?.toLowerCase().contains(q) ?? false) &&
            !p.bib.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filter == 'passed') return p.vetStatus == VetStatus.passed;
      if (_filter == 'pending') return p.vetStatus == VetStatus.pending;
      if (_filter == 'failed') return p.vetStatus == VetStatus.failed;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppAppBar(title: const Text('Ветконтроль'), actions: [
        if (failedCount > 0)
          Badge(label: Text('$failedCount'), child: IconButton(icon: const Icon(Icons.warning), onPressed: () => setState(() => _filter = 'failed'))),
        IconButton(icon: const Icon(Icons.nfc), tooltip: 'NFC чтение чипа', onPressed: () => AppSnackBar.info(context, 'NFC — поиск чипа собаки')),
      ]),
      body: Column(children: [
        // ─── Статистика ───
        AppInfoPanel(
          backgroundColor: cs.surfaceContainerHighest,
          children: [
            AppInfoPanel.stat('$passedCount', 'Прошли', cs.primary),
            AppInfoPanel.stat('$pendingCount', 'Ожидают', cs.tertiary),
            AppInfoPanel.stat('$failedCount', 'Отклонены', cs.error),
          ],
        ),

        // ─── Поиск + фильтры ───
        Padding(padding: const EdgeInsets.all(8), child: TextField(
          decoration: InputDecoration(
            hintText: 'Поиск по кличке, ФИО, BIB...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _filterChip(cs, 'Все', 'all'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Ожидают', 'pending'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Прошли', 'passed'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Отклонены', 'failed'),
            const Spacer(),
            Text('${filtered.length}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 4),

        // ─── Список ───
        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pets, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(
                withDogs.isEmpty ? 'Нет участников с собаками' : 'Нет совпадений',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _vetRow(context, cs, filtered[i]),
            ),
        ),
      ]),
    );
  }

  Widget _filterChip(ColorScheme cs, String label, String value) {
    final sel = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: sel ? cs.onPrimary : null)),
      selected: sel,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _vetRow(BuildContext context, ColorScheme cs, Participant p) {
    final status = p.vetStatus;
    final color = status == VetStatus.passed ? cs.primary
        : status == VetStatus.failed ? cs.error
        : cs.onSurfaceVariant;
    final icon = status == VetStatus.passed ? Icons.check_circle
        : status == VetStatus.failed ? Icons.cancel
        : Icons.hourglass_empty;

    return Card(child: AppListRow.status(
      icon: icon,
      iconColor: color,
      title: '${p.dogName ?? "—"} · ${p.name}',
      subtitle: '${p.bib.isNotEmpty ? "BIB ${p.bib} · " : ""}${p.disciplineName}${p.insuranceNo != null ? " · Страх.: ${p.insuranceNo}" : ""}',
      trailing: status == VetStatus.pending
        ? FilledButton(onPressed: () => _showDogCard(context, cs, p), child: const Text('Осмотр'))
        : IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showDogCard(context, cs, p)),
      onTap: () => _showDogCard(context, cs, p),
    ));
  }

  void _showDogCard(BuildContext context, ColorScheme cs, Participant p) {
    AppBottomSheet.show(context, title: p.dogName ?? 'Собака', initialHeight: 0.55, actions: [
      Row(children: [
        Expanded(child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(participantsProvider.notifier).setVetStatus(p.id, VetStatus.passed);
            AppSnackBar.success(context, '${p.dogName} — допущен');
          },
          icon: const Icon(Icons.check), label: const Text('Допустить'),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            _showRejectReason(context, cs, p);
          },
          icon: const Icon(Icons.close), label: const Text('Не допустить'),
        )),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.info(context, 'Замена собаки — двухэтапная проверка чипа'); },
        icon: const Icon(Icons.swap_horiz), label: const Text('Замена собаки'),
      ),
    ], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 30, backgroundColor: cs.secondaryContainer, child: Icon(Icons.pets, size: 32, color: cs.secondary)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.dogName ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Владелец: ${p.name}'),
          if (p.club != null) Text('Клуб: ${p.club}', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      ]),
      Divider(height: 24, color: cs.outlineVariant.withValues(alpha: 0.3)),
      AppListRow.status(icon: p.insuranceNo != null ? Icons.check_circle : Icons.warning, title: 'Страховка', subtitle: p.insuranceNo ?? 'Не указана'),
      AppListRow.status(icon: Icons.medical_services, title: 'Осмотр', subtitle: 'Общее состояние'),
      AppListRow.status(icon: Icons.thermostat, iconColor: cs.tertiary, title: 'Температура', subtitle: '—'),
    ]));
  }

  void _showRejectReason(BuildContext context, ColorScheme cs, Participant p) {
    AppBottomSheet.show(
      context,
      title: 'Не допустить — ${p.dogName}',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Подтвердить отказ',
          backgroundColor: cs.error,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(participantsProvider.notifier).setVetStatus(p.id, VetStatus.failed);
            AppSnackBar.error(context, '${p.dogName} — не допущен');
          },
        ),
      ],
      child: AppCard(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('Просрочена вакцинация'), selected: true, onSelected: (_) {}),
            ChoiceChip(label: const Text('Травма'), selected: false, onSelected: (_) {}),
            ChoiceChip(label: const Text('Агрессия'), selected: false, onSelected: (_) {}),
            ChoiceChip(label: const Text('Другое'), selected: false, onSelected: (_) {}),
          ]),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'Комментарий', border: OutlineInputBorder()), maxLines: 2),
        ]
      ),
    );
  }
}

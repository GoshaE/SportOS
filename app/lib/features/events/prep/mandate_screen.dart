import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen ID: P5 — Мандатная комиссия
///
/// Читает участников из [participantsProvider].
/// Кнопки «Допустить» / «Отказать» → обновляют [Participant.mandateStatus].
class MandateScreen extends ConsumerStatefulWidget {
  const MandateScreen({super.key});

  @override
  ConsumerState<MandateScreen> createState() => _MandateScreenState();
}

class _MandateScreenState extends ConsumerState<MandateScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all | passed | pending | failed

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final participants = ref.watch(participantsProvider);

    // Computed stats
    final passedCount = participants.where((p) => p.mandateStatus == MandateStatus.passed).length;
    final pendingCount = participants.where((p) => p.mandateStatus == MandateStatus.pending).length;
    final failedCount = participants.where((p) => p.mandateStatus == MandateStatus.failed).length;
    final total = participants.length;

    // Apply filters
    final filtered = participants.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.bib.toLowerCase().contains(q) &&
            !(p.dogName?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (_filter == 'passed') return p.mandateStatus == MandateStatus.passed;
      if (_filter == 'pending') return p.mandateStatus == MandateStatus.pending;
      if (_filter == 'failed') return p.mandateStatus == MandateStatus.failed;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppAppBar(title: const Text('Мандатная комиссия'), actions: [
        if (failedCount > 0)
          Badge(label: Text('$failedCount'), child: IconButton(icon: Icon(Icons.warning, color: cs.error), onPressed: () => setState(() => _filter = 'failed'))),
      ]),
      body: Column(children: [
        // ─── Статистика ───
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('$passedCount', 'Допущены', cs.primary),
            _stat('$pendingCount', 'Ожидают', cs.tertiary),
            _stat('$failedCount', 'Отказ', cs.error),
            _stat('$total', 'Всего', cs.onSurface),
          ]),
        ),

        // ─── Поиск + фильтры ───
        Padding(padding: const EdgeInsets.all(8), child: AppTextField(
          label: 'Поиск по BIB, ФИО, собаке...',
          prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _filterChip(cs, 'Все ($total)', 'all'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Ожидают ($pendingCount)', 'pending'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Допущены ($passedCount)', 'passed'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Отказ ($failedCount)', 'failed'),
            const Spacer(),
            Text('${filtered.length}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 4),

        // ─── Список участников ───
        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(
                participants.isEmpty ? 'Нет участников' : 'Нет совпадений',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _mandateCard(context, cs, filtered[i]),
            ),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 11, color: color)),
  ]);

  Widget _filterChip(ColorScheme cs, String label, String value) {
    final sel = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: sel ? cs.onPrimary : null)),
      selected: sel,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _mandateCard(BuildContext context, ColorScheme cs, Participant p) {
    final status = p.mandateStatus;
    final color = status == MandateStatus.passed ? cs.primary
        : status == MandateStatus.failed ? cs.error
        : cs.onSurfaceVariant;
    final icon = status == MandateStatus.passed ? Icons.check_circle
        : status == MandateStatus.failed ? Icons.cancel
        : Icons.hourglass_empty;
    final subtitle = status == MandateStatus.passed ? 'Допущен'
        : status == MandateStatus.failed ? 'Не допущен'
        : 'Ожидает проверки';

    // Document checklist items (UI-only, not persisted)
    final hasInsurance = p.insuranceNo != null && p.insuranceNo!.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          '${p.bib.isNotEmpty ? "BIB ${p.bib} " : ""}${p.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
          if (p.disciplineName.isNotEmpty)
            Text(p.disciplineName, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        children: [
          // Document checklist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _checkItem('Паспорт / удостоверение личности', status == MandateStatus.passed),
              _checkItem('Медицинская справка', status == MandateStatus.passed),
              _checkItem('Страховка', hasInsurance || status == MandateStatus.passed),
              _checkItem('Согласие на обработку ПД', status == MandateStatus.passed),
            ]),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: AppButton.primary(
                text: 'Допустить',
                icon: Icons.check,
                onPressed: () {
                  ref.read(participantsProvider.notifier).setMandateStatus(p.id, MandateStatus.passed);
                  AppSnackBar.success(context, '${p.name} — допущен');
                },
              )),
              const SizedBox(width: 8),
              Expanded(child: AppButton.smallDanger(
                text: 'Отказать',
                icon: Icons.close,
                onPressed: () {
                  ref.read(participantsProvider.notifier).setMandateStatus(p.id, MandateStatus.failed);
                  AppSnackBar.error(context, '${p.name} — не допущен');
                },
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String label, bool checked) {
    return CheckboxListTile(
      title: Text(label),
      value: checked,
      onChanged: (_) {},
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

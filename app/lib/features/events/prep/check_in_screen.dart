import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen ID: P6 — Чек-ин
///
/// Читает из [participantsProvider].
/// Чек-ин отмечается через [ParticipantsNotifier.toggleCheckIn].
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  String _filter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final participants = ref.watch(participantsProvider);

    final arrivedCount = participants.where((p) => p.checkInTime != null).length;
    final waitingCount = participants.where((p) => p.checkInTime == null).length;
    final unpaidCount = participants.where((p) => p.paymentStatus != PaymentStatus.paid).length;
    final mandateIssues = participants.where((p) => p.mandateStatus != MandateStatus.passed).length;

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
      if (_filter == 'arrived') return p.checkInTime != null;
      if (_filter == 'waiting') return p.checkInTime == null;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppAppBar(title: const Text('Чек-ин'), actions: [
        if (unpaidCount > 0) Badge(label: Text('$unpaidCount'), backgroundColor: cs.error, child: IconButton(icon: Icon(Icons.payment, color: cs.error), tooltip: 'Неоплаченные', onPressed: () => setState(() => _filter = 'all'))),
        IconButton(icon: const Icon(Icons.nfc), tooltip: 'NFC Сканер', onPressed: () => AppSnackBar.info(context, 'NFC чек-ин — Фаза 2')),
      ]),
      body: Column(children: [
        // ─── Статистика ───
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Прибыли', '$arrivedCount', cs.primary),
            _stat('Ожидаем', '$waitingCount', cs.tertiary),
            _stat('Не оплач.', '$unpaidCount', cs.error),
            _stat('Мандат', '$mandateIssues', cs.secondary),
            _stat('Всего', '${participants.length}', cs.onSurface),
          ]),
        ),

        // ─── Фильтры ───
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
          _filterChip(cs, 'Все', 'all'), const SizedBox(width: 6),
          _filterChip(cs, 'Прибыли', 'arrived'), const SizedBox(width: 6),
          _filterChip(cs, 'Ожидаем', 'waiting'), const Spacer(),
          Text('${filtered.length} записей', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),

        // ─── Поиск ───
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: AppTextField(label: 'Поиск по BIB, ФИО, кличке...', prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _searchQuery = v))),
        const SizedBox(height: 4),

        // ─── Список ───
        Expanded(child: filtered.isEmpty
          ? Center(child: Text(participants.isEmpty ? 'Нет участников' : 'Нет совпадений', style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                final checked = p.checkInTime != null;
                final paid = p.paymentStatus == PaymentStatus.paid;
                final mandate = p.mandateStatus;
                final vet = p.vetStatus == VetStatus.passed;
                final bibAssigned = p.bib.isNotEmpty;

                final timeStr = checked
                    ? '${p.checkInTime!.hour.toString().padLeft(2, '0')}:${p.checkInTime!.minute.toString().padLeft(2, '0')}'
                    : '—';

                return Card(
                  color: !paid ? cs.error.withValues(alpha: 0.03)
                      : mandate == MandateStatus.failed ? cs.secondary.withValues(alpha: 0.03) : null,
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () => ref.read(participantsProvider.notifier).toggleCheckIn(p.id),
                      child: Icon(checked ? Icons.check_circle : Icons.radio_button_unchecked, color: checked ? cs.primary : cs.onSurfaceVariant, size: 32),
                    ),
                    title: Row(children: [
                      Text(bibAssigned ? 'BIB ${p.bib}' : 'No BIB', style: TextStyle(fontWeight: FontWeight.bold, color: bibAssigned ? null : cs.tertiary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${p.name}${p.dogName != null ? " (${p.dogName})" : ""}', style: const TextStyle(fontSize: 13))),
                    ]),
                    subtitle: Row(children: [
                      if (checked) Text(timeStr, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      if (checked) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(paid ? Icons.payments : Icons.money_off, size: 16, color: paid ? cs.primary : cs.error),
                          const SizedBox(width: 6),
                          Icon(mandate == MandateStatus.passed ? Icons.health_and_safety : Icons.health_and_safety_outlined, size: 16, color: mandate == MandateStatus.passed ? cs.primary : mandate == MandateStatus.failed ? cs.error : cs.tertiary),
                          const SizedBox(width: 6),
                          Icon(vet ? Icons.pets : Icons.pets_outlined, size: 16, color: vet ? cs.primary : cs.tertiary),
                          const SizedBox(width: 6),
                          Icon(bibAssigned ? Icons.numbers : Icons.numbers_outlined, size: 16, color: bibAssigned ? cs.primary : cs.onSurfaceVariant),
                        ]),
                      ),
                    ]),
                    trailing: checked
                      ? Icon(Icons.check, color: cs.primary, size: 20)
                      : SizedBox(width: 70, height: 32, child: AppButton.small(
                          text: 'Чек-ин',
                          onPressed: () => ref.read(participantsProvider.notifier).toggleCheckIn(p.id),
                        )),
                  ),
                );
              },
            ),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 10, color: color)),
  ]);

  Widget _filterChip(ColorScheme cs, String label, String value) {
    final sel = _filter == value;
    return ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel ? cs.onPrimary : null)), selected: sel, onSelected: (_) => setState(() => _filter = value));
  }
}

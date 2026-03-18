import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';

/// Screen ID: P4 — Ветконтроль
///
/// Читает участников из [participantsProvider].
/// Все участники отображаются (не только с dogName) — это ездовой спорт.
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

    // All participants — this is ezdovoy sport, everyone has a dog
    final passedCount = participants.where((p) => p.vetStatus == VetStatus.passed).length;
    final pendingCount = participants.where((p) => p.vetStatus == VetStatus.pending).length;
    final failedCount = participants.where((p) => p.vetStatus == VetStatus.failed).length;

    final filtered = participants.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !(p.dogName?.toLowerCase().contains(q) ?? false) &&
            !p.bib.toLowerCase().contains(q) &&
            !p.disciplineName.toLowerCase().contains(q)) {
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
          Badge(label: Text('$failedCount'), child: IconButton(icon: Icon(Icons.warning, color: cs.error), onPressed: () => setState(() => _filter = 'failed'))),
      ]),
      body: Column(children: [
        // ─── Stats bar ───
        AppInfoPanel(
          backgroundColor: cs.surfaceContainerHighest,
          children: [
            AppInfoPanel.stat('$passedCount', 'Прошли', cs.primary),
            AppInfoPanel.stat('$pendingCount', 'Ожидают', cs.tertiary),
            AppInfoPanel.stat('$failedCount', 'Отклонены', cs.error),
          ],
        ),

        // ─── Search + filters ───
        Padding(padding: const EdgeInsets.all(8), child: AppTextField(
          label: 'Поиск по кличке, ФИО, BIB...',
          prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _filterChip(cs, 'Все (${participants.length})', 'all'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Ожидают ($pendingCount)', 'pending'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Прошли ($passedCount)', 'passed'),
            const SizedBox(width: 6),
            _filterChip(cs, 'Отклонены ($failedCount)', 'failed'),
          ]),
        ),
        const SizedBox(height: 4),

        // ─── List ───
        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pets, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(
                participants.isEmpty ? 'Нет участников' : 'Нет совпадений',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _vetCard(context, cs, filtered[i]),
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

  Widget _vetCard(BuildContext context, ColorScheme cs, Participant p) {
    final status = p.vetStatus;
    final borderColor = status == VetStatus.passed ? cs.primary.withValues(alpha: 0.3)
        : status == VetStatus.failed ? cs.error.withValues(alpha: 0.3)
        : cs.outlineVariant.withValues(alpha: 0.2);
    final statusIcon = status == VetStatus.passed ? Icons.check_circle
        : status == VetStatus.failed ? Icons.cancel
        : Icons.hourglass_empty;
    final statusColor = status == VetStatus.passed ? cs.primary
        : status == VetStatus.failed ? cs.error
        : cs.onSurfaceVariant;
    final statusLabel = status == VetStatus.passed ? 'Допущен'
        : status == VetStatus.failed ? 'Не допущен'
        : 'Ожидает';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDogCard(context, cs, p),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          // Dog avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(Icons.pets, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (p.bib.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(p.bib, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.primary)),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(p.dogName ?? 'Собака не указана', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ]),
            const SizedBox(height: 2),
            Text(p.name, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Row(children: [
              Text(p.disciplineName, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              if (p.club != null) ...[
                Text(' · ', style: TextStyle(color: cs.onSurfaceVariant)),
                Text(p.club!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ]),
          ])),
          const SizedBox(width: 8),
          // Status / Action
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(height: 2),
            Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ]),
        ])),
      ),
    );
  }

  void _showDogCard(BuildContext context, ColorScheme cs, Participant p) {
    final vetPassed = p.vetStatus == VetStatus.passed;
    final vetFailed = p.vetStatus == VetStatus.failed;

    AppBottomSheet.show(
      context,
      title: '🐕 ${p.dogName ?? "Собака"} — осмотр',
      initialHeight: 0.65,
      actions: [
        AppButton.primary(
          text: 'Допустить',
          icon: Icons.check,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(participantsProvider.notifier).setVetStatus(p.id, VetStatus.passed);
            AppSnackBar.success(context, '${p.dogName ?? p.name} — допущен к участию');
          },
        ),
        AppButton.smallDanger(
          text: 'Не допустить',
          icon: Icons.close,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            _showRejectDialog(context, cs, p);
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Dog & Owner info ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.secondaryContainer,
            child: Icon(Icons.pets, size: 36, color: cs.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.dogName ?? '—', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Владелец: ${p.name}', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            if (p.club != null)
              Text('Клуб: ${p.club}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            Text('Дисциплина: ${p.disciplineName}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            if (p.bib.isNotEmpty)
              Text('BIB: ${p.bib}', style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.bold)),
          ])),
        ]),
        const SizedBox(height: 16),

        // ── Current status badge ──
        if (vetPassed || vetFailed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (vetPassed ? cs.primary : cs.error).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (vetPassed ? cs.primary : cs.error).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(vetPassed ? Icons.check_circle : Icons.cancel, color: vetPassed ? cs.primary : cs.error),
              const SizedBox(width: 8),
              Text(vetPassed ? 'Допущен к участию' : 'Не допущен', style: TextStyle(fontWeight: FontWeight.bold, color: vetPassed ? cs.primary : cs.error)),
            ]),
          ),
        const SizedBox(height: 16),

        // ── Checklist ──
        Text('Проверка', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),

        _checkRow(cs, 'Ветеринарный паспорт', vetPassed),
        _checkRow(cs, 'Вакцинация (действительна)', vetPassed),
        _checkRow(cs, 'Общее состояние здоровья', vetPassed),
        _checkRow(cs, 'Страховка', p.insuranceNo != null && p.insuranceNo!.isNotEmpty),
        _checkRow(cs, 'Отсутствие агрессии', vetPassed),
        _checkRow(cs, 'Чип / клеймо', vetPassed),

        if (p.insuranceNo != null && p.insuranceNo!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.verified_user, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text('Страховка: ${p.insuranceNo}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _checkRow(ColorScheme cs, String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          size: 20,
          color: checked ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: 14,
          color: checked ? cs.onSurface : cs.onSurfaceVariant,
          decoration: checked ? TextDecoration.lineThrough : null,
        )),
      ]),
    );
  }

  void _showRejectDialog(BuildContext context, ColorScheme cs, Participant p) {
    String? selectedReason;

    AppBottomSheet.show(
      context,
      title: 'Причина отказа — ${p.dogName ?? p.name}',
      initialHeight: 0.55,
      actions: [
        AppButton.danger(
          text: 'Подтвердить отказ',
          icon: Icons.block,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(participantsProvider.notifier).setVetStatus(p.id, VetStatus.failed);
            AppSnackBar.error(context, '${p.dogName ?? p.name} — не допущен');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Выберите причину:', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),

        ...[
          ('vaccine', 'Просрочена вакцинация', Icons.vaccines),
          ('health', 'Проблемы со здоровьем', Icons.healing),
          ('injury', 'Травма', Icons.personal_injury),
          ('aggression', 'Агрессивное поведение', Icons.warning),
          ('docs', 'Отсутствие документов', Icons.description),
          ('other', 'Другое', Icons.more_horiz),
        ].map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => selectedReason = r.$1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selectedReason == r.$1 ? cs.error : cs.outlineVariant.withValues(alpha: 0.3)),
                color: selectedReason == r.$1 ? cs.error.withValues(alpha: 0.05) : null,
              ),
              child: Row(children: [
                Icon(r.$3, size: 20, color: selectedReason == r.$1 ? cs.error : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(r.$2, style: TextStyle(color: selectedReason == r.$1 ? cs.error : cs.onSurface)),
              ]),
            ),
          ),
        )),

        const SizedBox(height: 8),
        AppTextField(
          label: 'Комментарий (необязательно)',
          maxLines: 2,
        ),
      ]),
    );
  }
}

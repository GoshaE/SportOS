import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/event_config.dart';
import '../../../domain/event/config_providers.dart';

/// Screen ID: E3 — Участники (ConsumerWidget → данные из participantsProvider)
class ParticipantsScreen extends ConsumerStatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  ConsumerState<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends ConsumerState<ParticipantsScreen> {
  bool _isTableView = false;
  bool _initialized = false;
  String _filter = 'all'; // 'all', discipline name

  void _showApplicationCard(BuildContext context, Participant p) {
    final cs = Theme.of(context).colorScheme;
    final isPaid = p.paymentStatus == PaymentStatus.paid;
    final isApproved = p.applicationStatus == ApplicationStatus.approved;

    final map = {
      'name': p.name,
      'club': '${p.dogName != null ? "Собака: ${p.dogName} • " : ""}Дисциплина: ${p.disciplineName}',
      'role': 'competitor',
      'bib': p.bib,
    };

    AppUserProfileSheet.show(
      context,
      user: map,
      isOrganizer: true,
      contextActionsBuilder: (innerCtx) => [
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.check_circle, size: 20, color: cs.primary)),
          title: const Text('Статус заявки', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isApproved ? 'Подтверждена' : 'Ожидает подтверждения', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: isApproved
              ? Icon(Icons.check, color: cs.primary)
              : FilledButton.tonal(
                  onPressed: () {
                    ref.read(participantsProvider.notifier).approve(p.id);
                    Navigator.of(context, rootNavigator: true).pop();
                    AppSnackBar.success(context, '${p.name} — заявка подтверждена');
                  },
                  child: const Text('Подтвердить'),
                ),
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle), child: Icon(Icons.payment, size: 20, color: cs.secondary)),
          title: const Text('Оплата', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isPaid ? 'Оплачено (${p.priceRub ?? 0} ₽)' : 'Не оплачено', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: isPaid
              ? Icon(Icons.check, color: cs.primary)
              : FilledButton.tonal(
                  onPressed: () {
                    ref.read(participantsProvider.notifier).markPaid(p.id);
                    Navigator.of(context, rootNavigator: true).pop();
                    AppSnackBar.success(context, '${p.name} — оплата отмечена');
                  },
                  child: const Text('Оплачено'),
                ),
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.tertiaryContainer, shape: BoxShape.circle), child: Icon(Icons.confirmation_number, size: 20, color: cs.tertiary)),
          title: const Text('Стартовый номер', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(p.bib, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showAddParticipant(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final dogCtrl = TextEditingController();
    String? selectedDisc;
    final disciplines = ref.read(disciplineConfigsProvider);

    AppBottomSheet.show(context, title: 'Добавить участника', actions: [
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          if (nameCtrl.text.trim().isEmpty) {
            AppSnackBar.error(context, 'Введите ФИО');
            return;
          }
          final disc = disciplines.where((d) => d.id == selectedDisc).firstOrNull ?? disciplines.first;
          final participants = ref.read(participantsProvider);
          final nextBib = (participants.length + 1).toString().padLeft(2, '0');

          ref.read(participantsProvider.notifier).add(Participant(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            name: nameCtrl.text.trim(),
            phone: contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : null,
            disciplineId: disc.id,
            disciplineName: disc.name,
            bib: nextBib,
            dogName: dogCtrl.text.trim().isNotEmpty ? dogCtrl.text.trim() : null,
            registeredAt: DateTime.now(),
          ));

          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, '${nameCtrl.text.trim()} добавлен');
        },
        child: const Text('Добавить', style: TextStyle(fontSize: 16)),
      )),
    ], child: StatefulBuilder(builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Телефон / Email', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Дисциплина *', border: OutlineInputBorder()),
        items: disciplines.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
        value: selectedDisc,
        onChanged: (v) => setModal(() => selectedDisc = v),
      ),
      const SizedBox(height: 12),
      TextField(controller: dogCtrl, decoration: const InputDecoration(labelText: 'Кличка собаки', border: OutlineInputBorder())),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final w = MediaQuery.of(context).size.width;

    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }

    final allParticipants = ref.watch(participantsProvider);
    final filtered = _filter == 'all'
        ? allParticipants
        : allParticipants.where((p) => p.disciplineName.contains(_filter)).toList();

    // Stats
    final total = allParticipants.length;
    final approved = allParticipants.where((p) => p.applicationStatus == ApplicationStatus.approved).length;
    final pending = allParticipants.where((p) => p.applicationStatus == ApplicationStatus.pending).length;
    final unpaid = allParticipants.where((p) => p.paymentStatus == PaymentStatus.unpaid).length;

    // Unique discipline names for filters
    final discNames = allParticipants.map((p) => p.disciplineName).toSet().toList()..sort();

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Участники'),
        actions: [
          IconButton(icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows), tooltip: 'Вид таблицы', onPressed: () => setState(() => _isTableView = !_isTableView)),
          IconButton(icon: const Icon(Icons.person_add), tooltip: 'Добавить вручную', onPressed: () => _showAddParticipant(context)),
        ],
      ),
      body: Column(children: [
        AppInfoPanel(
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          children: [
            AppInfoPanel.stat('$total', 'Всего', cs.onSurface),
            AppInfoPanel.stat('$approved', 'Подтв.', cs.primary),
            AppInfoPanel.stat('$pending', 'Ожидает', cs.tertiary),
            AppInfoPanel.stat('$unpaid', 'Не опл.', cs.error),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Все'), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
            ...discNames.map((name) => FilterChip(
              label: Text(name),
              selected: _filter == name,
              onSelected: (_) => setState(() => _filter = _filter == name ? 'all' : name),
            )),
          ]),
        ),
        Expanded(
          child: AppProtocolTable(
            forceTableView: _isTableView,
            headerRow: const _ParticipantRow(isHeader: true, participant: null),
            itemCount: filtered.length,
            itemBuilder: (context, index, isCard) {
              final p = filtered[index];
              return _ParticipantRow(
                isCardView: isCard,
                participant: p,
                onTap: () => _showApplicationCard(context, p),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final Participant? participant;
  final bool isHeader;
  final bool isCardView;
  final VoidCallback? onTap;

  const _ParticipantRow({
    required this.participant,
    this.isHeader = false,
    this.isCardView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isHeader) {
      if (isCardView) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 50, child: _headerText('BIB', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 200, child: _headerText('ФИО', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: _headerText('Дисциплина', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: _headerText('Собака', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: _headerText('Оплата', theme, cs)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: _headerText('Статус', theme, cs)),
          ],
        ),
      );
    }

    final p = participant!;
    final isApproved = p.applicationStatus == ApplicationStatus.approved;
    final isPaid = p.paymentStatus == PaymentStatus.paid;

    Widget content;
    if (isCardView) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
                  child: Center(child: Text(p.bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                  child: Text(p.disciplineName, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (p.dogName != null) ...[
                  Icon(Icons.pets, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(p.dogName!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                ] else const Spacer(),
                _statusBadge(cs, isPaid ? 'Оплачено' : 'Не оплачено', isPaid ? cs.primary : cs.error),
                const SizedBox(width: 8),
                _statusBadge(cs, isApproved ? 'Подтвержден' : 'Ожидает', isApproved ? cs.primary : cs.tertiary),
              ],
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 50, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: Text(p.bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            )),
            const SizedBox(width: 16),
            SizedBox(width: 200, child: Text(p.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: Container(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                child: Text(p.disciplineName, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            )),
            const SizedBox(width: 16),
            SizedBox(width: 130, child: Text(p.dogName ?? '—', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(cs, isPaid ? 'Оплачено' : 'Не оплачено', isPaid ? cs.primary : cs.error))),
            const SizedBox(width: 16),
            SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(cs, isApproved ? 'Подтвержден' : 'Ожидает', isApproved ? cs.primary : cs.tertiary))),
          ],
        ),
      );
    }

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _headerText(String text, ThemeData theme, ColorScheme cs) {
    return Text(text, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 0.5));
  }

  Widget _statusBadge(ColorScheme cs, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

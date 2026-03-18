import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/event/config_providers.dart';
import '../../../../domain/event/event_config.dart';

/// Unified hero card for the event overview dashboard.
///
/// Displays race status, key KPIs (participants, check-in, revenue),
/// days until start, and a primary action button to advance the event status.
class EventHeroCard extends ConsumerWidget {
  const EventHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final eventConfig = ref.watch(eventConfigProvider);
    final participants = ref.watch(participantsProvider);
    final totalParticipants = participants.length;
    final daysUntilStart = eventConfig.startDate.difference(DateTime.now()).inDays;
    final daysLabel = daysUntilStart > 0
        ? '$daysUntilStart дн.'
        : daysUntilStart == 0
            ? 'Сегодня!'
            : 'Прошло';

    final paidParticipants = participants.where((p) => p.paymentStatus == PaymentStatus.paid).toList();
    final revenue = paidParticipants.fold<int>(0, (sum, p) => sum + (p.priceRub ?? 0));
    final revenueStr = revenue >= 1000 ? '${(revenue / 1000).toStringAsFixed(1)}К ₽' : '$revenue ₽';
    final checkedIn = participants.where((p) => p.checkInTime != null).length;

    // Status mapping
    final (statusLabel, _, statusIcon, statusColor) = switch (eventConfig.status) {
      EventStatus.draft => ('Черновик', 'Не видно участникам', Icons.edit_note, cs.outline),
      EventStatus.registrationOpen => ('Регистрация открыта', 'Принимаем заявки', Icons.how_to_reg, const Color(0xFF2E7D32)),
      EventStatus.registrationClosed => ('Регистрация закрыта', 'Финальная подготовка', Icons.lock_outline, const Color(0xFFE65100)),
      EventStatus.inProgress => ('Гонка идёт', 'Хронометраж активен', Icons.play_circle, cs.primary),
      EventStatus.completed => ('Завершено', 'Протоколы готовы', Icons.check_circle, const Color(0xFF1565C0)),
      EventStatus.archived => ('Архив', '', Icons.archive, cs.outline),
    };

    final (nextLabel, nextStatus) = switch (eventConfig.status) {
      EventStatus.draft => ('Открыть регистрацию', EventStatus.registrationOpen),
      EventStatus.registrationOpen => ('Закрыть регистрацию', EventStatus.registrationClosed),
      EventStatus.registrationClosed => ('Начать гонку', EventStatus.inProgress),
      EventStatus.inProgress => ('Завершить', EventStatus.completed),
      EventStatus.completed => ('Архивировать', EventStatus.archived),
      EventStatus.archived => (null, null),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.12),
            cs.surfaceContainerHigh.withValues(alpha: isDark ? 0.6 : 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        // ── Status row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              daysLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: daysUntilStart == 0 ? cs.primary : cs.onSurface,
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── KPI metrics row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _HeroKpi(icon: Icons.groups, value: '$totalParticipants', label: 'Участники', color: cs.primary),
            Container(width: 1, height: 40, color: cs.outlineVariant.withValues(alpha: 0.3)),
            _HeroKpi(icon: Icons.how_to_reg, value: '$checkedIn / $totalParticipants', label: 'Чек-ин', color: const Color(0xFF2E7D32)),
            Container(width: 1, height: 40, color: cs.outlineVariant.withValues(alpha: 0.3)),
            _HeroKpi(icon: Icons.payments, value: revenueStr, label: 'Сборы', color: cs.tertiary),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Next status action ──
        if (nextLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  nextStatus == EventStatus.inProgress ? Icons.play_arrow : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => ref.read(eventConfigProvider.notifier).update(
                  (c) => c.copyWith(status: nextStatus),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 14),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1),
      ]),
    );
  }
}

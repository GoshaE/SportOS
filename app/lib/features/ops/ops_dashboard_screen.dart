import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../core/widgets/app_app_bar.dart';
import '../../domain/event/config_providers.dart';
import '../../domain/event/event_config.dart';
import '../../domain/timing/timing.dart';

/// Ops Dashboard — the central command screen for the judge/organizer.
///
/// Reads from [eventConfigProvider], [participantsProvider], [raceSessionProvider],
/// [disciplineConfigsProvider] for real data.
class OpsDashboardScreen extends ConsumerWidget {
  const OpsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    final config = ref.watch(eventConfigProvider);
    final participants = ref.watch(participantsProvider);
    final session = ref.watch(raceSessionProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);

    // Computed KPIs
    final total = participants.length;
    final checkedIn = participants.where((p) => p.checkInTime != null).length;
    final onCourse = session?.onCourseAthletes.length ?? 0;
    final started = session?.startedAthletes.length ?? 0;
    final finished = started - onCourse;

    // Status label
    final statusLabel = switch (config.status) {
      EventStatus.draft => 'Черновик',
      EventStatus.registrationOpen => 'Регистрация',
      EventStatus.registrationClosed => 'Подготовка',
      EventStatus.inProgress => 'ГОНКА ИДЁТ',
      EventStatus.completed => 'Завершено',
      EventStatus.archived => 'Архив',
    };

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Дашборд Судьи'),
        onBackButtonPressed: () => context.go('/hub/event/$eventId'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Title & Status ──
          Text(config.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(statusLabel, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            if (disciplines.isNotEmpty)
              Text('${disciplines.first.name} · День 1', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 20),

          // ── Race Status Banner ──
          _buildRaceStatusBanner(cs, config),
          const SizedBox(height: 16),

          // ── KPI Grid (dynamic) ──
          Row(children: [
            Expanded(child: AppStatCard(value: '$total', label: 'Всего', icon: Icons.groups)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '$checkedIn', label: 'Чек-ин', icon: Icons.check_circle)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '$onCourse', label: 'На трассе', icon: Icons.flag, color: cs.tertiary)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '$finished', label: 'Финиш', icon: Icons.emoji_events, color: cs.secondary)),
          ]),
          const SizedBox(height: 16),

          // ── Readiness summary ──
          AppSectionHeader(title: 'Готовность', icon: Icons.checklist),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _readinessRow(cs, 'Мандатная комиссия',
              '${participants.where((p) => p.mandateStatus == MandateStatus.passed).length} из $total допущено',
              participants.every((p) => p.mandateStatus == MandateStatus.passed),
            ),
            Divider(height: 24, color: cs.outlineVariant.withOpacity(0.3)),
            _readinessRow(cs, 'Ветконтроль',
              '${participants.where((p) => p.vetStatus == VetStatus.passed).length} из $total прошли',
              participants.every((p) => p.vetStatus == VetStatus.passed),
            ),
            Divider(height: 24, color: cs.outlineVariant.withOpacity(0.3)),
            _readinessRow(cs, 'BIB номера',
              '${participants.where((p) => p.bib.isNotEmpty).length} из $total назначено',
              participants.every((p) => p.bib.isNotEmpty),
            ),
            Divider(height: 24, color: cs.outlineVariant.withOpacity(0.3)),
            _readinessRow(cs, 'Оплата',
              '${participants.where((p) => p.paymentStatus == PaymentStatus.paid).length} из $total оплачено',
              participants.every((p) => p.paymentStatus == PaymentStatus.paid),
            ),
          ]))),
          const SizedBox(height: 16),

          // ── Sync & Network ──
          AppSectionHeader(title: 'Связь и синхронизация', icon: Icons.cell_tower),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            AppSyncRow(name: 'Мастер-Нода (Финиш)', status: 'Ожидание', detail: '—', color: cs.onSurfaceVariant),
            Divider(height: 24, color: cs.outlineVariant.withOpacity(0.3)),
            AppSyncRow(name: 'Пост Старт', status: 'Ожидание', detail: '—', color: cs.onSurfaceVariant),
            Divider(height: 24, color: cs.outlineVariant.withOpacity(0.3)),
            AppSyncRow(name: 'Облако (Supabase)', status: 'Ожидание', detail: '—', color: cs.onSurfaceVariant),
          ]))),
          const SizedBox(height: 16),

          // ── Schedule (from disciplines) ──
          AppSectionHeader(title: 'Расписание дня', icon: Icons.schedule),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            if (disciplines.isEmpty)
              const Text('Нет дисциплин в расписании')
            else
              ...disciplines.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final time = '${d.firstStartTime.hour.toString().padLeft(2, '0')}:${d.firstStartTime.minute.toString().padLeft(2, '0')}';
                return AppTimelineRow(
                  time: time,
                  title: d.name,
                  isFirst: i == 0,
                  isLast: i == disciplines.length - 1,
                  isCurrent: config.status == EventStatus.inProgress && i == 0,
                  isPast: config.status == EventStatus.completed,
                );
              }),
          ]))),
          const SizedBox(height: 16),

          // ── Quick Actions ──
          AppSectionHeader(title: 'Быстрые действия', icon: Icons.bolt),
          Row(children: [
            Expanded(child: AppActionTile(icon: Icons.campaign, label: 'Push-уведомление', color: cs.primary, onTap: () {})),
            const SizedBox(width: 8),
            Expanded(child: AppActionTile(icon: Icons.pause_circle, label: 'Пауза гонки', color: cs.tertiary, onTap: () {})),
            const SizedBox(width: 8),
            Expanded(child: AppActionTile(icon: Icons.flag, label: 'Красный флаг', color: cs.error, onTap: () {})),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRaceStatusBanner(ColorScheme cs, EventConfig config) {
    final isLive = config.status == EventStatus.inProgress;
    final label = isLive ? 'ГОНКА ИДЁТ' : 'Подготовка к старту';
    final subtitle = isLive ? 'Хронометраж активен' : 'Убедитесь что все пункты готовности выполнены';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          isLive ? cs.primary : cs.surfaceContainerHighest,
          isLive ? cs.primary.withOpacity(0.8) : cs.surfaceContainerHighest.withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(isLive ? Icons.play_circle_filled : Icons.schedule, color: isLive ? cs.onPrimary : cs.onSurface, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: isLive ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: (isLive ? cs.onPrimary : cs.onSurfaceVariant).withOpacity(0.7), fontSize: 13)),
        ])),
      ]),
    );
  }

  Widget _readinessRow(ColorScheme cs, String title, String subtitle, bool isDone) {
    return Row(children: [
      Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? cs.primary : cs.onSurfaceVariant, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

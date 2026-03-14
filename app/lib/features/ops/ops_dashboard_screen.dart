import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../core/widgets/app_app_bar.dart'; // Added import

/// Ops Dashboard — the central command screen for the judge/organizer.
class OpsDashboardScreen extends StatelessWidget {
  const OpsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: const AppAppBar(
        title: Text('Дашборд Судьи'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Title & Role ──
          Text('Чемпионат Урала 2026', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Главный судья', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Text('Скиджоринг 5км · День 1', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 20),

          // ── Race Status Banner ──
          _buildRaceStatusBanner(cs, theme),
          const SizedBox(height: 16),

          // ── Readiness Grid ──
          Row(children: [
            Expanded(child: AppStatCard(value: '48', label: 'Всего', icon: Icons.groups)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '35', label: 'Чек-ин', icon: Icons.check_circle)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '12', label: 'На старте', icon: Icons.flag, color: cs.tertiary)),
            const SizedBox(width: 8),
            Expanded(child: AppStatCard(value: '8', label: 'Финишировали', icon: Icons.emoji_events, color: cs.secondary)),
          ]),
          const SizedBox(height: 16),

          // ── Sync & Network ──
          AppSectionHeader(title: 'Связь и синхронизация', icon: Icons.cell_tower),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            AppSyncRow(name: 'Мастер-Нода (Финиш)', status: 'Онлайн', detail: 'Δt = +0.003с', color: cs.primary),
            Divider(height: 24, color: cs.outlineVariant.withValues(alpha: 0.3)),
            AppSyncRow(name: 'Пост Старт', status: 'Онлайн', detail: 'Δt = +0.012с', color: cs.primary),
            Divider(height: 24, color: cs.outlineVariant.withValues(alpha: 0.3)),
            AppSyncRow(name: 'Пост Маршал (КП1)', status: 'Слабый сигнал', detail: 'Δt = +0.045с', color: cs.tertiary),
            Divider(height: 24, color: cs.outlineVariant.withValues(alpha: 0.3)),
            AppSyncRow(name: 'Облако (Supabase)', status: 'Синхронизировано', detail: '2 мин назад', color: cs.primary),
          ]))),
          const SizedBox(height: 16),

          // ── Weather ──
          AppSectionHeader(title: 'Погода на трассе', icon: Icons.wb_sunny),
          _buildWeatherCard(cs, theme),
          const SizedBox(height: 16),

          // ── Timeline ──
          AppSectionHeader(title: 'Расписание дня', icon: Icons.schedule),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const AppTimelineRow(time: '08:00', title: 'Регистрация и чек-ин', isPast: true, isFirst: true),
            const AppTimelineRow(time: '09:00', title: 'Брифинг и ветконтроль', isPast: true),
            const AppTimelineRow(time: '10:00', title: 'Старт — Скиджоринг 5 км', isPast: true),
            const AppTimelineRow(time: '11:30', title: 'Старт — Каникросс 3 км', isCurrent: true),
            const AppTimelineRow(time: '13:00', title: 'Награждение', isLast: true),
          ]))),
          const SizedBox(height: 16),

          // ── Incidents ──
          AppSectionHeader(title: 'Инциденты', icon: Icons.warning_amber),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.gavel, color: cs.tertiary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('0 протестов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Всё чисто', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.medical_services, color: cs.error),
                  const SizedBox(width: 12),
                  const Text('0 мед. случаев', style: TextStyle(fontSize: 14)),
                ]),
              ]),
            ),
          ),
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
  Widget _buildRaceStatusBanner(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.play_circle_filled, color: cs.onPrimary, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ГОНКА ИДЁТ', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text('Старт дан в 10:00 · Прошло: 1ч 24мин', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.7), fontSize: 13)),
        ])),
      ]),
    );
  }

  Widget _buildWeatherCard(ColorScheme cs, ThemeData theme) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      const Text('☀️', style: TextStyle(fontSize: 36)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('-8°C · Ясно', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Ветер: 3 м/с ЮВ · Влажность: 45%', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Text('Снег: плотный, укатанный', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ])),
    ])));
  }
}

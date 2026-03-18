import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/timing/timing.dart';
import '../../ui/molecules/app_list_row.dart';
import '../../ui/molecules/app_chip_group.dart';

/// Screen ID: R4 — Диктор (с тап на атлета → карточка)
class DictatorScreen extends ConsumerStatefulWidget {
  const DictatorScreen({super.key});

  @override
  ConsumerState<DictatorScreen> createState() => _DictatorScreenState();
}

class _DictatorScreenState extends ConsumerState<DictatorScreen> {
  String? _disc;
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(raceSessionProvider);
      if (session != null && session.clock.isRunning) {
        setState(() => _elapsed = session.clock.elapsed);
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Athlete card
  // ═══════════════════════════════════════

  void _showAthleteCard(BuildContext context, RaceResult result) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final position = '${result.position}-е место';
    final netStr = _fmtDur(result.netTime);

    // Split times from result
    final splitDurations = result.splitTimes;

    AppBottomSheet.show(
      context,
      title: 'BIB ${result.bib} — ${result.name}',
      initialHeight: 0.65,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: cs.primaryContainer, child: Text(result.bib, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('$position · $netStr', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 24),

        // Собака
        Text('Собака', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            AppListRow.status(
              title: 'Rex',
              subtitle: 'Сибирский хаски · 4 года',
              semantic: RowSemantic.success,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Split-times
        Text('Split-times по кругам', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            for (var i = 0; i < splitDurations.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              AppSplitRow(
                label: 'Круг ${i + 1}',
                time: _fmtDurMs(splitDurations[i]),
                delta: i == 0 ? null : _formatDelta(splitDurations[i] - splitDurations[i - 1]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // История
        Text('История стартов', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          children: [
            ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Text('🥈', style: TextStyle(fontSize: 20)), title: const Text('Кубок Сибири 2025'), subtitle: Text('Скидж. 10км — 01:12:45', style: TextStyle(color: cs.onSurfaceVariant))),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Text('🥉', style: TextStyle(fontSize: 20)), title: const Text('Кубок Урала 2025'), subtitle: Text('Скидж. 5км — 00:40:20', style: TextStyle(color: cs.onSurfaceVariant))),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtDur(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtDurMs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '00:$m:$s';
  }

  String? _formatDelta(Duration delta) {
    final sign = delta.isNegative ? '-' : '+';
    final abs = delta.abs();
    return '$sign${abs.inSeconds}с';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Диктор')),
        body: const Center(child: Text('Нет активной сессии.')),
      );
    }

    final results = session.calculateResults();
    final finishedCount = session.marking.finishedCount;
    final courseAthletes = session.onCourseAthletes;
    final onTrackCount = session.startedAthletes.length;  // только реально на трассе
    final totalAthletes = courseAthletes.length;

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Диктор'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.error, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(children: [
        // ── Инфо-панель ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(children: [
                Icon(Icons.mic, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Live трансляция', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.directions_run, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('$finishedCount/$totalAthletes финишировали', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                Icon(Icons.timer, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text(TimeFormatter.compact(_elapsed), style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
              ]),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: AppChipGroup(
            items: [session.config.name],
            selected: _disc ?? session.config.name,
            onSelected: (v) => setState(() => _disc = v),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),

        // ── ТОП-5 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('ТОП-5', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...List.generate(results.length.clamp(0, 5), (i) {
          final result = results[i];
          final medal = switch (i) { 0 => '🥇', 1 => '🥈', 2 => '🥉', _ => null };
          final bool isTop3 = i < 3;
          final netStr = _fmtDur(result.netTime);
          final gapStr = result.gapToLeader != null ? '+${_fmtDur(result.gapToLeader!)}' : '—';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: AppCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              backgroundColor: isTop3 ? cs.primaryContainer.withValues(alpha: 0.08 * (3 - i)) : cs.surface,
              borderColor: isTop3 ? cs.primary.withValues(alpha: 0.2 * (3 - i)) : cs.outlineVariant.withValues(alpha: 0.3),
              children: [
                ListTile(
                  dense: true,
                  leading: medal != null
                    ? Text(medal, style: const TextStyle(fontSize: 22))
                    : SizedBox(width: 28, child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                  title: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                      child: Text(result.bib, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.name, style: TextStyle(fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal))),
                  ]),
                  subtitle: Row(children: [
                    Text(netStr, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: i == 0 ? cs.primary : null)),
                    if (gapStr != '—') ...[const SizedBox(width: 8), Text(gapStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))],
                  ]),
                  trailing: Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                  onTap: () => _showAthleteCard(context, result),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // ── Последний финиш и На трассе (Bento Grid) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
                borderColor: cs.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(children: [
                    Icon(Icons.flag, color: cs.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Последний финиш', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
                  ]),
                  const SizedBox(height: 8),
                  if (results.isNotEmpty) ...[
                    Text('BIB ${results.last.bib} ${results.last.name.split(' ').first}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_fmtDur(results.last.netTime)} (${results.last.position}-е место)', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.15),
                borderColor: cs.tertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(children: [
                    Icon(Icons.timeline, color: cs.tertiary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text('На трассе: $onTrackCount', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary))),
                  ]),
                  const SizedBox(height: 8),
                  Text('Ожидается финиш', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('$onTrackCount участников', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Подсказки для диктора ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text('Подсказки', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        ),
        if (results.length >= 3)
          _hintCard(cs, theme, Icons.local_fire_department, 'BIB ${results[2].bib} вошёл в ТОП-3!', cs.tertiary),
        if (results.length > 1)
          _hintCard(cs, theme, Icons.emoji_events, '${results.first.name} лидирует с отрывом +${_fmtDur(results[1].gapToLeader ?? Duration.zero)}', cs.primary),
        if (results.isNotEmpty)
          _hintCard(cs, theme, Icons.trending_up, 'Средняя скорость лидера: ${results.first.speedKmh?.toStringAsFixed(1) ?? '?'} км/ч', cs.onSurfaceVariant),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _hintCard(ColorScheme cs, ThemeData theme, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: color.withValues(alpha: 0.06),
        borderColor: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500))),
          ]),
        ],
      ),
    );
  }
}

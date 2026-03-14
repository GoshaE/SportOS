import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: R4 — Диктор (с тап на атлета → карточка)
class DictatorScreen extends StatefulWidget {
  const DictatorScreen({super.key});

  @override
  State<DictatorScreen> createState() => _DictatorScreenState();
}

class _DictatorScreenState extends State<DictatorScreen> {
  String _disc = 'Sprint 5km';

  void _showAthleteCard(BuildContext context, String bib, String name, String time, String place) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    AppBottomSheet.show(
      context,
      title: 'BIB $bib — $name',
      initialHeight: 0.65,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: cs.primaryContainer, child: Text(bib, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('$place · $time', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text('Клуб: Хаски Урал · Екатеринбург', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
            AppStatusRow(
              icon: Icons.pets,
              title: 'Rex',
              subtitle: 'Сибирский хаски · 4 года',
              contentPadding: EdgeInsets.zero,
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
            const AppSplitRow(label: 'Круг 1', time: '00:12:45'),
            const SizedBox(height: 8),
            const AppSplitRow(label: 'Круг 2', time: '00:12:30', delta: '-15с'),
            const SizedBox(height: 8),
            const AppSplitRow(label: 'Круг 3', time: '00:12:57', delta: '+12с'),
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final top5 = [
      {'bib': '07', 'name': 'Петров А.А.', 'time': '00:38:12', 'delta': '—'},
      {'bib': '24', 'name': 'Иванов В.В.', 'time': '00:39:45', 'delta': '+1:33'},
      {'bib': '55', 'name': 'Волков Е.Е.', 'time': '00:41:02', 'delta': '+2:50'},
      {'bib': '12', 'name': 'Сидоров Б.Б.', 'time': '00:41:33', 'delta': '+3:21'},
      {'bib': '77', 'name': 'Новиков З.З.', 'time': '00:42:15', 'delta': '+4:03'},
    ];

    return Scaffold(
      appBar: AppAppBar(
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
                Text('23/35 финишировали', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: AppDisciplineChips(
            items: const ['Sprint 5km', 'Sprint 10km', 'Каникросс', 'Нарты'],
            selected: _disc,
            onSelected: (v) => setState(() => _disc = v),
          ),
        ),

        // ── ТОП-5 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('ТОП-5', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...List.generate(top5.length, (i) {
          final a = top5[i];
          final medal = switch (i) { 0 => '🥇', 1 => '🥈', 2 => '🥉', _ => null };
          final bool isTop3 = i < 3;
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
                      child: Text(a['bib']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a['name']!, style: TextStyle(fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal))),
                  ]),
                  subtitle: Row(children: [
                    Text(a['time']!, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: i == 0 ? cs.primary : null)),
                    if (a['delta'] != '—') ...[const SizedBox(width: 8), Text(a['delta']!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))],
                  ]),
                  trailing: Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                  onTap: () => _showAthleteCard(context, a['bib']!, a['name']!, a['time']!, '${i + 1}-е место'),
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
                  Text('BIB 77 Новиков', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('00:42:15 (5-е место)', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
                    Expanded(child: Text('На трассе: 12', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary))),
                  ]),
                  const SizedBox(height: 8),
                  Text('~2 мин до финиша', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('BIB 42 Морозов', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
        _hintCard(cs, theme, Icons.local_fire_department, 'BIB 55 вошёл в ТОП-3! Поднялся с 7-го места!', cs.tertiary),
        _hintCard(cs, theme, Icons.timer, 'Последний на трассе: BIB 88 Кузнецов — на 2-м кругу', cs.primary),
        _hintCard(cs, theme, Icons.emoji_events, 'Петров А.А. лидирует с отрывом +1:33', cs.primary),
        _hintCard(cs, theme, Icons.trending_up, 'Средняя скорость лидера: 15.3 км/ч', cs.onSurfaceVariant),
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

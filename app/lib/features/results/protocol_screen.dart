import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../ui/molecules/app_chip_group.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/app_podium_view.dart';
import '../../domain/timing/timing.dart';

/// Screen ID: RS2 — Протоколы (данные из ResultCalculator или демо)
class ProtocolScreen extends ConsumerStatefulWidget {
  const ProtocolScreen({super.key});

  @override
  ConsumerState<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends ConsumerState<ProtocolScreen> {
  String _disc = '';
  int _currentDay = 1;
  final int _totalDays = 2;
  bool _showCards = false;

  static const _tableBuilder = ResultTableBuilder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);

    // Если есть активная сессия — реальные результаты
    List<RaceResult> results;
    String discName;
    List<String> discNames;

    if (session != null) {
      results = session.calculateResults();
      discName = session.config.name;
      discNames = [discName];
      if (_disc.isEmpty) _disc = discName;
    } else {
      // Нет активной сессии — протокол пуст (формируется только во время / после гонки)
      results = [];
      discName = '';
      discNames = [];
    }

    // Stats
    final finished = results.where((r) => r.status == AthleteStatus.finished).length;
    final dnf = results.where((r) => r.status == AthleteStatus.dnf).length;
    final dns = results.where((r) => r.status == AthleteStatus.dns).length;
    final total = results.length;

    // Podium
    final podium = results.where((r) => r.position <= 3).toList();

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Протоколы'),
        actions: [
          IconButton(
            icon: Icon(_showCards ? Icons.table_rows : Icons.view_agenda_outlined),
            tooltip: _showCards ? 'Табличный вид' : 'Карточки',
            onPressed: () {
              setState(() => _showCards = !_showCards);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Экспорт PDF с печатями')),
              PopupMenuItem(value: 'csv', child: Text('Экспорт CSV (Excel)')),
              PopupMenuItem(value: 'json', child: Text('Экспорт JSON (API)')),
            ],
            onSelected: (v) {
              if (v == 'pdf') {
                _showPdfExport();
              } else {
                AppSnackBar.success(context, 'Экспорт $v запущен...');
              }
            },
          ),
        ],
      ),
      body: session == null
          // ── Нет активной сессии ──
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.assignment_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Протоколы пока не сформированы', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text('Протоколы формируются во время или после гонки', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
              ),
            ]))
          // ── Есть сессия — полный UI ──
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Multi-day + Дисциплины ──
                Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_totalDays > 1) ...[
                      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                        Icon(Icons.calendar_month, size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        ...List.generate(_totalDays, (d) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('День ${d + 1}', style: const TextStyle(fontSize: 12)),
                            selected: _currentDay == d + 1,
                            onSelected: (_) => setState(() => _currentDay = d + 1),
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
                        ChoiceChip(
                          label: Text('Общий', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _currentDay == 0 ? null : cs.tertiary)),
                          selected: _currentDay == 0,
                          onSelected: (_) => setState(() => _currentDay = 0),
                          visualDensity: VisualDensity.compact,
                        ),
                      ])),
                      const SizedBox(height: 6),
                    ],
                    AppChipGroup(
                      items: discNames,
                      selected: _disc,
                      onSelected: (v) => setState(() => _disc = v),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),

                // ── Статус протокола ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: (session.isApproved)
                    ? _buildApprovedBanner(cs, theme, session.approvedAt)
                    : _buildUnapprovedBanner(cs, theme, hasSession: true),
                ),

                // ── Сводка (реальные данные) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    _statPill(cs, theme, '$finished', 'Финиш', cs.primary),
                    const SizedBox(width: 4),
                    _statPill(cs, theme, '$dnf', 'DNF', cs.error),
                    const SizedBox(width: 4),
                    _statPill(cs, theme, '$dns', 'DNS', cs.onSurfaceVariant),
                    const Spacer(),
                    Text('Участников: $total', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(height: 8),

                // ── Источник данных ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.stream, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Text('Данные из активной сессии хронометража', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Пьедестал Почета (ТОП-3) ──
          if (podium.isNotEmpty)
            SliverToBoxAdapter(
              child: AppPodiumView(
                athletes: podium.map((r) => PodiumAthlete(
                  place: r.position,
                  name: r.name,
                  bib: r.bib,
                  time: TimeFormatter.compact(r.netTime),
                  dog: '',
                  delta: r.gapToLeader != null ? '+${TimeFormatter.compact(r.gapToLeader!)}' : '—',
                )).toList(),
              ),
            ),

          // ── Таблица результатов ──
          if (results.isNotEmpty)
            SliverToBoxAdapter(
              child: Builder(builder: (context) {
                final table = _tableBuilder.build(
                  results: results,
                  config: session.config,
                  display: session.config.displaySettings,
                  athletes: session.startList.all,
                  marks: session.marking.officialMarks,
                );
                return AppResultTable(
                  table: table,
                  showCards: _showCards,
                  onRowTap: (row) {
                    final r = results.where((r) => r.entryId == row.entryId).firstOrNull;
                    if (r != null) _showAthleteCard(context, r);
                  },
                );
              }),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_empty, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text('Ожидание результатов...', style: TextStyle(color: cs.onSurfaceVariant)),
              ])),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Подписи ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Подписи', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: AppSignatureRow(role: 'Главный судья', name: 'Иванов П.', signed: session.isApproved)),
                    Expanded(child: AppSignatureRow(role: 'Секретарь', name: 'Смирнова А.', signed: session.isApproved)),
                  ]),
                ]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }



  // ─────────────────────────────────────
  // ВИДЖЕТЫ
  // ─────────────────────────────────────

  Widget _buildApprovedBanner(ColorScheme cs, ThemeData theme, DateTime? approvedAt) {
    final dateStr = approvedAt != null
        ? '${approvedAt.day.toString().padLeft(2, '0')}.${approvedAt.month.toString().padLeft(2, '0')}.${approvedAt.year} ${approvedAt.hour.toString().padLeft(2, '0')}:${approvedAt.minute.toString().padLeft(2, '0')}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary.withValues(alpha: 0.08), cs.primary.withValues(alpha: 0.02)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.verified, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Official — Утверждён', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
          Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          if (_currentDay == 0) Text('Общий зачёт: сумма дней', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            ref.read(raceSessionProvider.notifier).revokeApproval();
            AppSnackBar.info(context, 'Утверждение отозвано');
          },
          icon: const Icon(Icons.undo, size: 16),
          label: const Text('Отозвать'),
        ),
      ]),
    );
  }

  Widget _buildUnapprovedBanner(ColorScheme cs, ThemeData theme, {bool hasSession = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.tertiary.withValues(alpha: 0.08), cs.tertiary.withValues(alpha: 0.02)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.hourglass_top, color: cs.tertiary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Unofficial — Предварительный', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary)),
          if (_currentDay == 0) Text('Общий зачёт: сумма дней', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
        if (hasSession) ...[
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _showApprove,
            icon: const Icon(Icons.verified, size: 16),
            label: const Text('Утвердить'),
          ),
        ],
      ]),
    );
  }

  Widget _statPill(ColorScheme cs, ThemeData theme, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ]),
    );
  }

  // ─────────────────────────────────────
  // МОДАЛКИ
  // ─────────────────────────────────────

  void _showAthleteCard(BuildContext context, RaceResult r) {
    final timeStr = r.status == AthleteStatus.finished
        ? TimeFormatter.compact(r.resultTime)
        : r.status.name.toUpperCase();

    AppBottomSheet.show(
      context,
      title: 'Карточка участника',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                child: Text(r.bib, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Место: ${r.position}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 24),
          if (r.splitTimes.isNotEmpty || r.lapTimes.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Детали кругов', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (r.lapTimes.isNotEmpty)
                  ...r.lapTimes.asMap().entries.map((e) =>
                    AppSplitRow(label: 'Круг ${e.key + 1}', time: TimeFormatter.compact(e.value)),
                  )
                else if (r.splitTimes.isNotEmpty)
                  ...r.splitTimes.asMap().entries.map((e) =>
                    AppSplitRow(label: 'Сплит ${e.key + 1}', time: TimeFormatter.compact(e.value)),
                  ),
                if (r.penaltyTime > Duration.zero) ...[
                  const Divider(),
                  AppSplitRow(label: 'Штрафы', time: '+${TimeFormatter.compact(r.penaltyTime)}'),
                ],
              ],
            )
          else
            const AppCard(
              padding: EdgeInsets.all(16),
              children: [
                Text('Детали кругов', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Нет данных о кругах'),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showApprove() {
    AppBottomSheet.show(
      context,
      title: 'Утвердить протокол?',
      initialHeight: 0.55,
      actions: [
        AppButton.primary(
          text: 'Подписать',
          icon: Icons.edit_document,
          onPressed: () {
            ref.read(raceSessionProvider.notifier).approveResults();
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Протокол успешно утверждён');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Протокол будет подписан ключом Ed25519 и станет официальным.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          AppInfoBanner.info(title: 'После утверждения изменения возможны только через протест.'),
          const SizedBox(height: 16),
          const AppCard(
            padding: EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'PIN электронной подписи',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPdfExport() {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Экспорт PDF',
      initialHeight: 0.65,
      actions: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'PDF сгенерирован и сохранён');
          },
          icon: const Icon(Icons.share),
          label: const Text('Поделиться / Сохранить'),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(children: [
            const SizedBox(height: 16),
            Text('ОФИЦИАЛЬНЫЙ ПРОТОКОЛ', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('Чемпионат Урала 2026', style: Theme.of(context).textTheme.bodySmall),
            Text('Дисциплина: $_disc', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _previewSignature('Главный судья', 'Иванов П.К.', ref.read(raceSessionProvider)?.isApproved ?? false, cs),
                _previewSignature('Секретарь', 'Смирнова А.А.', ref.read(raceSessionProvider)?.isApproved ?? false, cs),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Настройки документа', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
          title: const Text('Добавить QR-коды подписей (ЭЦП)'),
          value: ref.read(raceSessionProvider)?.isApproved ?? false,
          onChanged: (ref.read(raceSessionProvider)?.isApproved ?? false) ? (_) {} : null,
          subtitle: !(ref.read(raceSessionProvider)?.isApproved ?? false) ? Text('Сначала утвердите протокол', style: TextStyle(color: cs.error)) : null,
        ),
        CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
          title: const Text('Включать логотипы спонсоров'),
          value: true, onChanged: (_) {},
        ),
      ]),
    );
  }

  Widget _previewSignature(String role, String name, bool signed, ColorScheme cs) {
    return Column(children: [
      Text(role, style: const TextStyle(fontSize: 8)),
      const SizedBox(height: 4),
      if (signed) Icon(Icons.qr_code_2, size: 24, color: cs.primary) else Container(height: 24, width: 24, color: cs.surfaceContainerHighest),
      const SizedBox(height: 4),
      Text(name, style: const TextStyle(fontSize: 8, fontStyle: FontStyle.italic)),
    ]);
  }
}

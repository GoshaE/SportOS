import 'package:flutter/material.dart';


import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/app_podium_view.dart';

class _AthleteData {
  final int? place;
  final String bib;
  final String name;
  final String cat;
  final String dog;
  final String time;
  final String delta;
  final String penalty;
  final String? avatarUrl;

  const _AthleteData({
    this.place,
    required this.bib,
    required this.name,
    required this.cat,
    required this.dog,
    required this.time,
    required this.delta,
    required this.penalty,
    this.avatarUrl,
  });
}

/// Screen ID: RS2 — Протоколы (утверждение + подпись + экспорт + multi-day)
class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  String _disc = 'Скиджоринг 5км';
  bool _approved = false;
  int _currentDay = 1;
  final int _totalDays = 2;
  bool? _isTableView;

  final List<_AthleteData> _fakeData = [
    _AthleteData(place: 1, bib: '07', name: 'Петров А.', cat: 'M 25', dog: 'Rex', time: '00:38:12', delta: '—', penalty: '—', avatarUrl: 'assets/images/avatar1.jpeg'),
    _AthleteData(place: 2, bib: '24', name: 'Иванов В.', cat: 'M 25', dog: 'Storm', time: '00:39:45', delta: '+1:33', penalty: '—', avatarUrl: 'assets/images/avatar2.jpg'),
    _AthleteData(place: 3, bib: '55', name: 'Волков Е.', cat: 'M 35', dog: 'Alaska', time: '00:41:02', delta: '+2:50', penalty: '—', avatarUrl: 'assets/images/avatar3.jpeg'),
    _AthleteData(place: 4, bib: '12', name: 'Сидоров Б.', cat: 'M 25', dog: 'Luna', time: '00:41:33', delta: '+3:21', penalty: '+5с', avatarUrl: 'assets/images/avatar4.jpeg'),
    _AthleteData(place: 5, bib: '77', name: 'Новиков З.', cat: 'Ж 25', dog: 'Rocky', time: '00:42:15', delta: '+4:03', penalty: '—', avatarUrl: 'assets/images/avatar5.jpeg'),
    _AthleteData(place: 6, bib: '63', name: 'Лебедев Ж.', cat: 'M 25', dog: 'Max', time: '—', delta: '—', penalty: '—', avatarUrl: 'assets/images/avatar6.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Протоколы'),
        actions: [
          IconButton(
            icon: Icon(_isTableView == true ? Icons.grid_view : Icons.table_rows),
            tooltip: _isTableView == true ? 'Плиточный вид' : 'Табличный вид',
            onPressed: () {
              setState(() => _isTableView = !(_isTableView ?? true));
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
      body: CustomScrollView(
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
                    AppDisciplineChips(
                      items: const ['Скиджоринг 5км', 'Скиджоринг 10км', 'Каникросс 3км', 'Нарты 15км'],
                      selected: _disc,
                      onSelected: (v) => setState(() => _disc = v),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),

                // ── Статус протокола ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _approved
                    ? _buildApprovedBanner(cs, theme)
                    : _buildUnapprovedBanner(cs, theme),
                ),

                // ── Сводка ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    _statPill(cs, theme, '5', 'Финиш', cs.primary),
                    const SizedBox(width: 4),
                    _statPill(cs, theme, '1', 'DNF', cs.error),
                    const SizedBox(width: 4),
                    _statPill(cs, theme, '0', 'DNS', cs.onSurfaceVariant),
                    const Spacer(),
                    Text('Участников: 6', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Пьедестал Почета (ТОП-3) ──
          if (_fakeData.where((a) => a.place != null && a.place! <= 3).isNotEmpty)
            SliverToBoxAdapter(
              child: AppPodiumView(
                athletes: _fakeData
                    .where((a) => a.place != null && a.place! <= 3)
                    .map((a) => PodiumAthlete(
                          place: a.place!,
                          name: a.name,
                          bib: a.bib,
                          time: a.time,
                          dog: a.dog,
                          delta: a.delta,
                          avatarUrl: a.avatarUrl,
                        ))
                    .toList(),
              ),
            ),

          // ── Таблица результатов (Glass-строки / Карточки) ──
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverToBoxAdapter(
            child: AppProtocolTable( // Renamed widget
              forceTableView: _isTableView,
              headerRow: const AppProtocolRow(
                isHeader: true,
                bib: '', name: '', cat: '', dog: '', time: '', delta: '', penalty: '',
              ),
              itemCount: _fakeData.length,
              itemBuilder: (context, index, isCardView) {
                final a = _fakeData[index];
                return AppProtocolRow(
                  isCardView: isCardView,
                  place: a.place,
                  
                  bib: a.bib,
                  name: a.name,
                  cat: a.cat,
                  dog: a.dog,
                  time: a.time,
                  delta: a.delta,
                  penalty: a.penalty,
                  onTap: () => _showAthleteCard(context, a.bib, a.name, a.time),
                );
              },
            ),
          ),
          ),

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
                    Expanded(child: AppSignatureRow(role: 'Главный судья', name: 'Иванов П.', signed: _approved)),
                    Expanded(child: AppSignatureRow(role: 'Секретарь', name: 'Смирнова А.', signed: _approved)),
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

  Widget _buildApprovedBanner(ColorScheme cs, ThemeData theme) {
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
          Text('Ed25519 · 10.03.2026 18:30', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          if (_currentDay == 0) Text('Общий зачёт: сумма дней', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
      ]),
    );
  }

  Widget _buildUnapprovedBanner(ColorScheme cs, ThemeData theme) {
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
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: _showApprove,
          icon: const Icon(Icons.verified, size: 16),
          label: const Text('Утвердить'),
        ),
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



  // (Удален _placeWidget, _row и _dnfRow - они теперь внутри AppProtocolRow)




  // ─────────────────────────────────────
  // МОДАЛКИ
  // ─────────────────────────────────────

  void _showAthleteCard(BuildContext context, String bib, String name, String time) {
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
                child: Text(bib, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Скиджоринг 5км', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 24),
          const AppCard(
            padding: EdgeInsets.all(16),
            children: [
              Text('Детали кругов', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              AppSplitRow(label: 'Круг 1', time: '12:05'),
              AppSplitRow(label: 'Круг 2', time: '13:10'),
              AppSplitRow(label: 'Круг 3', time: '12:57'),
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
            setState(() => _approved = true);
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Протокол успешно подписан');
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
          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              const TextField(
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
            Text('Соревнование: Кубок Урала 2026', style: Theme.of(context).textTheme.bodySmall),
            Text('Дисциплина: Скиджоринг 5км', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('1. Петров А.А.', style: Theme.of(context).textTheme.bodySmall),
                  Text('2. Иванов В.В.', style: Theme.of(context).textTheme.bodySmall),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('00:38:12', style: Theme.of(context).textTheme.bodySmall),
                  Text('00:39:45', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ]),
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _previewSignature('Главный судья', 'Иванов П.К.', _approved, cs),
                _previewSignature('Секретарь', 'Смирнова А.А.', _approved, cs),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Настройки документа', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero,
          title: const Text('Добавить QR-коды подписей (ЭЦП)'),
          value: _approved, onChanged: _approved ? (_) {} : null,
          subtitle: !_approved ? Text('Сначала утвердите протокол', style: TextStyle(color: cs.error)) : null,
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



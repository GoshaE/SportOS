import 'package:flutter/material.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/widgets.dart';


/// Screen ID: RS1 — Live результаты (с split-times, multi-day, отсечки)
class LiveResultsScreen extends StatefulWidget {
  const LiveResultsScreen({super.key});

  @override
  State<LiveResultsScreen> createState() => _LiveResultsScreenState();
}

class _LiveResultsScreenState extends State<LiveResultsScreen> {
  String _disc = 'Скиджоринг 5км';
  int _currentDay = 1;
  final int _totalDays = 2;
  bool _showSplits = false;

  final _results = [
    {'pos': 1, 'bib': '07', 'name': 'Петров А.А.', 'dog': 'Rex', 'cat': 'M 25-34', 'time': '00:38:12', 'delta': '—', 'status': 'finished', 'split1': '00:12:45', 'split2': '00:25:30'},
    {'pos': 2, 'bib': '24', 'name': 'Иванов В.В.', 'dog': 'Storm', 'cat': 'M 25-34', 'time': '00:39:45', 'delta': '+1:33', 'status': 'finished', 'split1': '00:13:20', 'split2': '00:26:15'},
    {'pos': 3, 'bib': '55', 'name': 'Волков Е.Е.', 'dog': 'Alaska', 'cat': 'M 35-44', 'time': '00:41:02', 'delta': '+2:50', 'status': 'finished', 'split1': '00:14:00', 'split2': '00:27:45'},
    {'pos': 4, 'bib': '12', 'name': 'Сидоров Б.Б.', 'dog': 'Luna', 'cat': 'M 25-34', 'time': '00:41:33', 'delta': '+3:21', 'status': 'finished', 'split1': '00:13:55', 'split2': '00:28:10'},
    {'pos': 5, 'bib': '77', 'name': 'Новиков З.З.', 'dog': 'Rocky', 'cat': 'Ж 25-34', 'time': '00:42:15', 'delta': '+4:03', 'status': 'finished', 'split1': '00:14:30', 'split2': '00:28:50'},
    {'pos': 0, 'bib': '42', 'name': 'Морозов Д.Д.', 'dog': 'Buddy', 'cat': 'M 18-24', 'time': '—', 'delta': '', 'status': 'on_track', 'split1': '00:14:15', 'split2': '—'},
    {'pos': 0, 'bib': '88', 'name': 'Кузнецов И.И.', 'dog': 'Max', 'cat': 'M 35-44', 'time': '—', 'delta': '', 'status': 'on_track', 'split1': '—', 'split2': '—'},
    {'pos': -1, 'bib': '63', 'name': 'Лебедев Ж.Ж.', 'dog': 'Max', 'cat': 'M 25-34', 'time': 'DNF', 'delta': '', 'status': 'dnf', 'split1': '00:15:22', 'split2': '—'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Live результаты'),
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
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        // ── Шапка: дни + дисциплины + статистика ──
        Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Multi-day
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
            // Дисциплины
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              _chip('Скиджоринг 5км'), _chip('Скиджоринг 10км'), _chip('Каникросс 3км'), _chip('Нарты 15км'),
            ])),
            const SizedBox(height: 8),
            // Статистика
            Row(children: [
              _statPill(cs, theme, '5', 'Финиш', cs.primary),
              const SizedBox(width: 6),
              _statPill(cs, theme, '2', 'На трассе', cs.tertiary),
              const SizedBox(width: 6),
              _statPill(cs, theme, '1', 'DNF', cs.error),
              const SizedBox(width: 6),
              _statPill(cs, theme, '0', 'DNS', cs.onSurfaceVariant),
              const Spacer(),
              // Splits toggle
              GestureDetector(
                onTap: () => setState(() => _showSplits = !_showSplits),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showSplits ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _showSplits ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_showSplits ? Icons.timer : Icons.timer_outlined, size: 14, color: _showSplits ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Сплиты', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _showSplits ? cs.primary : cs.onSurfaceVariant)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),

        // ── Список результатов ──
        Expanded(child: AppProtocolTable(
          itemCount: _results.length,
          forceTableView: true, // Always show as table for live results
          headerRow: AppProtocolRow(
            isHeader: true,
            bib: 'BIB',
            name: 'Спортсмен / Собака',
            cat: 'Кат.',
            dog: 'CP1 / CP2', // We use the 'dog' column space for splits in table mode
            time: 'Время',
            delta: 'Отст.',
            penalty: '—',
          ),
          itemBuilder: (ctx, i, isCard) {
            final r = _results[i];
            final pos = r['pos'] as int;
            final onTrack = r['status'] == 'on_track';
            final dnf = r['status'] == 'dnf';
            
            String placeText = pos <= 0 ? (dnf ? 'DNF' : (onTrack ? 'LIVE' : '—')) : pos.toString();
            String timeDisplay = r['time'] as String;
            if (onTrack) timeDisplay = 'на трассе';

            // Generate split display
            String splitText = '— / —';
            if (_showSplits && r['split1'] != '—') {
              splitText = '${r['split1']} / ${r['split2']}';
            } else if (!_showSplits) {
               splitText = r['dog'] as String; // Show dog when splits hidden
            }

            return AppProtocolRow(
              isCardView: isCard,
              placeText: placeText,
              bib: r['bib'] as String,
              name: r['name'] as String,
              cat: r['cat'] as String,
              dog: splitText, // Reusing dog column for splits if enabled
              time: timeDisplay,
              delta: r['delta'] as String,
              penalty: '—',
            );
          },
        )),

        // ── Auto-refresh ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.sync, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('18:25:03 · авто 5с', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────
  // ВИДЖЕТЫ
  // ─────────────────────────────────────



  Widget _statPill(ColorScheme cs, ThemeData theme, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color)),
      ]),
    );
  }

  Widget _chip(String label) {
    final sel = _disc == label;
    return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: sel,
      onSelected: (_) => setState(() => _disc = label),
      visualDensity: VisualDensity.compact,
    ));
  }
}

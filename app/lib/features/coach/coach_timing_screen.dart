import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: CT1 — Тренерский Пост (Live-отсечки + аналитика)
///
/// Три таба:
/// 1. Гонка — live-таблица соревнования (read-only)
/// 2. Мои отсечки — BIB-сетка + Секундомер
/// 3. Аналитика — сплиты, разрывы, графики
class CoachTimingScreen extends StatefulWidget {
  const CoachTimingScreen({super.key});

  @override
  State<CoachTimingScreen> createState() => _CoachTimingScreenState();
}

class _CoachTimingScreenState extends State<CoachTimingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Режим ввода: сетка или секундомер ──
  bool _isStopwatchMode = false;

  // ── Данные тренера ──
  final List<_CoachMark> _marks = [];
  final Map<String, int> _lapCounters = {}; // bib -> текущий круг

  // ── Mock-данные: все спортсмены на соревновании ──
  final List<Map<String, String>> _athletes = [
    {'bib': '07', 'name': 'Петров А.', 'disc': 'Скидж.'},
    {'bib': '12', 'name': 'Сидоров Б.', 'disc': 'Скидж.'},
    {'bib': '24', 'name': 'Иванов В.', 'disc': 'Нарты'},
    {'bib': '31', 'name': 'Козлов Г.', 'disc': 'Нарты'},
    {'bib': '42', 'name': 'Морозов Д.', 'disc': 'Скидж.'},
    {'bib': '55', 'name': 'Волков Е.', 'disc': 'Пулка'},
    {'bib': '63', 'name': 'Лебедев Ж.', 'disc': 'Скидж.'},
    {'bib': '77', 'name': 'Новиков З.', 'disc': 'Нарты'},
    {'bib': '88', 'name': 'Кузнецов И.', 'disc': 'Скидж.'},
  ];

  // ── Mock: официальные результаты (таб "Гонка") ──
  final List<Map<String, dynamic>> _raceResults = [
    {'pos': 1, 'bib': '07', 'name': 'Петров А.', 'split1': '04:12', 'finish': '12:34', 'gap': '—', 'status': 'finished'},
    {'pos': 2, 'bib': '24', 'name': 'Иванов В.', 'split1': '04:18', 'finish': '12:57', 'gap': '+0:23', 'status': 'finished'},
    {'pos': 3, 'bib': '42', 'name': 'Морозов Д.', 'split1': '04:25', 'finish': '13:15', 'gap': '+0:41', 'status': 'finished'},
    {'pos': 4, 'bib': '31', 'name': 'Козлов Г.', 'split1': '04:30', 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 5, 'bib': '55', 'name': 'Волков Е.', 'split1': '04:35', 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 6, 'bib': '63', 'name': 'Лебедев Ж.', 'split1': null, 'finish': null, 'gap': null, 'status': 'on_course'},
    {'pos': 7, 'bib': '12', 'name': 'Сидоров Б.', 'split1': null, 'finish': null, 'gap': null, 'status': 'started'},
    {'pos': 8, 'bib': '77', 'name': 'Новиков З.', 'split1': null, 'finish': null, 'gap': null, 'status': 'dns'},
  ];

  int _totalLaps = 3;
  int _selectedLapFilter = 0; // 0 = все

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Логика отсечек
  // ═══════════════════════════════════════

  /// Добавить быструю отсечку (секундомер) без BIB
  void _addQuickMark() {
    HapticFeedback.heavyImpact();
    setState(() {
      _marks.add(_CoachMark(
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Назначить BIB конкретной отсечке (из сетки или секундомера)
  void _assignBib(int markIndex, String bib) {
    final lap = (_lapCounters[bib] ?? 0) + 1;
    _lapCounters[bib] = lap;

    // Рассчитываем сплит круга
    Duration? lapSplit;
    final prevMarks = _marks.where((m) => m.bib == bib).toList();
    if (prevMarks.isNotEmpty) {
      lapSplit = _marks[markIndex].timestamp.difference(prevMarks.last.timestamp);
    }

    setState(() {
      _marks[markIndex] = _marks[markIndex].copyWith(
        bib: bib,
        name: _athletes.firstWhere((a) => a['bib'] == bib, orElse: () => {'name': '?'})['name'],
        lap: lap,
        lapSplit: lapSplit,
      );
    });
  }

  /// Отсечка из сетки BIB (тап по плитке)
  void _markFromGrid(String bib) {
    HapticFeedback.mediumImpact();
    final lap = (_lapCounters[bib] ?? 0) + 1;
    _lapCounters[bib] = lap;

    Duration? lapSplit;
    final prevMarks = _marks.where((m) => m.bib == bib).toList();
    final now = DateTime.now();
    if (prevMarks.isNotEmpty) {
      lapSplit = now.difference(prevMarks.last.timestamp);
    }

    final name = _athletes.firstWhere((a) => a['bib'] == bib, orElse: () => {'name': '?'})['name']!;

    setState(() {
      _marks.add(_CoachMark(
        timestamp: now,
        bib: bib,
        name: name,
        lap: lap,
        lapSplit: lapSplit,
      ));
    });

    AppSnackBar.success(context, 'BIB $bib · Круг $lap · ${_formatTime(now)}');
  }

  /// Удалить отсечку
  void _removeMark(int index) {
    final mark = _marks[index];
    if (mark.bib != null && _lapCounters.containsKey(mark.bib)) {
      _lapCounters[mark.bib!] = (_lapCounters[mark.bib!]! - 1).clamp(0, 999);
    }
    setState(() => _marks.removeAt(index));
  }

  /// BIB-пикер (для назначения неопознанной отсечки)
  void _showBibPicker(int markIndex) {
    AppBottomSheet.show(
      context,
      title: 'Назначить BIB',
      initialHeight: 0.6,
      child: GridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        maxCrossAxisExtent: 130,
        childAspectRatio: 1.25,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: _athletes.map((a) {
          final bib = a['bib']!;
          final alreadyMarked = _marks.any((m) => m.bib == bib);
          return AppBibTile(
            bib: bib,
            name: a['name'],
            lapInfo: alreadyMarked
                ? 'Круг ${_lapCounters[bib] ?? 0}'
                : a['disc'],
            state: alreadyMarked ? BibState.finished : BibState.available,
            onTap: () {
              _assignBib(markIndex, bib);
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'BIB $bib назначен');
            },
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = (dt.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$ms';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Получить разрывы для конкретного круга
  List<_CoachMark> _getMarksForLap(int lap) {
    if (lap == 0) {
      // Все отсечки, группируем по BIB, берём последнюю
      final Map<String, _CoachMark> latest = {};
      for (final m in _marks) {
        if (m.bib != null) latest[m.bib!] = m;
      }
      return latest.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return _marks.where((m) => m.bib != null && m.lap == lap).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Тренерский Пост'),
        actions: [
          IconButton(
            icon: Icon(Icons.sports, color: cs.primary),
            tooltip: 'Настройки',
            onPressed: () => _showSettings(context),
          ),
        ],
        bottom: AppPillTabBar(
          controller: _tabController,
          tabs: const ['Гонка', 'Мои отсечки', 'Аналитика'],
          icons: const [Icons.leaderboard, Icons.timer, Icons.analytics],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRaceTab(theme, cs),
          _buildMarksTab(theme, cs),
          _buildAnalyticsTab(theme, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Настройки
  // ═══════════════════════════════════════
  void _showSettings(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Настройки тренера',
      initialHeight: 0.4,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Количество кругов на трассе:', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children: [
          for (final n in [1, 2, 3, 4, 5])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$n'),
                selected: _totalLaps == n,
                onSelected: (_) => setState(() => _totalLaps = n),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        AppInfoBanner.info(title: 'Количество кругов влияет на авто-определение круга при отсечке и отображение в таблице разрывов.'),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Таб 1: Гонка (Read-only live)
  // ═══════════════════════════════════════
  Widget _buildRaceTab(ThemeData theme, ColorScheme cs) {
    return Column(children: [
      // Заголовок
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Sprint 5km', style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(fontSize: 10, color: cs.error, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),

      // Заголовок таблицы
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          SizedBox(width: 40, child: Text('BIB', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Имя', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold))),
          SizedBox(width: 55, child: Text('КП1', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 60, child: Text('Финиш', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 55, child: Text('Δ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ]),
      ),
      const Divider(height: 1),

      // Таблица результатов
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _raceResults.length,
          itemBuilder: (context, i) {
            final r = _raceResults[i];
            final status = r['status'] as String;
            final isFinished = status == 'finished';
            final isDns = status == 'dns';
            final isOnCourse = status == 'on_course' || status == 'started';

            final statusColor = isFinished ? cs.primary : isDns ? cs.error : cs.tertiary;
            final statusIcon = isFinished
                ? Icons.check_circle
                : isDns
                    ? Icons.block
                    : Icons.directions_run;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1))),
              ),
              child: Row(children: [
                SizedBox(width: 32, child: Row(children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text('${r['pos']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ])),
                SizedBox(width: 40, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                  child: Text('${r['bib']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                )),
                const SizedBox(width: 4),
                Expanded(child: Text(
                  '${r['name']}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDns ? cs.outline : cs.onSurface, decoration: isDns ? TextDecoration.lineThrough : null),
                  overflow: TextOverflow.ellipsis,
                )),
                SizedBox(width: 55, child: Text(r['split1'] ?? '—', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: r['split1'] != null ? cs.onSurface : cs.outline), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text(
                  r['finish'] ?? (isOnCourse ? '...' : '—'),
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: isFinished ? FontWeight.bold : FontWeight.normal, color: isFinished ? cs.primary : cs.outline),
                  textAlign: TextAlign.center,
                )),
                SizedBox(width: 55, child: Text(
                  r['gap'] ?? '',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r['gap'] == '—' ? cs.primary : cs.error),
                  textAlign: TextAlign.center,
                )),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Таб 2: Мои отсечки
  // ═══════════════════════════════════════
  Widget _buildMarksTab(ThemeData theme, ColorScheme cs) {
    final assignedMarks = _marks.where((m) => m.bib != null).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(children: [
      // ── Переключатель: Сетка / Секундомер ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(4),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              children: [
                SizedBox(
                  height: 38,
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStopwatchMode = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isStopwatchMode ? cs.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: !_isStopwatchMode ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
                            boxShadow: !_isStopwatchMode ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.grid_view, size: 18, color: !_isStopwatchMode ? cs.onSurface : cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Сетка BIB', style: TextStyle(fontSize: 13, fontWeight: !_isStopwatchMode ? FontWeight.w700 : FontWeight.w500, color: !_isStopwatchMode ? cs.onSurface : cs.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStopwatchMode = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isStopwatchMode ? cs.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: _isStopwatchMode ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
                            boxShadow: _isStopwatchMode ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.timer, size: 18, color: _isStopwatchMode ? cs.onSurface : cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Секундомер', style: TextStyle(fontSize: 13, fontWeight: _isStopwatchMode ? FontWeight.w700 : FontWeight.w500, color: _isStopwatchMode ? cs.onSurface : cs.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            children: [
              Row(children: [
                Icon(Icons.bookmark, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('${assignedMarks.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
              ]),
            ],
          ),
        ]),
      ),

      // ── Основной контент: Сетка или Секундомер ──
      Expanded(
        child: _isStopwatchMode
            ? _buildStopwatchMode(theme, cs)
            : _buildGridMode(theme, cs),
      ),

      // ── Таблица разрывов (внизу) ──
      if (assignedMarks.isNotEmpty) _buildGapTable(theme, cs, assignedMarks),
    ]);
  }

  // ── Режим Сетка BIB ──
  Widget _buildGridMode(ThemeData theme, ColorScheme cs) {
    return GridView.extent(
      maxCrossAxisExtent: 130,
      childAspectRatio: 0.85,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: _athletes.map((a) {
        final bib = a['bib']!;
        final lapCount = _lapCounters[bib] ?? 0;
        final hasMarks = lapCount > 0;

        // Найти последний сплит для этого BIB
        final bibMarks = _marks.where((m) => m.bib == bib).toList();
        String? lastSplitText;
        String? trendIcon;
        if (bibMarks.length >= 2) {
          final last = bibMarks.last;
          final prev = bibMarks[bibMarks.length - 2];
          if (last.lapSplit != null && prev.lapSplit != null) {
            final diff = last.lapSplit!.inSeconds - prev.lapSplit!.inSeconds;
            trendIcon = diff > 0 ? '▼' : (diff < 0 ? '▲' : '=');
          }
          if (last.lapSplit != null) {
            lastSplitText = '${_formatDuration(last.lapSplit!)} ${trendIcon ?? ''}';
          }
        } else if (bibMarks.isNotEmpty && bibMarks.last.lapSplit != null) {
          lastSplitText = _formatDuration(bibMarks.last.lapSplit!);
        }

        final lapInfo = hasMarks
            ? 'Круг $lapCount/$_totalLaps${lastSplitText != null ? '\n$lastSplitText' : ''}'
            : a['disc'];

        return AppBibTile(
          bib: bib,
          name: a['name'],
          lapInfo: lapInfo,
          state: hasMarks
              ? (lapCount >= _totalLaps ? BibState.finished : BibState.current)
              : BibState.available,
          onTap: () => _markFromGrid(bib),
        );
      }).toList(),
    );
  }

  // ── Режим Секундомер ──
  Widget _buildStopwatchMode(ThemeData theme, ColorScheme cs) {
    final unassigned = <int>[];
    for (int i = 0; i < _marks.length; i++) {
      if (_marks[i].bib == null) unassigned.add(i);
    }

    return Column(children: [
      // Список неназначенных отсечек
      if (unassigned.isNotEmpty)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: unassigned.length,
            itemBuilder: (context, i) {
              final idx = unassigned[i];
              final mark = _marks[idx];
              return Dismissible(
                key: ValueKey('mark-$idx-${mark.timestamp}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeMark(idx),
                background: Container(
                  color: cs.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete, color: cs.onError),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.1),
                    borderColor: cs.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    children: [
                      InkWell(
                        onTap: () => _showBibPicker(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.tertiary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_formatTime(mark.timestamp), style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                              const SizedBox(height: 4),
                              Text('Назначить BIB', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ])),
                            Icon(Icons.touch_app, color: cs.tertiary, size: 24),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      else
        Expanded(
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Нажмите кнопку ОТСЕЧКА', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text('когда спортсмен проходит вашу точку', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
          ])),
        ),

      // Большая кнопка ОТСЕЧКА
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.1),
            borderColor: cs.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addQuickMark,
                  splashColor: cs.primary.withValues(alpha: 0.2),
                  highlightColor: cs.primary.withValues(alpha: 0.1),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_sharp, size: 40, color: cs.primary),
                        const SizedBox(height: 8),
                        Text('ОТСЕЧКА', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  // ── Таблица разрывов ──
  Widget _buildGapTable(ThemeData theme, ColorScheme cs, List<_CoachMark> assignedMarks) {
    final lapsWithData = <int>{};
    for (final m in assignedMarks) {
      lapsWithData.add(m.lap);
    }

    final marksForLap = _getMarksForLap(_selectedLapFilter);
    final firstTime = marksForLap.isNotEmpty ? marksForLap.first.timestamp : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Переключатель кругов
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Icon(Icons.compare_arrows, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text('Разрывы', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const Spacer(),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [
                  _buildLapChip('Все', 0, cs),
                  for (final lap in lapsWithData.toList()..sort())
                    _buildLapChip('Кр.$lap', lap, cs),
                ],
              ),
            ),
          ]),
        ),

        // Мини-таблица
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: marksForLap.length,
            itemBuilder: (context, i) {
              final m = marksForLap[i];
              final gap = firstTime != null && i > 0
                  ? m.timestamp.difference(firstTime)
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Container(
                    width: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                    child: Text('#${m.bib}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m.name ?? '?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface))),
                  if (m.lapSplit != null)
                    Text(_formatDuration(m.lapSplit!), style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.onSurface)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      gap != null ? '+${_formatDuration(gap)}' : '—',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: gap != null ? cs.error : cs.primary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildLapChip(String label, int lap, ColorScheme cs) {
    final selected = _selectedLapFilter == lap;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => setState(() => _selectedLapFilter = lap),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? cs.primary : cs.onSurfaceVariant)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Таб 3: Аналитика
  // ═══════════════════════════════════════
  Widget _buildAnalyticsTab(ThemeData theme, ColorScheme cs) {
    final assignedMarks = _marks.where((m) => m.bib != null).toList();

    if (assignedMarks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.analytics_outlined, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        Text('Пока нет данных', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Поставьте отсечки на табе «Мои отсечки»', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
      ]));
    }

    // Группируем отсечки по BIB
    final Map<String, List<_CoachMark>> byBib = {};
    for (final m in assignedMarks) {
      byBib.putIfAbsent(m.bib!, () => []).add(m);
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Сводная статистика
      Row(children: [
        AppStatCard(value: '${byBib.keys.length}', label: 'Спортсменов', icon: Icons.people),
        const SizedBox(width: 8),
        AppStatCard(value: '${assignedMarks.length}', label: 'Отсечек', icon: Icons.timer),
        const SizedBox(width: 8),
        AppStatCard(value: '$_totalLaps', label: 'Кругов', icon: Icons.loop, color: cs.tertiary),
      ]),
      const SizedBox(height: 16),

      // Заголовок таблицы
      Text('ТАБЛИЦА СПЛИТОВ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
      const SizedBox(height: 8),

      // Таблица сплитов по кругам
      AppCard(
        padding: const EdgeInsets.all(12),
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        children: [
          // Заголовок
          Row(children: [
            SizedBox(width: 40, child: Text('BIB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
            Expanded(child: Text('Имя', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
            for (int lap = 1; lap <= _totalLaps; lap++)
              SizedBox(width: 55, child: Text('Кр.$lap', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
            SizedBox(width: 55, child: Text('Δ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
          ]),
          const Divider(height: 16),

          // Строки
          ...byBib.entries.map((entry) {
            final bib = entry.key;
            final bibMarks = entry.value..sort((a, b) => a.lap.compareTo(b.lap));
            final firstBib = byBib.entries.first.key;

            // Вычислить общий разрыв
            String gapText = '—';
            if (bib != firstBib && bibMarks.isNotEmpty && byBib[firstBib]!.isNotEmpty) {
              final myTotal = bibMarks.last.timestamp.difference(bibMarks.first.timestamp);
              final leaderMarks = byBib[firstBib]!;
              if (leaderMarks.length >= bibMarks.length) {
                final leaderTotal = leaderMarks.last.timestamp.difference(leaderMarks.first.timestamp);
                final gap = myTotal - leaderTotal;
                gapText = '+${_formatDuration(gap)}';
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 40, child: Text(bib, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.onSurface))),
                Expanded(child: Text(bibMarks.first.name ?? '?', style: TextStyle(fontSize: 12, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
                for (int lap = 1; lap <= _totalLaps; lap++)
                  SizedBox(width: 55, child: () {
                    final lapMark = bibMarks.where((m) => m.lap == lap).firstOrNull;
                    if (lapMark?.lapSplit == null) return Text('—', style: TextStyle(fontSize: 11, color: cs.outline), textAlign: TextAlign.center);
                    return Text(_formatDuration(lapMark!.lapSplit!), style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.onSurface), textAlign: TextAlign.center);
                  }()),
                SizedBox(width: 55, child: Text(gapText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gapText == '—' ? cs.primary : cs.error), textAlign: TextAlign.center)),
              ]),
            );
          }),
        ],
      ),
      const SizedBox(height: 16),

      // Кнопки экспорта
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => AppSnackBar.info(context, 'Экспорт PDF → скоро'),
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('PDF'),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => AppSnackBar.info(context, 'Экспорт Excel → скоро'),
          icon: const Icon(Icons.table_chart, size: 16),
          label: const Text('Excel'),
        )),
      ]),
    ]);
  }
}

// ═══════════════════════════════════════
// Data Model
// ═══════════════════════════════════════

class _CoachMark {
  final DateTime timestamp;
  final String? bib;
  final String? name;
  final int lap;
  final Duration? lapSplit;

  const _CoachMark({
    required this.timestamp,
    this.bib,
    this.name,
    this.lap = 0,
    this.lapSplit,
  });

  _CoachMark copyWith({
    String? bib,
    String? name,
    int? lap,
    Duration? lapSplit,
  }) {
    return _CoachMark(
      timestamp: timestamp,
      bib: bib ?? this.bib,
      name: name ?? this.name,
      lap: lap ?? this.lap,
      lapSplit: lapSplit ?? this.lapSplit,
    );
  }
}

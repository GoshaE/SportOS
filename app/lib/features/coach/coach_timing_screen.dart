import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: CT1 — Тренерский Хронометраж (Live-отсечки + разрывы)
///
/// Три таба:
/// 1. Гонка — live-таблица соревнования (read-only)
/// 2. Мои отсечки — BIB-сетка + Секундомер + таблица разрывов
/// 3. Аналитика — полная таблица сплитов + экспорт
class CoachTimingScreen extends StatefulWidget {
  const CoachTimingScreen({super.key});

  @override
  State<CoachTimingScreen> createState() => _CoachTimingScreenState();
}

class _CoachTimingScreenState extends State<CoachTimingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _clockTimer;

  // ── Режим ввода: сетка или секундомер ──
  bool _isStopwatchMode = false;

  // ── Данные тренера ──
  final List<_CoachMark> _marks = [];
  final Map<String, int> _lapCounters = {}; // bib -> текущий круг

  // ── Часы мероприятия ──
  /// Время старта первого спортсмена = «нулевая точка» мероприятия.
  late final DateTime _raceStartTime;
  Duration _elapsed = Duration.zero;

  // ── Mock-данные: все спортсмены (с интервалом старта!) ──
  late final List<_Athlete> _athletes;

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

    // Симуляция: старт мероприятия был «сейчас минус 15 минут»
    _raceStartTime = DateTime.now().subtract(const Duration(minutes: 15));

    // Спортсмены с интервальными стартами (каждые 30 сек)
    _athletes = [
      _Athlete(bib: '07', name: 'Петров А.', disc: 'Скидж.', startTime: _raceStartTime),
      _Athlete(bib: '12', name: 'Сидоров Б.', disc: 'Скидж.', startTime: _raceStartTime.add(const Duration(seconds: 30))),
      _Athlete(bib: '24', name: 'Иванов В.', disc: 'Нарты', startTime: _raceStartTime.add(const Duration(seconds: 60))),
      _Athlete(bib: '31', name: 'Козлов Г.', disc: 'Нарты', startTime: _raceStartTime.add(const Duration(seconds: 90))),
      _Athlete(bib: '42', name: 'Морозов Д.', disc: 'Скидж.', startTime: _raceStartTime.add(const Duration(seconds: 120))),
      _Athlete(bib: '55', name: 'Волков Е.', disc: 'Пулка', startTime: _raceStartTime.add(const Duration(seconds: 150))),
      _Athlete(bib: '63', name: 'Лебедев Ж.', disc: 'Скидж.', startTime: _raceStartTime.add(const Duration(seconds: 180))),
      _Athlete(bib: '77', name: 'Новиков З.', disc: 'Нарты', startTime: _raceStartTime.add(const Duration(seconds: 210))),
      _Athlete(bib: '88', name: 'Кузнецов И.', disc: 'Скидж.', startTime: _raceStartTime.add(const Duration(seconds: 240))),
    ];

    // Таймер для часов мероприятия (обновление каждую секунду)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_raceStartTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Логика отсечек
  // ═══════════════════════════════════════

  /// Добавить быструю отсечку (секундомер) без BIB
  void _addQuickMark() {
    HapticFeedback.heavyImpact();
    setState(() {
      _marks.add(_CoachMark(timestamp: DateTime.now()));
    });
  }

  /// Найти спортсмена по BIB
  _Athlete _findAthlete(String bib) {
    return _athletes.firstWhere(
      (a) => a.bib == bib,
      orElse: () => _Athlete(bib: bib, name: '?', disc: '?', startTime: _raceStartTime),
    );
  }

  /// Назначить BIB конкретной отсечке
  void _assignBib(int markIndex, String bib) {
    final lap = (_lapCounters[bib] ?? 0) + 1;
    _lapCounters[bib] = lap;

    final athlete = _findAthlete(bib);
    final markTime = _marks[markIndex].timestamp;
    final elapsedFromStart = markTime.difference(athlete.startTime);

    // Сплит круга (время между этой и предыдущей отсечкой этого BIB)
    Duration? lapSplit;
    final prevMarks = _marks.where((m) => m.bib == bib).toList();
    if (prevMarks.isNotEmpty) {
      lapSplit = markTime.difference(prevMarks.last.timestamp);
    }

    setState(() {
      _marks[markIndex] = _marks[markIndex].copyWith(
        bib: bib,
        name: athlete.name,
        lap: lap,
        lapSplit: lapSplit,
        elapsedFromStart: elapsedFromStart,
      );
    });
  }

  /// Отсечка из сетки BIB (тап по плитке)
  void _markFromGrid(String bib) {
    HapticFeedback.mediumImpact();
    final lap = (_lapCounters[bib] ?? 0) + 1;
    _lapCounters[bib] = lap;

    final athlete = _findAthlete(bib);
    final now = DateTime.now();
    final elapsedFromStart = now.difference(athlete.startTime);

    Duration? lapSplit;
    final prevMarks = _marks.where((m) => m.bib == bib).toList();
    if (prevMarks.isNotEmpty) {
      lapSplit = now.difference(prevMarks.last.timestamp);
    }

    setState(() {
      _marks.add(_CoachMark(
        timestamp: now,
        bib: bib,
        name: athlete.name,
        lap: lap,
        lapSplit: lapSplit,
        elapsedFromStart: elapsedFromStart,
      ));
    });

    AppSnackBar.success(context, 'BIB $bib · Круг $lap · ${_fmtDur(elapsedFromStart)} от старта');
  }

  /// Удалить отсечку
  void _removeMark(int index) {
    final mark = _marks[index];
    if (mark.bib != null && _lapCounters.containsKey(mark.bib)) {
      _lapCounters[mark.bib!] = (_lapCounters[mark.bib!]! - 1).clamp(0, 999);
    }
    setState(() => _marks.removeAt(index));
  }

  /// BIB-пикер
  void _showBibPicker(int markIndex) {
    AppBottomSheet.show(
      context,
      title: 'Назначить BIB',
      initialHeight: 0.6,
      child: GridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        maxCrossAxisExtent: 130,
        childAspectRatio: 1.1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: _athletes.map((a) {
          final alreadyMarked = _marks.any((m) => m.bib == a.bib);
          return AppBibTile(
            bib: a.bib,
            name: a.name,
            lapInfo: alreadyMarked
                ? 'Круг ${_lapCounters[a.bib] ?? 0}'
                : 'Старт: ${_fmtTime(a.startTime)}',
            state: alreadyMarked ? BibState.assigned : BibState.available,
            onTap: () {
              _assignBib(markIndex, a.bib);
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'BIB ${a.bib} назначен');
            },
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtDur(Duration d) {
    if (d.isNegative) return '-${_fmtDur(-d)}';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDurMs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Построить таблицу разрывов: для каждого круга группируем по BIB,
  /// считаем elapsed от старта, сортируем, выводим разрыв от лидера.
  List<_GapRow> _buildGapRows(int lap) {
    List<_CoachMark> marksForLap;
    if (lap == 0) {
      // Берём последнюю отсечку каждого BIB
      final Map<String, _CoachMark> latest = {};
      for (final m in _marks) {
        if (m.bib != null) latest[m.bib!] = m;
      }
      marksForLap = latest.values.toList();
    } else {
      marksForLap = _marks.where((m) => m.bib != null && m.lap == lap).toList();
    }

    if (marksForLap.isEmpty) return [];

    // Сортируем по elapsed from start (кто быстрее дошёл)
    marksForLap.sort((a, b) => (a.elapsedFromStart ?? Duration.zero).compareTo(b.elapsedFromStart ?? Duration.zero));

    final leaderElapsed = marksForLap.first.elapsedFromStart ?? Duration.zero;
    final rows = <_GapRow>[];

    for (int i = 0; i < marksForLap.length; i++) {
      final m = marksForLap[i];
      final elapsed = m.elapsedFromStart ?? Duration.zero;
      final gapFromLeader = elapsed - leaderElapsed;

      // Динамика: сравнить разрыв на этом круге vs предыдущем
      Duration? prevGap;
      if (lap > 1 && m.bib != null) {
        final prevLapMark = _marks.where((pm) => pm.bib == m.bib && pm.lap == lap - 1).firstOrNull;
        final prevLeaderMark = _marks.where((pm) => pm.bib == marksForLap.first.bib && pm.lap == lap - 1).firstOrNull;
        if (prevLapMark != null && prevLeaderMark != null && prevLapMark.elapsedFromStart != null && prevLeaderMark.elapsedFromStart != null) {
          prevGap = prevLapMark.elapsedFromStart! - prevLeaderMark.elapsedFromStart!;
        }
      }

      rows.add(_GapRow(
        pos: i + 1,
        bib: m.bib!,
        name: m.name ?? '?',
        elapsed: elapsed,
        lapSplit: m.lapSplit,
        gapFromLeader: gapFromLeader,
        trend: prevGap != null ? _calcTrend(gapFromLeader, prevGap) : null,
      ));
    }

    return rows;
  }

  _GapTrend? _calcTrend(Duration currentGap, Duration prevGap) {
    final diff = currentGap.inMilliseconds - prevGap.inMilliseconds;
    if (diff.abs() < 500) return _GapTrend.same; // Менее 0.5 сек — без изменений
    return diff > 0 ? _GapTrend.losing : _GapTrend.gaining;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Хронометраж'),
        actions: [
          // ── Часы мероприятия ──
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_fmtElapsed(_elapsed), style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w900, color: cs.error)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 20, color: cs.onSurfaceVariant),
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
        AppInfoBanner.info(title: 'Разрывы рассчитываются с учётом времени старта каждого спортсмена (интервальный старт).'),
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
                  Text('Sprint 5km · $_totalLaps кр.', style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.bold)),
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
            final statusIcon = isFinished ? Icons.check_circle : isDns ? Icons.block : Icons.directions_run;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1)))),
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
                Expanded(child: Text('${r['name']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDns ? cs.outline : cs.onSurface, decoration: isDns ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 55, child: Text(r['split1'] ?? '—', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: r['split1'] != null ? cs.onSurface : cs.outline), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text(r['finish'] ?? (isOnCourse ? '...' : '—'), style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: isFinished ? FontWeight.bold : FontWeight.normal, color: isFinished ? cs.primary : cs.outline), textAlign: TextAlign.center)),
                SizedBox(width: 55, child: Text(r['gap'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r['gap'] == '—' ? cs.primary : cs.error), textAlign: TextAlign.center)),
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
                    _modeButton('Сетка BIB', Icons.grid_view, !_isStopwatchMode, cs, () => setState(() => _isStopwatchMode = false)),
                    _modeButton('Секундомер', Icons.timer, _isStopwatchMode, cs, () => setState(() => _isStopwatchMode = true)),
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

      // ── Основной контент ──
      Expanded(
        child: _isStopwatchMode
            ? _buildStopwatchMode(theme, cs)
            : _buildGridMode(theme, cs),
      ),

      // ── Таблица разрывов (внизу) ──
      if (assignedMarks.isNotEmpty) _buildGapTable(theme, cs),
    ]);
  }

  Widget _modeButton(String label, IconData icon, bool active, ColorScheme cs, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: active ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? cs.onSurface : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? cs.onSurface : cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
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
        final lapCount = _lapCounters[a.bib] ?? 0;
        final hasMarks = lapCount > 0;

        // Последний сплит + тренд
        final bibMarks = _marks.where((m) => m.bib == a.bib).toList();
        String? splitInfo;
        if (bibMarks.isNotEmpty && bibMarks.last.elapsedFromStart != null) {
          splitInfo = _fmtDur(bibMarks.last.elapsedFromStart!);
        }

        final lapInfo = hasMarks
            ? 'Круг $lapCount/$_totalLaps${splitInfo != null ? '\n⏱$splitInfo' : ''}'
            : 'Старт: ${_fmtTime(a.startTime)}';

        return AppBibTile(
          bib: a.bib,
          name: a.name,
          lapInfo: lapInfo,
          state: hasMarks
              ? (lapCount >= _totalLaps ? BibState.finished : BibState.current)
              : BibState.available,
          onTap: () => _markFromGrid(a.bib),
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
      if (unassigned.isNotEmpty)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: unassigned.length,
            itemBuilder: (context, i) {
              final idx = unassigned[i];
              final mark = _marks[idx];
              final raceTime = mark.timestamp.difference(_raceStartTime);
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
                              Text(_fmtDurMs(raceTime), style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                              Text('🕐 ${_fmtTime(mark.timestamp)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Назначить BIB', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold, fontSize: 12)),
                              Icon(Icons.touch_app, color: cs.tertiary, size: 20),
                            ]),
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.timer_sharp, size: 40, color: cs.primary),
                      const SizedBox(height: 8),
                      Text('ОТСЕЧКА', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: 3)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Таблица разрывов (с elapsed от старта)
  // ═══════════════════════════════════════
  Widget _buildGapTable(ThemeData theme, ColorScheme cs) {
    final assignedMarks = _marks.where((m) => m.bib != null).toList();
    final lapsWithData = <int>{};
    for (final m in assignedMarks) {
      lapsWithData.add(m.lap);
    }

    final gapRows = _buildGapRows(_selectedLapFilter);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Заголовок + переключатель кругов
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

        // Заголовок колонок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            SizedBox(width: 18, child: Text('#', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            SizedBox(width: 28, child: Text('BIB', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Имя', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold))),
            SizedBox(width: 50, child: Text('Время', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            SizedBox(width: 45, child: Text('Круг', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            SizedBox(width: 60, child: Text('Разрыв', style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ]),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),

        // Таблица
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 170),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            itemCount: gapRows.length,
            itemBuilder: (context, i) {
              final r = gapRows[i];
              final isLeader = i == 0;
              final trendIcon = r.trend == _GapTrend.gaining ? '▲' : r.trend == _GapTrend.losing ? '▼' : r.trend == _GapTrend.same ? '=' : '';
              final trendColor = r.trend == _GapTrend.gaining ? Colors.green : r.trend == _GapTrend.losing ? cs.error : cs.onSurfaceVariant;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  // Позиция
                  SizedBox(width: 18, child: Text('${r.pos}', style: TextStyle(fontSize: 11, fontWeight: isLeader ? FontWeight.w900 : FontWeight.w600, color: isLeader ? cs.primary : cs.onSurfaceVariant))),
                  // BIB
                  SizedBox(width: 28, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
                    child: Text(r.bib, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  )),
                  const SizedBox(width: 4),
                  // Имя
                  Expanded(child: Text(r.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
                  // Elapsed от старта
                  SizedBox(width: 50, child: Text(_fmtDur(r.elapsed), style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: cs.onSurface), textAlign: TextAlign.center)),
                  // Сплит круга
                  SizedBox(width: 45, child: Text(r.lapSplit != null ? _fmtDur(r.lapSplit!) : '—', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
                  // Разрыв от лидера + тренд
                  SizedBox(width: 60, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (trendIcon.isNotEmpty) Text(trendIcon, style: TextStyle(fontSize: 10, color: trendColor)),
                    const SizedBox(width: 2),
                    Text(
                      isLeader ? '—' : '+${_fmtDur(r.gapFromLeader)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLeader ? cs.primary : cs.error),
                    ),
                  ])),
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

    // Группируем по BIB
    final Map<String, List<_CoachMark>> byBib = {};
    for (final m in assignedMarks) {
      byBib.putIfAbsent(m.bib!, () => []).add(m);
    }

    // Сортируем BIB по elapsed (кто быстрее)
    final sortedBibs = byBib.entries.toList()
      ..sort((a, b) {
        final aElapsed = a.value.last.elapsedFromStart ?? Duration.zero;
        final bElapsed = b.value.last.elapsedFromStart ?? Duration.zero;
        return aElapsed.compareTo(bElapsed);
      });

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

      // Заголовок
      Text('ТАБЛИЦА СПЛИТОВ (от старта)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text('Время — elapsed от персонального старта спортсмена', style: TextStyle(fontSize: 10, color: cs.outline)),
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
            SizedBox(width: 55, child: Text('Δ лидер', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
          ]),
          const Divider(height: 16),

          ...sortedBibs.asMap().entries.map((entry) {
            final i = entry.key;
            final bib = entry.value.key;
            final bibMarks = entry.value.value..sort((a, b) => a.lap.compareTo(b.lap));
            final isLeader = i == 0;

            // Разрыв от лидера
            String gapText = '—';
            if (!isLeader && bibMarks.isNotEmpty) {
              final leaderBibMarks = sortedBibs.first.value;
              final myLastElapsed = bibMarks.last.elapsedFromStart;
              final leaderLastElapsed = leaderBibMarks.last.elapsedFromStart;
              if (myLastElapsed != null && leaderLastElapsed != null) {
                final gap = myLastElapsed - leaderLastElapsed;
                gapText = '+${_fmtDur(gap)}';
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 40, child: Text(bib, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isLeader ? cs.primary : cs.onSurface))),
                Expanded(child: Text(bibMarks.first.name ?? '?', style: TextStyle(fontSize: 12, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
                for (int lap = 1; lap <= _totalLaps; lap++)
                  SizedBox(width: 55, child: () {
                    final lapMark = bibMarks.where((m) => m.lap == lap).firstOrNull;
                    if (lapMark?.elapsedFromStart == null) return Text('—', style: TextStyle(fontSize: 11, color: cs.outline), textAlign: TextAlign.center);
                    return Text(_fmtDur(lapMark!.elapsedFromStart!), style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.onSurface), textAlign: TextAlign.center);
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
// Data Models
// ═══════════════════════════════════════

/// Спортсмен с интервалом старта
class _Athlete {
  final String bib;
  final String name;
  final String disc;
  final DateTime startTime;

  const _Athlete({
    required this.bib,
    required this.name,
    required this.disc,
    required this.startTime,
  });
}

/// Отсечка тренера
class _CoachMark {
  final DateTime timestamp;
  final String? bib;
  final String? name;
  final int lap;
  final Duration? lapSplit;
  final Duration? elapsedFromStart; // Время от старта спортсмена до этой отсечки

  const _CoachMark({
    required this.timestamp,
    this.bib,
    this.name,
    this.lap = 0,
    this.lapSplit,
    this.elapsedFromStart,
  });

  _CoachMark copyWith({
    String? bib,
    String? name,
    int? lap,
    Duration? lapSplit,
    Duration? elapsedFromStart,
  }) {
    return _CoachMark(
      timestamp: timestamp,
      bib: bib ?? this.bib,
      name: name ?? this.name,
      lap: lap ?? this.lap,
      lapSplit: lapSplit ?? this.lapSplit,
      elapsedFromStart: elapsedFromStart ?? this.elapsedFromStart,
    );
  }
}

/// Строка таблицы разрывов
class _GapRow {
  final int pos;
  final String bib;
  final String name;
  final Duration elapsed;
  final Duration? lapSplit;
  final Duration gapFromLeader;
  final _GapTrend? trend;

  const _GapRow({
    required this.pos,
    required this.bib,
    required this.name,
    required this.elapsed,
    this.lapSplit,
    required this.gapFromLeader,
    this.trend,
  });
}

enum _GapTrend { gaining, losing, same }

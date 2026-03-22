import '../timing/result_table.dart';
import '../timing/time_formatter.dart';
import 'quick_timer_models.dart';

/// Калькулятор результатов для Быстрого таймера.
///
/// Изолирует логику расчётов и создания таблицы (колонки, ячейки, сортировка)
/// от UI-слоя. Адаптировано из `quick_timer_screen.dart`.
class QuickResultCalculator {
  const QuickResultCalculator._();

  /// Построить [ResultTable] из [QuickSession].
  static ResultTable buildTable(QuickSession session) {
    final athletes = [...session.athletes];
    
    // Сортировка: сначала по кругам, затем по времени последнего сплита
    athletes.sort((a, b) {
      final lapsCompare = b.completedLaps.compareTo(a.completedLaps);
      if (lapsCompare != 0) return lapsCompare;
      if (a.splits.isNotEmpty && b.splits.isNotEmpty) {
        final aTime = a.splits.last.difference(session.effectiveStart(a));
        final bTime = b.splits.last.difference(session.effectiveStart(b));
        return aTime.compareTo(bTime);
      }
      return 0;
    });

    final leaderLapDurations = athletes.isNotEmpty
        ? athletes.first.lapDurations(session.effectiveStart(athletes.first))
        : <Duration>[];
        
    Duration? leaderTotalTime;
    if (athletes.isNotEmpty && athletes.first.splits.isNotEmpty) {
      leaderTotalTime = athletes.first.splits.last.difference(session.effectiveStart(athletes.first));
    }

    // ── Колонки ──
    final columns = <ColumnDef>[
      const ColumnDef(id: 'place', label: '#', type: ColumnType.number, align: ColumnAlign.center, flex: 0.4, minWidth: 36),
      const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.text, align: ColumnAlign.center, flex: 0.5, minWidth: 40),
      const ColumnDef(id: 'name', label: 'Имя', type: ColumnType.text, flex: 1.5, minWidth: 80),
      for (var lap = 1; lap <= session.totalLaps; lap++)
        ColumnDef(id: 'lap${lap}_time', label: 'L$lap', type: ColumnType.time, align: ColumnAlign.right, flex: 0.8, minWidth: 60),
      const ColumnDef(id: 'result_time', label: 'Время', type: ColumnType.time, align: ColumnAlign.right, flex: 1.0, minWidth: 70),
      const ColumnDef(id: 'gap_leader', label: 'Δ', type: ColumnType.gap, align: ColumnAlign.right, flex: 0.7, minWidth: 55),
    ];

    // ── Строки ──
    final rows = <ResultRow>[];
    for (var i = 0; i < athletes.length; i++) {
      final a = athletes[i];
      final finished = a.isFinished(session.totalLaps);
      final hasStarted = a.startTime != null || session.mode == QuickStartMode.mass;
      final laps = a.completedLaps;
      final place = i + 1;
      final lapDurations = a.lapDurations(session.effectiveStart(a));
      final displayName = a.name.isNotEmpty ? a.name : 'BIB ${a.bib}';

      Duration? athleteTime;
      if (a.splits.isNotEmpty) {
        athleteTime = a.splits.last.difference(session.effectiveStart(a));
      }

      final RowType rowType;
      if (finished) {
        rowType = RowType.finished;
      } else if (!hasStarted) {
        rowType = RowType.waiting;
      } else {
        rowType = RowType.onTrack;
      }

      final cells = <String, CellValue>{};

      // №
      if (finished) {
        cells['place'] = CellValue(raw: place, display: '$place', style: place <= 3 ? CellStyle.highlight : CellStyle.normal);
      } else if (hasStarted) {
        final statusLabel = laps > 0 ? 'К$laps' : 'LIVE';
        cells['place'] = CellValue(display: statusLabel, style: CellStyle.highlight);
      } else {
        cells['place'] = const CellValue(display: '—', style: CellStyle.muted);
      }

      // BIB & Name
      cells['bib'] = CellValue(raw: a.bib, display: a.bib);
      cells['name'] = CellValue(raw: displayName, display: displayName,
        style: finished ? CellStyle.bold : hasStarted ? CellStyle.normal : CellStyle.muted);

      // Laps
      for (var lap = 1; lap <= session.totalLaps; lap++) {
        final lapIdx = lap - 1;
        if (lapIdx < lapDurations.length) {
          final lapTime = lapDurations[lapIdx];
          var lapStyle = CellStyle.normal;
          if (i == 0 && finished) lapStyle = CellStyle.highlight;
          
          String lapDisplay = TimeFormatter.compact(lapTime);
          if (i > 0 && lapIdx < leaderLapDurations.length) {
            final diff = lapTime - leaderLapDurations[lapIdx];
            if (diff.inMilliseconds > 0) {
              lapDisplay = TimeFormatter.compact(lapTime);
              lapStyle = CellStyle.normal; // Можно сделать CellStyle.error если отставание большое
            }
          }
          cells['lap${lap}_time'] = CellValue(raw: lapTime, display: lapDisplay, style: lapStyle);
        } else {
          cells['lap${lap}_time'] = CellValue.na;
        }
      }

      // Time
      if (athleteTime != null) {
        cells['result_time'] = CellValue(raw: athleteTime, display: TimeFormatter.compact(athleteTime), style: finished ? CellStyle.bold : CellStyle.normal);
      } else {
        cells['result_time'] = CellValue.empty;
      }

      // Gap
      if (leaderTotalTime != null && athleteTime != null && i > 0) {
        final gap = athleteTime - leaderTotalTime;
        if (gap.inMilliseconds > 0) {
          cells['gap_leader'] = CellValue(raw: gap, display: '+${TimeFormatter.compact(gap)}', style: CellStyle.error);
        } else {
          cells['gap_leader'] = CellValue.na;
        }
      } else {
        cells['gap_leader'] = CellValue.na;
      }

      rows.add(ResultRow(entryId: a.id, cells: cells, type: rowType));
    }

    return ResultTable(columns: columns, rows: rows);
  }
}

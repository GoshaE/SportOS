import 'models.dart';
import 'result_table.dart';
import 'time_formatter.dart';
import 'elapsed_calculator.dart';
import '../event/event_config.dart';

/// Строит [ResultTable] из расчётных результатов.
///
/// Единая точка генерации таблиц для всех экранов.
/// Динамически создаёт колонки в зависимости от:
/// - `DisciplineConfig.laps` — количество кругов → lap columns
/// - `DisplaySettings` — какие колонки показывать
///
/// ```dart
/// final table = ResultTableBuilder().build(
///   results: session.calculateResults(),
///   config: session.config,
///   display: session.config.displaySettings,
///   athletes: session.startList.all,
///   marks: session.marking.officialMarks,
/// );
/// // table.columns = [place, bib, name, lap1, lap2, time, gap, ...]
/// // table.rows[0].cell('lap1') → "1:05.3"
/// ```
class ResultTableBuilder {
  final ElapsedCalculator _elapsed;

  const ResultTableBuilder([this._elapsed = const ElapsedCalculator()]);

  // ═══════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════

  /// Построить таблицу результатов.
  ResultTable build({
    required List<RaceResult> results,
    required DisciplineConfig config,
    required DisplaySettings display,
    List<StartEntry>? athletes,
    List<TimeMark>? marks,
  }) {
    final columns = _buildColumns(config, display);
    final rows = _buildRows(results, config, display, athletes, marks);
    return ResultTable(columns: columns, rows: rows);
  }

  // ═══════════════════════════════════════
  // COLUMN GENERATION
  // ═══════════════════════════════════════

  List<ColumnDef> _buildColumns(DisciplineConfig config, DisplaySettings display) {
    final cols = <ColumnDef>[];

    // ── Always present ──
    cols.add(const ColumnDef(id: 'place', label: '№', type: ColumnType.number, align: ColumnAlign.center, flex: 0.5, minWidth: 40));
    cols.add(const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 50));
    cols.add(const ColumnDef(id: 'name', label: 'Спортсмен', type: ColumnType.text, align: ColumnAlign.left, flex: 2.0, minWidth: 140));
    cols.add(const ColumnDef(id: 'category', label: 'Кат.', type: ColumnType.text, align: ColumnAlign.center, flex: 0.8, minWidth: 80));
    cols.add(const ColumnDef(id: 'cat_place', label: '№ Кат.', type: ColumnType.number, align: ColumnAlign.center, flex: 0.5, minWidth: 45));

    // ── Dog name (ездовой спорт) ──
    if (display.showDogNames) {
      cols.add(const ColumnDef(id: 'dog', label: 'Собака', type: ColumnType.text, align: ColumnAlign.left, flex: 1.2, minWidth: 100));
    }

    // ── Club ──
    if (display.showClub) {
      cols.add(const ColumnDef(id: 'club', label: 'Клуб', type: ColumnType.text, align: ColumnAlign.left, flex: 1.0, minWidth: 90));
    }

    // ── Per-lap columns (multi-lap) ──
    if (config.laps > 1 && display.showLapSplits) {
      for (var lap = 1; lap <= config.laps; lap++) {
        cols.add(ColumnDef(
          id: 'lap${lap}_time',
          label: 'Круг $lap',
          type: ColumnType.time,
          align: ColumnAlign.right,
          flex: 1.0,
          minWidth: 75,
        ));
      }
    }

    // ── Per-lap speed (multi-lap) ──
    if (config.laps > 1 && display.showSpeed) {
      for (var lap = 1; lap <= config.laps; lap++) {
        cols.add(ColumnDef(
          id: 'lap${lap}_speed',
          label: 'Скор. Кр.$lap',
          type: ColumnType.speed,
          align: ColumnAlign.right,
          flex: 0.8,
          minWidth: 65,
        ));
      }
    }

    // ── Checkpoint splits (single-lap or explicit) ──
    if (config.laps == 1 && display.showCheckpoints) {
      cols.add(const ColumnDef(id: 'split', label: 'Сплит', type: ColumnType.time, align: ColumnAlign.right, flex: 1.0, minWidth: 75));
    }

    // ── Result time ──
    cols.add(const ColumnDef(id: 'result_time', label: 'Время', type: ColumnType.time, align: ColumnAlign.right, flex: 1.2, minWidth: 85));

    // ── Penalty ──
    cols.add(const ColumnDef(id: 'penalty', label: 'Штр.', type: ColumnType.time, align: ColumnAlign.right, flex: 0.7, minWidth: 55));

    // ── Total speed ──
    if (display.showSpeed) {
      cols.add(const ColumnDef(id: 'total_speed', label: 'Скорость', type: ColumnType.speed, align: ColumnAlign.right, flex: 0.9, minWidth: 65));
    }

    // ── Pace ──
    if (display.showPace) {
      cols.add(const ColumnDef(id: 'pace', label: 'Темп', type: ColumnType.speed, align: ColumnAlign.right, flex: 0.9, minWidth: 60));
    }

    // ── Gap to leader ──
    if (display.showGapToLeader) {
      cols.add(const ColumnDef(id: 'gap_leader', label: '+Лидер', type: ColumnType.gap, align: ColumnAlign.right, flex: 0.9, minWidth: 70));
    }

    // ── Gap to previous ──
    if (display.showGapToPrev) {
      cols.add(const ColumnDef(id: 'gap_prev', label: 'Разрыв', type: ColumnType.gap, align: ColumnAlign.right, flex: 0.9, minWidth: 70));
    }

    return cols;
  }

  // ═══════════════════════════════════════
  // ROW GENERATION
  // ═══════════════════════════════════════

  List<ResultRow> _buildRows(
    List<RaceResult> results,
    DisciplineConfig config,
    DisplaySettings display,
    List<StartEntry>? athletes,
    List<TimeMark>? marks,
  ) {
    // Find best lap for highlighting
    final bestLaps = _findBestLaps(results, config.laps);

    return results.map((r) {
      final cells = <String, CellValue>{};
      final rowType = _rowType(r.status);

      // ── Place ──
      if (r.position > 0) {
        cells['place'] = CellValue(raw: r.position, display: '${r.position}', style: r.position == 1 ? CellStyle.highlight : CellStyle.normal);
      } else {
        cells['place'] = CellValue(raw: null, display: _statusLabel(r.status), style: _statusStyle(r.status));
      }

      // ── BIB ──
      cells['bib'] = CellValue(raw: r.bib, display: r.bib);

      // ── Name ──
      cells['name'] = CellValue(raw: r.name, display: r.name);

      // ── Category ──
      final athlete = athletes?.where((a) => a.bib == r.bib).firstOrNull;
      // Use categoryName from result (populated by ResultCalculator)
      final catName = r.categoryName ?? athlete?.categoryName;
      cells['category'] = CellValue(raw: catName, display: catName ?? '—');

      // ── Category Place ──
      if (r.categoryPosition > 0) {
        cells['cat_place'] = CellValue(raw: r.categoryPosition, display: '${r.categoryPosition}');
      } else {
        cells['cat_place'] = CellValue.na;
      }

      // ── Dog name ──
      if (display.showDogNames) {
        cells['dog'] = CellValue.empty; // dog name resolved by UI from registration data
      }

      // ── Club ──
      if (display.showClub) {
        cells['club'] = const CellValue(display: '—'); // TODO: add club to StartEntry
      }

      // ── Per-lap times ──
      if (config.laps > 1 && display.showLapSplits) {
        for (var lap = 1; lap <= config.laps; lap++) {
          final key = 'lap${lap}_time';
          if (lap <= r.lapTimes.length) {
            final lapDur = r.lapTimes[lap - 1];
            final isBest = bestLaps[lap - 1] == lapDur;
            cells[key] = CellValue(
              raw: lapDur.inMilliseconds,
              display: TimeFormatter.compact(lapDur),
              style: isBest ? CellStyle.highlight : CellStyle.normal,
            );
          } else if (_isTerminal(r.status)) {
            cells[key] = CellValue(display: _statusLabel(r.status), style: _statusStyle(r.status));
          } else {
            // On track — show which lap they're on
            final currentLap = r.lapTimes.length + 1;
            cells[key] = CellValue(
              display: lap == currentLap ? '...' : '',
              style: CellStyle.muted,
            );
          }
        }
      }

      // ── Per-lap speed ──
      if (config.laps > 1 && display.showSpeed) {
        for (var lap = 1; lap <= config.laps; lap++) {
          final key = 'lap${lap}_speed';
          if (lap <= r.lapSpeeds.length && r.lapSpeeds[lap - 1] != null) {
            cells[key] = CellValue(
              raw: r.lapSpeeds[lap - 1],
              display: TimeFormatter.speed(r.lapSpeeds[lap - 1]),
            );
          } else {
            cells[key] = CellValue.empty;
          }
        }
      }

      // ── Checkpoint split (single-lap) ──
      if (config.laps == 1 && display.showCheckpoints) {
        if (r.splitTimes.length > 1) {
          // First split is checkpoint, last is finish
          cells['split'] = CellValue(
            raw: r.splitTimes.first.inMilliseconds,
            display: TimeFormatter.compact(r.splitTimes.first),
          );
        } else {
          cells['split'] = CellValue.empty;
        }
      }

      // ── Result time ──
      if (r.status == AthleteStatus.finished) {
        cells['result_time'] = CellValue(
          raw: r.resultTime.inMilliseconds,
          display: TimeFormatter.compact(r.resultTime),
          style: CellStyle.bold,
        );
      } else if (r.status == AthleteStatus.started) {
        // On track — show current lap or cumulative
        final currentLap = r.lapTimes.length + 1;
        cells['result_time'] = CellValue(
          display: config.laps > 1 ? 'Круг $currentLap/${config.laps}' : '...',
          style: CellStyle.muted,
        );
      } else {
        cells['result_time'] = CellValue(display: _statusLabel(r.status), style: _statusStyle(r.status));
      }

      // ── Penalty ──
      if (r.penaltyTime > Duration.zero) {
        cells['penalty'] = CellValue(
          raw: r.penaltyTime.inMilliseconds,
          display: '+${TimeFormatter.compact(r.penaltyTime)}',
          style: CellStyle.error,
        );
      } else {
        cells['penalty'] = CellValue.na;
      }

      // ── Total speed ──
      if (display.showSpeed) {
        cells['total_speed'] = CellValue(
          raw: r.speedKmh,
          display: TimeFormatter.speed(r.speedKmh),
        );
      }

      // ── Pace ──
      if (display.showPace) {
        final paceVal = config.totalDistanceKm > 0 && r.netTime > Duration.zero
            ? _elapsed.paceMinKm(config.totalDistanceKm, r.netTime)
            : null;
        cells['pace'] = CellValue(
          raw: paceVal,
          display: TimeFormatter.pace(paceVal),
        );
      }

      // ── Gap to leader ──
      if (display.showGapToLeader) {
        cells['gap_leader'] = r.gapToLeader != null
            ? CellValue(raw: r.gapToLeader!.inMilliseconds, display: TimeFormatter.gap(r.gapToLeader!))
            : (r.position == 1
                ? const CellValue(display: '—')
                : CellValue.na);
      }

      // ── Gap to previous ──
      if (display.showGapToPrev) {
        cells['gap_prev'] = r.gapToPrev != null
            ? CellValue(raw: r.gapToPrev!.inMilliseconds, display: TimeFormatter.gap(r.gapToPrev!))
            : CellValue.na;
      }

      return ResultRow(entryId: r.entryId, cells: cells, type: rowType);
    }).toList();
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════

  /// Найти лучшее время на каждом кругу (для подсветки).
  List<Duration?> _findBestLaps(List<RaceResult> results, int totalLaps) {
    final best = List<Duration?>.filled(totalLaps, null);
    for (final r in results) {
      if (r.status != AthleteStatus.finished) continue;
      for (var i = 0; i < r.lapTimes.length && i < totalLaps; i++) {
        if (best[i] == null || r.lapTimes[i] < best[i]!) {
          best[i] = r.lapTimes[i];
        }
      }
    }
    return best;
  }

  RowType _rowType(AthleteStatus status) {
    switch (status) {
      case AthleteStatus.finished: return RowType.finished;
      case AthleteStatus.started: return RowType.onTrack;
      case AthleteStatus.dnf: return RowType.dnf;
      case AthleteStatus.dns: return RowType.dns;
      case AthleteStatus.dsq: return RowType.dsq;
      default: return RowType.waiting;
    }
  }

  String _statusLabel(AthleteStatus status) {
    switch (status) {
      case AthleteStatus.dns: return 'DNS';
      case AthleteStatus.dnf: return 'DNF';
      case AthleteStatus.dsq: return 'DSQ';
      case AthleteStatus.started: return 'LIVE';
      case AthleteStatus.finished: return 'FIN';
      default: return '—';
    }
  }

  CellStyle _statusStyle(AthleteStatus status) {
    switch (status) {
      case AthleteStatus.dsq: return CellStyle.error;
      case AthleteStatus.dnf: return CellStyle.error;
      case AthleteStatus.dns: return CellStyle.muted;
      case AthleteStatus.started: return CellStyle.highlight;
      default: return CellStyle.muted;
    }
  }

  bool _isTerminal(AthleteStatus status) =>
    status == AthleteStatus.dns || status == AthleteStatus.dnf || status == AthleteStatus.dsq;
}

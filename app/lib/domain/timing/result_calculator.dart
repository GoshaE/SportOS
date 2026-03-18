import 'models.dart';
import 'elapsed_calculator.dart';

/// Калькулятор результатов.
///
/// Берёт стартовый лист, отсечки и штрафы → выдаёт отсортированный
/// список [RaceResult] с позициями, разрывами и статусами.
class ResultCalculator {
  final ElapsedCalculator _elapsed;

  const ResultCalculator([this._elapsed = const ElapsedCalculator()]);

  /// Рассчитать результаты для дисциплины.
  ///
  /// Формулы:
  /// ```
  /// NetTime    = finish.correctedTime − athlete.effectiveStartTime
  /// PenaltyTime = Σ penalty.timePenalty (where active)
  /// ResultTime = NetTime + PenaltyTime
  /// GrossTime  = finish.correctedTime − config.firstStartTime
  /// Speed      = config.distanceKm / (NetTime.hours)
  /// ```
  List<RaceResult> calculate({
    required DisciplineConfig config,
    required List<StartEntry> startList,
    required List<TimeMark> marks,
    required List<Penalty> penalties,
  }) {
    final results = <RaceResult>[];

    for (final athlete in startList) {
      // Определить статус
      if (athlete.status == AthleteStatus.dns) {
        results.add(_statusResult(athlete, AthleteStatus.dns));
        continue;
      }
      if (athlete.status == AthleteStatus.dnf) {
        results.add(_partialResult(config, athlete, marks, penalties));
        continue;
      }
      if (athlete.status == AthleteStatus.dsq) {
        results.add(_statusResult(athlete, AthleteStatus.dsq));
        continue;
      }

      // Найти финишную отсечку
      final finishMark = _findFinishMark(athlete.bib, marks, config.laps);

      if (finishMark == null) {
        // Ещё на трассе — показать частичные данные
        results.add(_partialResult(config, athlete, marks, penalties));
        continue;
      }

      // Полный расчёт
      final net = _elapsed.netTime(athlete, finishMark.correctedTime);
      final gross = _elapsed.grossTime(config.firstStartTime, finishMark.correctedTime);
      final penaltyTime = _totalPenalty(athlete.entryId, penalties);
      final result = net + penaltyTime;
      final splits = _elapsed.splitTimes(athlete.bib, marks, athlete);
      final laps = _elapsed.lapTimes(athlete.bib, marks, athlete);
      final speed = _elapsed.speedKmh(config.distanceKm, net);

      // Per-lap speed
      final lapDistKm = config.lapLengthM != null
          ? config.lapLengthM! / 1000.0
          : config.distanceKm / config.laps;
      final lapSpeeds = laps.map((lt) => _elapsed.speedKmh(lapDistKm, lt)).toList();

      results.add(RaceResult(
        entryId: athlete.entryId,
        bib: athlete.bib,
        name: athlete.name,
        grossTime: gross,
        netTime: net,
        penaltyTime: penaltyTime,
        resultTime: result,
        speedKmh: speed,
        splitTimes: splits,
        lapTimes: laps,
        lapSpeeds: lapSpeeds,
        status: AthleteStatus.finished,
      ));
    }

    // Сортировка и расстановка мест
    return _sortAndRank(results, config.tieBreakMode);
  }

  // ─── Sorting & Ranking ───────────────────────────────────────

  List<RaceResult> _sortAndRank(List<RaceResult> results, String tieBreakMode) {
    // Разделить на finished и прочих
    final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
    final onCourse = results.where((r) =>
        r.status == AthleteStatus.started ||
        r.status == AthleteStatus.waiting ||
        r.status == AthleteStatus.current).toList();
    final dnf = results.where((r) => r.status == AthleteStatus.dnf).toList();
    final dns = results.where((r) => r.status == AthleteStatus.dns).toList();
    final dsq = results.where((r) => r.status == AthleteStatus.dsq).toList();

    // Сортировка finished по resultTime
    finished.sort((a, b) => a.resultTime.compareTo(b.resultTime));

    // Расстановка мест
    for (var i = 0; i < finished.length; i++) {
      if (i > 0 &&
          tieBreakMode == 'shared' &&
          finished[i].resultTime == finished[i - 1].resultTime) {
        finished[i].position = finished[i - 1].position; // shared place
      } else {
        finished[i].position = i + 1;
      }
    }

    // Gaps
    final ranked = <RaceResult>[];
    for (var i = 0; i < finished.length; i++) {
      final leaderGap = i == 0
          ? null
          : finished[i].resultTime - finished[0].resultTime;
      final prevGap = i == 0
          ? null
          : finished[i].resultTime - finished[i - 1].resultTime;

      ranked.add(RaceResult(
        entryId: finished[i].entryId,
        bib: finished[i].bib,
        name: finished[i].name,
        grossTime: finished[i].grossTime,
        netTime: finished[i].netTime,
        penaltyTime: finished[i].penaltyTime,
        resultTime: finished[i].resultTime,
        speedKmh: finished[i].speedKmh,
        splitTimes: finished[i].splitTimes,
        lapTimes: finished[i].lapTimes,
        lapSpeeds: finished[i].lapSpeeds,
        position: finished[i].position,
        gapToLeader: leaderGap,
        gapToPrev: prevGap,
        status: finished[i].status,
      ));
    }

    // Собрать всё вместе
    return [...ranked, ...onCourse, ...dnf, ...dns, ...dsq];
  }

  // ─── Helpers ─────────────────────────────────────────────────

  /// Найти финишную отсечку (последний круг).
  TimeMark? _findFinishMark(String bib, List<TimeMark> marks, int totalLaps) {
    final bibMarks = marks
        .where((m) => m.bib == bib && (m.type == MarkType.finish || m.type == MarkType.checkpoint))
        .toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));

    // Финиш — это отсечка на последнем кругу
    if (bibMarks.length >= totalLaps) {
      return bibMarks[totalLaps - 1];
    }
    return null;
  }

  /// Σ штрафов для атлета.
  Duration _totalPenalty(String entryId, List<Penalty> penalties) {
    var total = Duration.zero;
    for (final p in penalties) {
      if (p.entryId == entryId && p.isActive) {
        total += p.timePenalty;
      }
    }
    return total;
  }

  /// Результат без финиша (DNS / DSQ).
  RaceResult _statusResult(StartEntry athlete, AthleteStatus status) {
    return RaceResult(
      entryId: athlete.entryId,
      bib: athlete.bib,
      name: athlete.name,
      grossTime: Duration.zero,
      netTime: Duration.zero,
      penaltyTime: Duration.zero,
      resultTime: Duration.zero,
      status: status,
    );
  }

  /// Частичный результат (на трассе или DNF — показать сплиты).
  RaceResult _partialResult(
    DisciplineConfig config,
    StartEntry athlete,
    List<TimeMark> marks,
    List<Penalty> penalties,
  ) {
    final splits = _elapsed.splitTimes(athlete.bib, marks, athlete);
    final laps = _elapsed.lapTimes(athlete.bib, marks, athlete);
    final penaltyTime = _totalPenalty(athlete.entryId, penalties);

    return RaceResult(
      entryId: athlete.entryId,
      bib: athlete.bib,
      name: athlete.name,
      grossTime: splits.isNotEmpty ? splits.last : Duration.zero,
      netTime: splits.isNotEmpty ? splits.last : Duration.zero,
      penaltyTime: penaltyTime,
      resultTime: (splits.isNotEmpty ? splits.last : Duration.zero) + penaltyTime,
      splitTimes: splits,
      lapTimes: laps,
      status: athlete.status,
    );
  }
}

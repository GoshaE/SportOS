import 'models.dart';

/// Калькулятор elapsed-времени и сплитов.
///
/// Единая точка расчёта для всех экранов:
/// - Финиш: NetTime для протокола
/// - Тренер: elapsed от старта каждого спортсмена
/// - Диктор: split-times для ТОП-5
///
/// Разделение отсечек:
/// - **Finish marks** → используются для lap counting (splitTimes, lapTimes)
/// - **Checkpoint marks** → промежуточные точки внутри круга (checkpointSplits)
class ElapsedCalculator {
  const ElapsedCalculator();

  // ─── Основные формулы ────────────────────────────────────────

  /// NetTime = finishTime − athlete.effectiveStartTime
  ///
  /// Для Individual/Wave/Pursuit: actualStartTime ?? plannedStartTime
  /// Для Mass: всегда plannedStartTime (= GUN time)
  Duration netTime(StartEntry athlete, DateTime finishTime) {
    return finishTime.difference(athlete.effectiveStartTime);
  }

  /// GrossTime = markTime − discipline.zeroTime (общие часы гонки)
  Duration grossTime(DateTime zeroTime, DateTime markTime) {
    return markTime.difference(zeroTime);
  }

  // ─── Split-times (lap boundaries) ────────────────────────────

  /// Split-times: elapsed от старта атлета на каждом кругу.
  ///
  /// Использует только **finish** marks (= прохождение финишной черты).
  /// Возвращает список длиной = количество завершённых кругов.
  /// split[0] = elapsed первого круга от старта
  /// split[n] = elapsed n-го круга от старта (cumulative)
  List<Duration> splitTimes(String bib, List<TimeMark> marks, StartEntry athlete) {
    final finishMarks = _finishMarksForBib(bib, marks);

    return finishMarks.map((m) {
      return m.correctedTime.difference(athlete.effectiveStartTime);
    }).toList();
  }

  /// Длительность каждого круга отдельно.
  ///
  /// Использует только **finish** marks (= прохождение финишной черты).
  /// lap[0] = время первого круга (от старта до первого прохождения финиша)
  /// lap[n] = время n-го круга (от предыдущего прохождения до текущего)
  List<Duration> lapTimes(String bib, List<TimeMark> marks, StartEntry athlete) {
    final finishMarks = _finishMarksForBib(bib, marks);

    if (finishMarks.isEmpty) return [];

    final laps = <Duration>[];

    // Первый круг: от старта до первого прохождения финиша
    laps.add(finishMarks[0].correctedTime.difference(athlete.effectiveStartTime));

    // Последующие круги
    for (var i = 1; i < finishMarks.length; i++) {
      laps.add(finishMarks[i].correctedTime.difference(finishMarks[i - 1].correctedTime));
    }

    return laps;
  }

  /// Elapsed на конкретном кругу (от старта).
  /// Возвращает null если круг ещё не завершён.
  Duration? lapElapsed(String bib, int lap, List<TimeMark> marks, StartEntry athlete) {
    final splits = splitTimes(bib, marks, athlete);
    if (lap < 1 || lap > splits.length) return null;
    return splits[lap - 1];
  }

  // ─── Checkpoint splits (intermediate) ────────────────────────

  /// Промежуточные сплиты от маршальских checkpoint'ов.
  ///
  /// Возвращает список elapsed-времён от старта для каждого checkpoint.
  /// Используется для отображения в протоколе (КП1, КП2...).
  List<Duration> checkpointSplits(String bib, List<TimeMark> marks, StartEntry athlete) {
    final cpMarks = _checkpointMarksForBib(bib, marks);

    return cpMarks.map((m) {
      return m.correctedTime.difference(athlete.effectiveStartTime);
    }).toList();
  }

  /// Сырые checkpoint marks для BIB (для отображения в UI).
  List<TimeMark> checkpointMarksForBib(String bib, List<TimeMark> marks) {
    return _checkpointMarksForBib(bib, marks);
  }

  // ─── Speed ───────────────────────────────────────────────────

  /// Средняя скорость в км/ч
  double? speedKmh(double distanceKm, Duration time) {
    if (time.inMilliseconds <= 0) return null;
    final hours = time.inMilliseconds / 3600000.0;
    return distanceKm / hours;
  }

  /// Темп в мин/км
  double? paceMinKm(double distanceKm, Duration time) {
    if (distanceKm <= 0) return null;
    final minutes = time.inMilliseconds / 60000.0;
    return minutes / distanceKm;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  /// Finish marks для BIB — используются для lap counting.
  ///
  /// Включает только marks с type == finish (прохождение финишной черты).
  /// Checkpoint marks (маршальские промежуточные) исключены.
  List<TimeMark> _finishMarksForBib(String bib, List<TimeMark> marks) {
    return marks
        .where((m) => m.bib == bib && m.type == MarkType.finish)
        .toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }

  /// Checkpoint marks для BIB — промежуточные точки.
  List<TimeMark> _checkpointMarksForBib(String bib, List<TimeMark> marks) {
    return marks
        .where((m) => m.bib == bib && m.type == MarkType.checkpoint)
        .toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }
}

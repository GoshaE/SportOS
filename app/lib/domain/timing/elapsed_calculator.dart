import 'models.dart';

/// Калькулятор elapsed-времени и сплитов.
///
/// Единая точка расчёта для всех экранов:
/// - Финиш: NetTime для протокола
/// - Тренер: elapsed от старта каждого спортсмена
/// - Диктор: split-times для ТОП-5
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

  // ─── Split-times ─────────────────────────────────────────────

  /// Split-times: elapsed от старта атлета на каждом кругу.
  ///
  /// Возвращает список длиной = количество завершённых кругов.
  /// split[0] = время первого круга от старта
  /// split[n] = время n-го круга от старта
  List<Duration> splitTimes(String bib, List<TimeMark> marks, StartEntry athlete) {
    final athleteMarks = _marksForBib(bib, marks)
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));

    return athleteMarks.map((m) {
      return m.correctedTime.difference(athlete.effectiveStartTime);
    }).toList();
  }

  /// Длительность каждого круга отдельно.
  ///
  /// lap[0] = время первого круга (от старта до первой отсечки)
  /// lap[n] = время (n+1)-го круга (от предыдущей отсечки до текущей)
  List<Duration> lapTimes(String bib, List<TimeMark> marks, StartEntry athlete) {
    final athleteMarks = _marksForBib(bib, marks)
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));

    if (athleteMarks.isEmpty) return [];

    final laps = <Duration>[];

    // Первый круг: от старта до первой отсечки
    laps.add(athleteMarks[0].correctedTime.difference(athlete.effectiveStartTime));

    // Последующие круги
    for (var i = 1; i < athleteMarks.length; i++) {
      laps.add(athleteMarks[i].correctedTime.difference(athleteMarks[i - 1].correctedTime));
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

  /// Отфильтровать отсечки для конкретного BIB (checkpoint + finish).
  List<TimeMark> _marksForBib(String bib, List<TimeMark> marks) {
    return marks
        .where((m) =>
            m.bib == bib &&
            (m.type == MarkType.checkpoint || m.type == MarkType.finish))
        .toList();
  }
}

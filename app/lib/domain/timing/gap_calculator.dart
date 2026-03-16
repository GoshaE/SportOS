import 'models.dart';
import 'elapsed_calculator.dart';

/// Калькулятор разрывов (gaps) и трендов.
///
/// Используется для:
/// - Тренерского экрана: таблица разрывов с динамикой ▲/▼
/// - Диктора: отрыв лидера
/// - Протокола: Gap to Leader / Gap to Previous
class GapCalculator {
  final ElapsedCalculator _elapsed;

  const GapCalculator([this._elapsed = const ElapsedCalculator()]);

  // ─── Gap к лидеру ────────────────────────────────────────────

  /// Разрыв от лидера на конкретном кругу.
  ///
  /// Отрицательный → атлет впереди (не должно быть у обычного расчёта).
  Duration? gapToLeader(String bib, int lap, List<TimeMark> marks, List<StartEntry> starts) {
    final leaderElapsed = _bestElapsedAtLap(lap, marks, starts);
    final myElapsed = _elapsedAtLap(bib, lap, marks, starts);

    if (leaderElapsed == null || myElapsed == null) return null;
    return myElapsed - leaderElapsed;
  }

  /// Разрыв от предыдущего атлета в отсортированном списке.
  Duration? gapToPrev(String bib, int lap, List<TimeMark> marks, List<StartEntry> starts) {
    final ranked = rankedAtLap(lap, marks, starts);
    final myIndex = ranked.indexWhere((r) => r.bib == bib);
    if (myIndex <= 0) return null; // лидер или не найден

    return ranked[myIndex].elapsed - ranked[myIndex - 1].elapsed;
  }

  // ─── Тренд ───────────────────────────────────────────────────

  /// Тренд между двумя кругами:
  /// - '▲' — спортсмен сокращает отставание (gaining)
  /// - '▼' — спортсмен теряет (losing)
  /// - '=' — стабильно (±1 сек)
  /// - '' — недостаточно данных
  String trend(String bib, int lap, List<TimeMark> marks, List<StartEntry> starts) {
    if (lap < 2) return '';

    final gapPrev = gapToLeader(bib, lap - 1, marks, starts);
    final gapCurr = gapToLeader(bib, lap, marks, starts);

    if (gapPrev == null || gapCurr == null) return '';

    final diff = gapCurr.inMilliseconds - gapPrev.inMilliseconds;

    // Порог: ±1000 мс = стабильно
    if (diff.abs() < 1000) return '=';
    return diff < 0 ? '▲' : '▼';
  }

  // ─── Полная таблица разрывов ─────────────────────────────────

  /// Строит таблицу разрывов для списка отслеживаемых BIB.
  ///
  /// Одна строка на каждый (bib × lap). Сортировка по elapsed.
  List<GapRow> gapTable(
    List<String> trackedBibs,
    List<TimeMark> marks,
    List<StartEntry> starts,
  ) {
    final rows = <GapRow>[];

    // Определить максимальное кол-во кругов среди tracked
    int maxLap = 0;
    for (final bib in trackedBibs) {
      final athlete = starts.where((s) => s.bib == bib).firstOrNull;
      if (athlete == null) continue;
      final splits = _elapsed.splitTimes(bib, marks, athlete);
      if (splits.length > maxLap) maxLap = splits.length;
    }

    for (int lap = 1; lap <= maxLap; lap++) {
      final lapRows = <GapRow>[];
      for (final bib in trackedBibs) {
        final athlete = starts.where((s) => s.bib == bib).firstOrNull;
        if (athlete == null) continue;

        final elapsed = _elapsedAtLap(bib, lap, marks, starts);
        if (elapsed == null) continue;

        lapRows.add(GapRow(
          bib: bib,
          name: athlete.name,
          lap: lap,
          elapsed: elapsed,
          gapToLeader: gapToLeader(bib, lap, marks, starts),
          gapToPrev: gapToPrev(bib, lap, marks, starts),
          trend: trend(bib, lap, marks, starts),
        ));
      }

      // Сортировка по elapsed внутри круга
      lapRows.sort((a, b) => a.elapsed.compareTo(b.elapsed));
      rows.addAll(lapRows);
    }

    return rows;
  }

  // ─── Ранжирование на кругу ───────────────────────────────────

  /// Ranked list атлетов на данном кругу, отсортированных по elapsed.
  List<RankedEntry> rankedAtLap(int lap, List<TimeMark> marks, List<StartEntry> starts) {
    final entries = <RankedEntry>[];

    for (final athlete in starts) {
      final elapsed = _elapsedAtLap(athlete.bib, lap, marks, starts);
      if (elapsed == null) continue;
      entries.add(RankedEntry(bib: athlete.bib, name: athlete.name, elapsed: elapsed));
    }

    entries.sort((a, b) => a.elapsed.compareTo(b.elapsed));
    return entries;
  }

  // ─── Internal helpers ────────────────────────────────────────

  /// Elapsed от старта атлета на данном кругу.
  Duration? _elapsedAtLap(String bib, int lap, List<TimeMark> marks, List<StartEntry> starts) {
    final athlete = starts.where((s) => s.bib == bib).firstOrNull;
    if (athlete == null) return null;
    return _elapsed.lapElapsed(bib, lap, marks, athlete);
  }

  /// Лучший (минимальный) elapsed на данном кругу.
  Duration? _bestElapsedAtLap(int lap, List<TimeMark> marks, List<StartEntry> starts) {
    Duration? best;
    for (final athlete in starts) {
      final e = _elapsed.lapElapsed(athlete.bib, lap, marks, athlete);
      if (e != null && (best == null || e < best)) {
        best = e;
      }
    }
    return best;
  }
}

/// Структура для ранжирования атлетов.
class RankedEntry {
  final String bib;
  final String name;
  final Duration elapsed;

  const RankedEntry({required this.bib, required this.name, required this.elapsed});
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';

void main() {
  const calc = ElapsedCalculator();

  // ─── Helper factories ──────────────────────────────────────────

  final start = DateTime(2026, 3, 18, 10, 0, 0);
  var markId = 0;

  StartEntry athlete_({
    String bib = '1',
    DateTime? actualStart,
    DateTime? plannedStart,
  }) {
    return StartEntry(
      entryId: 'e-$bib',
      bib: bib,
      name: 'Test Athlete',
      startPosition: 1,
      plannedStartTime: plannedStart ?? start,
      actualStartTime: actualStart,
    );
  }

  TimeMark mark_({
    required DateTime time,
    String bib = '1',
    MarkType type = MarkType.finish,
  }) {
    markId++;
    return TimeMark(
      id: 'tm-$markId',
      bib: bib,
      rawTime: time,
      type: type,
    );
  }

  setUp(() => markId = 0);

  // ═══════════════════════════════════════════════════════════════
  // NetTime
  // ═══════════════════════════════════════════════════════════════

  group('netTime', () {
    test('finish − effectiveStart', () {
      final a = athlete_(actualStart: start);
      final finish = start.add(const Duration(minutes: 5, seconds: 30));
      final net = calc.netTime(a, finish);
      expect(net, const Duration(minutes: 5, seconds: 30));
    });

    test('uses plannedStart when actualStart is null', () {
      final a = athlete_(); // no actualStart
      final finish = start.add(const Duration(minutes: 3));
      expect(calc.netTime(a, finish), const Duration(minutes: 3));
    });

    test('uses actualStart when both present', () {
      final planned = start;
      final actual = start.add(const Duration(seconds: 5));
      final a = athlete_(plannedStart: planned, actualStart: actual);
      final finish = start.add(const Duration(minutes: 3));
      // net = finish − actual = 3min − 5sec = 2:55
      expect(calc.netTime(a, finish), const Duration(minutes: 2, seconds: 55));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // GrossTime
  // ═══════════════════════════════════════════════════════════════

  group('grossTime', () {
    test('markTime − zeroTime', () {
      final markTime = start.add(const Duration(hours: 1, seconds: 15));
      expect(calc.grossTime(start, markTime), const Duration(hours: 1, seconds: 15));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Split Times (finish marks only)
  // ═══════════════════════════════════════════════════════════════

  group('splitTimes', () {
    test('returns cumulative elapsed per finish mark', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 2))),              // lap 1 finish
        mark_(time: start.add(const Duration(minutes: 4, seconds: 30))), // lap 2 finish
      ];

      final splits = calc.splitTimes('1', marks, a);
      expect(splits.length, 2);
      expect(splits[0], const Duration(minutes: 2));
      expect(splits[1], const Duration(minutes: 4, seconds: 30));
    });

    test('ignores checkpoint marks — only finish marks', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 1)), type: MarkType.checkpoint), // CP
        mark_(time: start.add(const Duration(minutes: 2)), type: MarkType.finish),      // lap 1
        mark_(time: start.add(const Duration(minutes: 3)), type: MarkType.checkpoint), // CP
        mark_(time: start.add(const Duration(minutes: 4)), type: MarkType.finish),      // lap 2
      ];

      final splits = calc.splitTimes('1', marks, a);
      expect(splits.length, 2); // not 4!
      expect(splits[0], const Duration(minutes: 2));
      expect(splits[1], const Duration(minutes: 4));
    });

    test('empty when no finish marks', () {
      final a = athlete_(actualStart: start);
      expect(calc.splitTimes('1', [], a), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Lap Times (per-lap duration)
  // ═══════════════════════════════════════════════════════════════

  group('lapTimes', () {
    test('first lap from start, subsequent from previous finish', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 2))),             // lap 1
        mark_(time: start.add(const Duration(minutes: 4, seconds: 30))), // lap 2
        mark_(time: start.add(const Duration(minutes: 7))),             // lap 3
      ];

      final laps = calc.lapTimes('1', marks, a);
      expect(laps.length, 3);
      expect(laps[0], const Duration(minutes: 2));             // lap 1
      expect(laps[1], const Duration(minutes: 2, seconds: 30)); // lap 2
      expect(laps[2], const Duration(minutes: 2, seconds: 30)); // lap 3
    });

    test('does not mix checkpoint and finish marks for laps', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 1)), type: MarkType.checkpoint),
        mark_(time: start.add(const Duration(minutes: 2)), type: MarkType.finish),
      ];

      final laps = calc.lapTimes('1', marks, a);
      expect(laps.length, 1); // only 1 finish mark = 1 lap
      expect(laps[0], const Duration(minutes: 2));
    });

    test('empty when no marks', () {
      final a = athlete_(actualStart: start);
      expect(calc.lapTimes('1', [], a), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Checkpoint Splits
  // ═══════════════════════════════════════════════════════════════

  group('checkpointSplits', () {
    test('returns elapsed for checkpoint marks only', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 1)), type: MarkType.checkpoint),
        mark_(time: start.add(const Duration(minutes: 2)), type: MarkType.finish),
        mark_(time: start.add(const Duration(minutes: 3)), type: MarkType.checkpoint),
      ];

      final cps = calc.checkpointSplits('1', marks, a);
      expect(cps.length, 2); // 2 checkpoints, not 3 total
      expect(cps[0], const Duration(minutes: 1));
      expect(cps[1], const Duration(minutes: 3));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Speed & Pace
  // ═══════════════════════════════════════════════════════════════

  group('speedKmh', () {
    test('10 km in 30 min = 20 km/h', () {
      expect(calc.speedKmh(10.0, const Duration(minutes: 30)), 20.0);
    });

    test('returns null for zero time', () {
      expect(calc.speedKmh(10.0, Duration.zero), isNull);
    });

    test('returns null for negative time', () {
      expect(calc.speedKmh(10.0, const Duration(seconds: -1)), isNull);
    });
  });

  group('paceMinKm', () {
    test('10 km in 50 min = 5.0 min/km', () {
      expect(calc.paceMinKm(10.0, const Duration(minutes: 50)), 5.0);
    });

    test('returns null for zero distance', () {
      expect(calc.paceMinKm(0, const Duration(minutes: 50)), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // lapElapsed
  // ═══════════════════════════════════════════════════════════════

  group('lapElapsed', () {
    test('returns elapsed at specific lap', () {
      final a = athlete_(actualStart: start);
      final marks = [
        mark_(time: start.add(const Duration(minutes: 2))),
        mark_(time: start.add(const Duration(minutes: 5))),
      ];

      expect(calc.lapElapsed('1', 1, marks, a), const Duration(minutes: 2));
      expect(calc.lapElapsed('1', 2, marks, a), const Duration(minutes: 5));
    });

    test('returns null for incomplete lap', () {
      final a = athlete_(actualStart: start);
      expect(calc.lapElapsed('1', 1, [], a), isNull);
    });

    test('returns null for out-of-range lap', () {
      final a = athlete_(actualStart: start);
      final marks = [mark_(time: start.add(const Duration(minutes: 2)))];
      expect(calc.lapElapsed('1', 0, marks, a), isNull);
      expect(calc.lapElapsed('1', 3, marks, a), isNull);
    });
  });
}

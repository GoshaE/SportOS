import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';

void main() {
  late ResultCalculator calc;

  setUp(() {
    calc = ResultCalculator(const ElapsedCalculator());
  });

  // ─── Helpers ────────────────────────────────────────────────

  final start = DateTime(2026, 3, 18, 10, 0, 0);

  DisciplineConfig config_({
    int laps = 1,
    double distanceKm = 6.0,
    String tieBreakMode = 'shared',
    Duration? cutoffTime,
  }) {
    return DisciplineConfig(
      id: 'test',
      name: 'Test',
      distanceKm: distanceKm,
      startType: StartType.individual,
      firstStartTime: start,
      laps: laps,
      tieBreakMode: tieBreakMode,
      cutoffTime: cutoffTime,
    );
  }

  var markId = 0;

  StartEntry athlete_({
    required String bib,
    String name = 'Athlete',
    String? category,
    AthleteStatus status = AthleteStatus.started,
    DateTime? actualStart,
  }) {
    return StartEntry(
      entryId: 'e-$bib',
      bib: bib,
      name: name,
      categoryName: category,
      startPosition: int.parse(bib),
      plannedStartTime: start,
      actualStartTime: actualStart ?? start,
      status: status,
    );
  }

  TimeMark finish_({
    required String bib,
    required Duration after,
  }) {
    markId++;
    return TimeMark(
      id: 'tm-$markId',
      bib: bib,
      rawTime: start.add(after),
      type: MarkType.finish,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Basic Ranking
  // ═══════════════════════════════════════════════════════════════

  group('Basic ranking', () {
    test('sorts by result time and assigns positions', () {
      final results = calc.calculate(
        config: config_(),
        startList: [
          athlete_(bib: '1'),
          athlete_(bib: '2'),
          athlete_(bib: '3'),
        ],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 5)),
          finish_(bib: '2', after: const Duration(minutes: 3)),  // fastest
          finish_(bib: '3', after: const Duration(minutes: 4)),
        ],
        penalties: [],
      );

      // Finished athletes should be sorted by time
      final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
      expect(finished[0].bib, '2');  // 3 min — 1st
      expect(finished[0].position, 1);
      expect(finished[1].bib, '3');  // 4 min — 2nd
      expect(finished[1].position, 2);
      expect(finished[2].bib, '1');  // 5 min — 3rd
      expect(finished[2].position, 3);
    });

    test('shared positions for equal times', () {
      final results = calc.calculate(
        config: config_(tieBreakMode: 'shared'),
        startList: [
          athlete_(bib: '1'),
          athlete_(bib: '2'),
          athlete_(bib: '3'),
        ],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 5)),
          finish_(bib: '2', after: const Duration(minutes: 5)), // same time
          finish_(bib: '3', after: const Duration(minutes: 6)),
        ],
        penalties: [],
      );

      final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
      expect(finished[0].position, 1);
      expect(finished[1].position, 1); // shared
      expect(finished[2].position, 3); // skips 2
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Gaps
  // ═══════════════════════════════════════════════════════════════

  group('Gap calculation in results', () {
    test('gap to leader and previous', () {
      final results = calc.calculate(
        config: config_(),
        startList: [
          athlete_(bib: '1'),
          athlete_(bib: '2'),
          athlete_(bib: '3'),
        ],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 3)),
          finish_(bib: '2', after: const Duration(minutes: 5)),
          finish_(bib: '3', after: const Duration(minutes: 8)),
        ],
        penalties: [],
      );

      final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
      // Leader: no gaps
      expect(finished[0].gapToLeader, isNull);
      expect(finished[0].gapToPrev, isNull);
      // 2nd place: +2 min from leader, +2 min from prev
      expect(finished[1].gapToLeader, const Duration(minutes: 2));
      expect(finished[1].gapToPrev, const Duration(minutes: 2));
      // 3rd place: +5 min from leader, +3 min from prev
      expect(finished[2].gapToLeader, const Duration(minutes: 5));
      expect(finished[2].gapToPrev, const Duration(minutes: 3));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Penalties
  // ═══════════════════════════════════════════════════════════════

  group('Penalties', () {
    test('penalty time added to result', () {
      final results = calc.calculate(
        config: config_(),
        startList: [athlete_(bib: '1')],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 3)),
        ],
        penalties: [
          Penalty(
            id: 'p1',
            entryId: 'e-1',
            reason: 'False start',
            timePenalty: const Duration(seconds: 30),
          ),
        ],
      );

      final r = results.first;
      expect(r.netTime, const Duration(minutes: 3));
      expect(r.penaltyTime, const Duration(seconds: 30));
      expect(r.resultTime, const Duration(minutes: 3, seconds: 30));
    });

    test('penalty can change ranking', () {
      final results = calc.calculate(
        config: config_(),
        startList: [athlete_(bib: '1'), athlete_(bib: '2')],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 3)),
          finish_(bib: '2', after: const Duration(minutes: 3, seconds: 20)),
        ],
        penalties: [
          Penalty(
            id: 'p1',
            entryId: 'e-1',
            reason: 'Penalty',
            timePenalty: const Duration(minutes: 1), // pushes bib 1 to 4:00
          ),
        ],
      );

      final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
      expect(finished[0].bib, '2'); // 3:20 — now 1st
      expect(finished[1].bib, '1'); // 3:00 + 1:00 = 4:00 — now 2nd
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Status ordering
  // ═══════════════════════════════════════════════════════════════

  group('Status ordering', () {
    test('order: finished → on course → DNF → DNS → DSQ', () {
      final results = calc.calculate(
        config: config_(),
        startList: [
          athlete_(bib: '1', status: AthleteStatus.dns),
          athlete_(bib: '2', status: AthleteStatus.dnf),
          athlete_(bib: '3', status: AthleteStatus.dsq),
          athlete_(bib: '4'), // started, on course (no finish mark)
          athlete_(bib: '5'), // finished
        ],
        marks: [
          finish_(bib: '5', after: const Duration(minutes: 3)),
        ],
        penalties: [],
      );

      expect(results[0].bib, '5');  // finished first
      expect(results[0].status, AthleteStatus.finished);
      // on course next
      expect(results[1].bib, '4');
      expect(results[1].status, AthleteStatus.started);
      // then DNF
      expect(results[2].status, AthleteStatus.dnf);
      // then DNS
      expect(results[3].status, AthleteStatus.dns);
      // then DSQ
      expect(results[4].status, AthleteStatus.dsq);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Category Ranking (P2)
  // ═══════════════════════════════════════════════════════════════

  group('Category ranking', () {
    test('assigns category positions independently', () {
      final results = calc.calculate(
        config: config_(),
        startList: [
          athlete_(bib: '1', category: 'M'),
          athlete_(bib: '2', category: 'F'),
          athlete_(bib: '3', category: 'M'),
          athlete_(bib: '4', category: 'F'),
        ],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 3)),
          finish_(bib: '2', after: const Duration(minutes: 4)),
          finish_(bib: '3', after: const Duration(minutes: 5)),
          finish_(bib: '4', after: const Duration(minutes: 6)),
        ],
        penalties: [],
      );

      final finished = results.where((r) => r.status == AthleteStatus.finished).toList();
      // Absolute: 1→bib1, 2→bib2, 3→bib3, 4→bib4
      // Category M: bib1=1st, bib3=2nd
      // Category F: bib2=1st, bib4=2nd
      final bib1 = finished.firstWhere((r) => r.bib == '1');
      final bib2 = finished.firstWhere((r) => r.bib == '2');
      final bib3 = finished.firstWhere((r) => r.bib == '3');
      final bib4 = finished.firstWhere((r) => r.bib == '4');

      expect(bib1.position, 1); // absolute 1st
      expect(bib1.categoryPosition, 1); // M 1st
      expect(bib2.position, 2); // absolute 2nd
      expect(bib2.categoryPosition, 1); // F 1st
      expect(bib3.categoryPosition, 2); // M 2nd
      expect(bib4.categoryPosition, 2); // F 2nd
    });

    test('categoryName propagated to result', () {
      final results = calc.calculate(
        config: config_(),
        startList: [athlete_(bib: '1', category: 'Juniors')],
        marks: [finish_(bib: '1', after: const Duration(minutes: 3))],
        penalties: [],
      );

      expect(results.first.categoryName, 'Juniors');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Multi-lap finish detection (P4)
  // ═══════════════════════════════════════════════════════════════

  group('Multi-lap finish detection', () {
    test('finish requires N finish marks for N laps', () {
      final results = calc.calculate(
        config: config_(laps: 3),
        startList: [athlete_(bib: '1')],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 2)),
          finish_(bib: '1', after: const Duration(minutes: 4)),
          // only 2 finish marks, need 3 → still on course
        ],
        penalties: [],
      );

      expect(results.first.status, AthleteStatus.started); // not finished
    });

    test('checkpoint marks do not count as laps', () {
      final results = calc.calculate(
        config: config_(laps: 2),
        startList: [athlete_(bib: '1')],
        marks: [
          TimeMark(id: 'tm-cp1', bib: '1', rawTime: start.add(const Duration(minutes: 1)), type: MarkType.checkpoint),
          finish_(bib: '1', after: const Duration(minutes: 2)),
          // 1 CP + 1 finish = only 1 lap completed
        ],
        penalties: [],
      );

      expect(results.first.status, AthleteStatus.started); // need 2 finish marks
    });

    test('finishes with correct number of finish marks', () {
      final results = calc.calculate(
        config: config_(laps: 2),
        startList: [athlete_(bib: '1')],
        marks: [
          finish_(bib: '1', after: const Duration(minutes: 2)),
          finish_(bib: '1', after: const Duration(minutes: 4)),
        ],
        penalties: [],
      );

      expect(results.first.status, AthleteStatus.finished);
      expect(results.first.netTime, const Duration(minutes: 4));
    });
  });
}

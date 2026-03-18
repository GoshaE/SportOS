import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';

void main() {
  late GapCalculator gap;

  setUp(() {
    gap = GapCalculator(const ElapsedCalculator());
  });

  final start = DateTime(2026, 3, 18, 10, 0, 0);
  var markId = 0;

  StartEntry athlete_({required String bib, DateTime? actualStart}) {
    return StartEntry(
      entryId: 'e-$bib',
      bib: bib,
      name: 'A-$bib',
      startPosition: int.parse(bib),
      plannedStartTime: start,
      actualStartTime: actualStart ?? start,
      status: AthleteStatus.started,
    );
  }

  TimeMark mark_({required String bib, required Duration after}) {
    markId++;
    return TimeMark(
      id: 'tm-$markId',
      bib: bib,
      rawTime: start.add(after),
      type: MarkType.finish,
    );
  }

  setUp(() => markId = 0);

  // ═══════════════════════════════════════════════════════════════
  // Gap to Leader
  // ═══════════════════════════════════════════════════════════════

  group('gapToLeader', () {
    test('leader has zero gap', () {
      final starts = [athlete_(bib: '1'), athlete_(bib: '2')];
      final marks = [
        mark_(bib: '1', after: const Duration(minutes: 3)),
        mark_(bib: '2', after: const Duration(minutes: 5)),
      ];

      final gapRow = gap.gapTable(['1', '2'], marks, starts);
      final leader = gapRow.firstWhere((g) => g.bib == '1');
      expect(leader.gapToLeader, Duration.zero);
    });

    test('calculates gap correctly', () {
      final starts = [athlete_(bib: '1'), athlete_(bib: '2')];
      final marks = [
        mark_(bib: '1', after: const Duration(minutes: 3)),
        mark_(bib: '2', after: const Duration(minutes: 5)),
      ];

      final gapRow = gap.gapTable(['1', '2'], marks, starts);
      final second = gapRow.firstWhere((g) => g.bib == '2');
      expect(second.gapToLeader, const Duration(minutes: 2));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Gap to Previous
  // ═══════════════════════════════════════════════════════════════

  group('gapToPrev', () {
    test('calculates gap to previous correctly', () {
      final starts = [
        athlete_(bib: '1'),
        athlete_(bib: '2'),
        athlete_(bib: '3'),
      ];
      final marks = [
        mark_(bib: '1', after: const Duration(minutes: 3)),
        mark_(bib: '2', after: const Duration(minutes: 5)),
        mark_(bib: '3', after: const Duration(minutes: 9)),
      ];

      final gapRow = gap.gapTable(['1', '2', '3'], marks, starts);
      final third = gapRow.firstWhere((g) => g.bib == '3');
      expect(third.gapToPrev, const Duration(minutes: 4));  // 9-5 = 4min
      expect(third.gapToLeader, const Duration(minutes: 6)); // 9-3 = 6min
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Athletes without marks
  // ═══════════════════════════════════════════════════════════════

  group('Athletes without marks', () {
    test('athletes without marks excluded from gap table', () {
      final starts = [athlete_(bib: '1'), athlete_(bib: '2')];
      final marks = [
        mark_(bib: '1', after: const Duration(minutes: 3)),
        // bib 2 has no marks
      ];

      final gapRow = gap.gapTable(['1', '2'], marks, starts);
      expect(gapRow.length, 1);
      expect(gapRow.first.bib, '1');
    });
  });
}

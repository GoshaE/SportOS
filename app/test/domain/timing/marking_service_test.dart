import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';

void main() {
  late MarkingService service;
  final baseTime = DateTime(2026, 3, 18, 10, 0, 0);

  setUp(() {
    service = MarkingService(
      minLapTime: const Duration(seconds: 20),
      totalLaps: 3,
    );
  });

  // ═══════════════════════════════════════════════════════════════
  // Add Mark
  // ═══════════════════════════════════════════════════════════════

  group('addMark', () {
    test('creates unassigned mark', () {
      final mark = service.addMark();
      expect(mark.bib, isNull);
      expect(mark.type, MarkType.finish);
      expect(service.unassigned.length, 1);
    });

    test('creates checkpoint mark', () {
      final mark = service.addMark(type: MarkType.checkpoint);
      expect(mark.type, MarkType.checkpoint);
    });

    test('totalMarks increments', () {
      expect(service.totalMarks, 0);
      service.addMark();
      expect(service.totalMarks, 1);
      service.addMark();
      expect(service.totalMarks, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Assign / Unassign BIB
  // ═══════════════════════════════════════════════════════════════

  group('assignBib', () {
    test('assigns BIB to unassigned mark', () {
      final mark = service.addMark();
      final ok = service.assignBib(mark.id, '42');
      expect(ok, isTrue);
      expect(service.unassigned, isEmpty);
      expect(service.assigned.length, 1);
      expect(service.assigned.first.bib, '42');
    });

    test('unassignBib returns mark to unassigned', () {
      final mark = service.addMark();
      service.assignBib(mark.id, '42');
      service.unassignBib(mark.id);
      expect(service.unassigned.length, 1);
      expect(service.assigned, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Swap BIB
  // ═══════════════════════════════════════════════════════════════

  group('swapBib', () {
    test('swaps BIB on assigned mark', () {
      final mark = service.addMark();
      service.assignBib(mark.id, '42');
      service.swapBib(mark.id, '99');
      expect(service.marksForBib('99').length, 1);
      expect(service.marksForBib('42'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Correct Time
  // ═══════════════════════════════════════════════════════════════

  group('correctTime', () {
    test('updates mark time and records reason', () {
      final mark = service.addMark();
      service.assignBib(mark.id, '1');

      final newTime = mark.rawTime.add(const Duration(seconds: 2));
      service.correctTime(mark.id, newTime, 'Photo finish review');

      final updated = service.marksForBib('1').first;
      expect(updated.correctedTime, newTime);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Insert Mark
  // ═══════════════════════════════════════════════════════════════

  group('insertMark', () {
    test('inserts manual mark with specific time', () {
      final t = DateTime(2026, 3, 18, 10, 5, 30);
      final mark = service.insertMark(t, bib: '5', reason: 'Manual entry');
      expect(mark.bib, '5');
      expect(mark.correctedTime, t);
      expect(service.totalMarks, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Delete Mark
  // ═══════════════════════════════════════════════════════════════

  group('deleteMark', () {
    test('removes mark from service', () {
      final mark = service.addMark();
      service.assignBib(mark.id, '1');
      expect(service.totalMarks, 1);

      service.deleteMark(mark.id);
      expect(service.totalMarks, 0);
      expect(service.marksForBib('1'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Lap Resolution (using insertMark for precise time control)
  // ═══════════════════════════════════════════════════════════════

  group('resolveCurrentLap', () {
    test('starts at lap 1', () {
      expect(service.resolveCurrentLap('1'), 1);
    });

    test('increments after official mark', () {
      // Insert a mark with bib assigned — bypasses minLapTime check
      service.insertMark(baseTime, bib: '1');
      // After one official mark, should be on lap 2
      expect(service.resolveCurrentLap('1'), 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // isLastLap
  // ═══════════════════════════════════════════════════════════════

  group('isLastLap', () {
    test('false at start', () {
      expect(service.isLastLap('1'), isFalse);
    });

    test('true on last lap', () {
      // totalLaps = 3. Insert 2 marks → resolveCurrentLap = 3 (last lap!)
      service.insertMark(baseTime, bib: '1');
      service.insertMark(baseTime.add(const Duration(minutes: 1)), bib: '1');
      expect(service.isLastLap('1'), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Finished Count
  // ═══════════════════════════════════════════════════════════════

  group('finishedCount', () {
    test('counts athletes with all laps completed', () {
      expect(service.finishedCount, 0);
      // Complete 3 laps for bib 1 (with proper time gaps for minLapTime)
      service.insertMark(baseTime, bib: '1');
      service.insertMark(baseTime.add(const Duration(minutes: 1)), bib: '1');
      service.insertMark(baseTime.add(const Duration(minutes: 2)), bib: '1');
      expect(service.finishedCount, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // MinLapTime rejection
  // ═══════════════════════════════════════════════════════════════

  group('minLapTime', () {
    test('assignBib rejects mark within minLapTime', () {
      // First mark
      final m1 = service.addMark();
      service.assignBib(m1.id, '1');

      // Second mark — created almost at same instant
      final m2 = service.addMark();
      // assignBib should return false because gap < 20 sec
      final ok = service.assignBib(m2.id, '1');
      expect(ok, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';

void main() {
  final start = DateTime(2026, 3, 18, 10, 0, 0);

  DisciplineConfig config_({
    StartType startType = StartType.individual,
    Duration interval = const Duration(seconds: 30),
    bool manualStart = false,
    Duration? cutoffTime,
  }) {
    return DisciplineConfig(
      id: 'test',
      name: 'Test',
      distanceKm: 6.0,
      startType: startType,
      interval: interval,
      firstStartTime: start,
      manualStart: manualStart,
      laps: 1,
      cutoffTime: cutoffTime,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Individual Start
  // ═══════════════════════════════════════════════════════════════

  group('Individual start', () {
    test('creates start list with planned times', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
        (entryId: 'e2', bib: '2', name: 'B', category: null, waveId: null),
        (entryId: 'e3', bib: '3', name: 'C', category: null, waveId: null),
      ]);

      expect(service.all.length, 3);
      expect(service.all[0].plannedStartTime, start);
      expect(service.all[1].plannedStartTime, start.add(const Duration(seconds: 30)));
      expect(service.all[2].plannedStartTime, start.add(const Duration(seconds: 60)));
    });

    test('markStarted transitions status', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);

      // First athlete gets 'current' status (next to start)
      expect(service.all[0].status, AthleteStatus.current);
      service.markStarted('1', actualTime: start);
      expect(service.all[0].status, AthleteStatus.started);
      expect(service.all[0].actualStartTime, start);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Mass Start
  // ═══════════════════════════════════════════════════════════════

  group('Mass start', () {
    test('all athletes get same planned time', () {
      final service = StartListService(config: config_(startType: StartType.mass));
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
        (entryId: 'e2', bib: '2', name: 'B', category: null, waveId: null),
      ]);

      expect(service.all[0].plannedStartTime, start);
      expect(service.all[1].plannedStartTime, start);
    });

    test('markStartedAll starts everyone with gun time', () {
      final service = StartListService(config: config_(startType: StartType.mass));
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
        (entryId: 'e2', bib: '2', name: 'B', category: null, waveId: null),
      ]);

      service.markStartedAll(gunTime: start);
      expect(service.all.every((a) => a.status == AthleteStatus.started), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // DNS / DNF / DSQ
  // ═══════════════════════════════════════════════════════════════

  group('DNS', () {
    test('markDns changes status', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);

      service.markDns('1');
      expect(service.all[0].status, AthleteStatus.dns);
    });

    test('undoDns restores to waiting', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);

      service.markDns('1');
      service.undoDns('1');
      expect(service.all[0].status, AthleteStatus.waiting);
    });
  });

  group('DNF', () {
    test('markDnf changes started to dnf', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);
      service.markStarted('1', actualTime: start);

      service.markDnf('1');
      expect(service.all[0].status, AthleteStatus.dnf);
    });

    test('undoDnf restores to started', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);
      service.markStarted('1', actualTime: start);
      service.markDnf('1');
      service.undoDnf('1');
      expect(service.all[0].status, AthleteStatus.started);
    });
  });

  group('DSQ', () {
    test('markDsq changes status', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);

      service.markDsq('1');
      expect(service.all[0].status, AthleteStatus.dsq);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Force Start
  // ═══════════════════════════════════════════════════════════════

  group('forceStart', () {
    test('starts athlete immediately', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
      ]);

      final now = start.add(const Duration(minutes: 1));
      service.forceStart('1', actualTime: now);
      expect(service.all[0].status, AthleteStatus.started);
      expect(service.all[0].actualStartTime, now);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Counters
  // ═══════════════════════════════════════════════════════════════

  group('Counters', () {
    test('remaining and startedCount', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: null, waveId: null),
        (entryId: 'e2', bib: '2', name: 'B', category: null, waveId: null),
        (entryId: 'e3', bib: '3', name: 'C', category: null, waveId: null),
      ]);

      expect(service.remaining, 3);
      expect(service.startedCount, 0);

      service.markStarted('1', actualTime: start);
      expect(service.remaining, 2);
      expect(service.startedCount, 1);

      service.markDns('2');
      expect(service.remaining, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Category propagation
  // ═══════════════════════════════════════════════════════════════

  group('Category', () {
    test('preserves category name', () {
      final service = StartListService(config: config_());
      service.buildStartList([
        (entryId: 'e1', bib: '1', name: 'A', category: 'Juniors', waveId: null),
      ]);

      expect(service.all[0].categoryName, 'Juniors');
    });
  });
}

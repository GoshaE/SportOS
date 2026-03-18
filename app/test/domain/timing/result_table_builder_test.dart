import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/timing.dart';
import 'package:sportos_app/domain/event/event_config.dart';

void main() {
  late ResultTableBuilder builder;

  setUp(() {
    builder = const ResultTableBuilder();
  });

  DisciplineConfig config_({int laps = 1, double distanceKm = 6.0}) {
    return DisciplineConfig(
      id: 'test',
      name: 'Test',
      distanceKm: distanceKm,
      startType: StartType.individual,
      firstStartTime: DateTime(2026, 3, 18, 10, 0),
      laps: laps,
    );
  }

  RaceResult result_({
    required String bib,
    String name = 'Athlete',
    Duration netTime = Duration.zero,
    Duration resultTime = Duration.zero,
    AthleteStatus status = AthleteStatus.finished,
    int position = 0,
    List<Duration> lapTimes = const [],
    List<Duration> splitTimes = const [],
    List<double?> lapSpeeds = const [],
    Duration? gapToLeader,
  }) {
    return RaceResult(
      entryId: 'e-$bib',
      bib: bib,
      name: name,
      grossTime: netTime,
      netTime: netTime,
      penaltyTime: Duration.zero,
      resultTime: resultTime.inMilliseconds > 0 ? resultTime : netTime,
      status: status,
      position: position,
      lapTimes: lapTimes,
      splitTimes: splitTimes,
      lapSpeeds: lapSpeeds,
      gapToLeader: gapToLeader,
    );
  }

  group('Column generation', () {
    test('single-lap generates basic columns', () {
      final table = builder.build(
        results: [],
        config: config_(laps: 1),
        display: const DisplaySettings(showGapToLeader: false),
      );

      final ids = table.columnIds;
      expect(ids, contains('place'));
      expect(ids, contains('bib'));
      expect(ids, contains('name'));
      expect(ids, contains('result_time'));
      expect(ids, isNot(contains('lap1_time')));
      expect(ids, isNot(contains('lap2_time')));
    });

    test('multi-lap generates per-lap columns', () {
      final table = builder.build(
        results: [],
        config: config_(laps: 3),
        display: const DisplaySettings(showLapSplits: true, showGapToLeader: false),
      );

      final ids = table.columnIds;
      expect(ids, contains('lap1_time'));
      expect(ids, contains('lap2_time'));
      expect(ids, contains('lap3_time'));
      expect(ids, isNot(contains('lap4_time')));
    });

    test('speed columns generated when showSpeed=true', () {
      final table = builder.build(
        results: [],
        config: config_(laps: 2),
        display: const DisplaySettings(showSpeed: true, showGapToLeader: false),
      );

      final ids = table.columnIds;
      expect(ids, contains('total_speed'));
      expect(ids, contains('lap1_speed'));
      expect(ids, contains('lap2_speed'));
    });

    test('gap columns generated when enabled', () {
      final table = builder.build(
        results: [],
        config: config_(laps: 1),
        display: const DisplaySettings(showGapToLeader: true, showGapToPrev: true),
      );

      final ids = table.columnIds;
      expect(ids, contains('gap_leader'));
      expect(ids, contains('gap_prev'));
    });
  });

  group('Row generation', () {
    test('finished athlete has correct cells', () {
      final table = builder.build(
        results: [
          result_(
            bib: '1',
            name: 'Петров',
            netTime: const Duration(minutes: 2, seconds: 5),
            position: 1,
          ),
        ],
        config: config_(laps: 1),
        display: const DisplaySettings(showGapToLeader: false),
      );

      expect(table.rowCount, 1);
      expect(table.rows[0].cell('bib'), '1');
      expect(table.rows[0].cell('name'), 'Петров');
      expect(table.rows[0].cell('place'), '1');
      expect(table.rows[0].cell('result_time'), '02:05');
      expect(table.rows[0].type, RowType.finished);
    });

    test('multi-lap shows per-lap times', () {
      final table = builder.build(
        results: [
          result_(
            bib: '1',
            netTime: const Duration(minutes: 2, seconds: 5),
            position: 1,
            lapTimes: [
              const Duration(minutes: 1, seconds: 0),
              const Duration(minutes: 1, seconds: 5),
            ],
          ),
        ],
        config: config_(laps: 2),
        display: const DisplaySettings(showLapSplits: true, showGapToLeader: false),
      );

      expect(table.rows[0].cell('lap1_time'), '01:00');
      expect(table.rows[0].cell('lap2_time'), '01:05');
    });

    test('on-track athlete shows lap progress', () {
      final table = builder.build(
        results: [
          result_(
            bib: '1',
            status: AthleteStatus.started,
            lapTimes: [const Duration(minutes: 1, seconds: 0)],
          ),
        ],
        config: config_(laps: 3),
        display: const DisplaySettings(showLapSplits: true, showGapToLeader: false),
      );

      expect(table.rows[0].cell('result_time'), 'Круг 2/3');
      expect(table.rows[0].type, RowType.onTrack);
    });

    test('DNF/DNS/DSQ show status labels', () {
      final table = builder.build(
        results: [
          result_(bib: '1', status: AthleteStatus.dnf),
          result_(bib: '2', status: AthleteStatus.dns),
          result_(bib: '3', status: AthleteStatus.dsq),
        ],
        config: config_(),
        display: const DisplaySettings(showGapToLeader: false),
      );

      expect(table.rows[0].cell('place'), 'DNF');
      expect(table.rows[1].cell('place'), 'DNS');
      expect(table.rows[2].cell('place'), 'DSQ');
      expect(table.rows[0].type, RowType.dnf);
      expect(table.rows[1].type, RowType.dns);
      expect(table.rows[2].type, RowType.dsq);
    });

    test('best lap is highlighted', () {
      final table = builder.build(
        results: [
          result_(
            bib: '1', position: 1,
            netTime: const Duration(minutes: 2, seconds: 0),
            lapTimes: [const Duration(minutes: 1, seconds: 5), const Duration(minutes: 0, seconds: 55)],
          ),
          result_(
            bib: '2', position: 2,
            netTime: const Duration(minutes: 2, seconds: 10),
            lapTimes: [const Duration(minutes: 1, seconds: 0), const Duration(minutes: 1, seconds: 10)],
          ),
        ],
        config: config_(laps: 2),
        display: const DisplaySettings(showLapSplits: true, showGapToLeader: false),
      );

      // Bib 2 has best lap1 (1:00 < 1:05), Bib 1 has best lap2 (0:55 < 1:10)
      expect(table.rows[1].cells['lap1_time']?.style, CellStyle.highlight);
      expect(table.rows[0].cells['lap2_time']?.style, CellStyle.highlight);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/domain/timing/time_formatter.dart';

void main() {
  group('TimeFormatter.full', () {
    test('formats zero duration', () {
      expect(TimeFormatter.full(Duration.zero), '00:00:00.000');
    });

    test('formats hours, minutes, seconds, ms', () {
      const d = Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678);
      expect(TimeFormatter.full(d), '01:23:45.678');
    });

    test('formats sub-second', () {
      const d = Duration(milliseconds: 456);
      expect(TimeFormatter.full(d), '00:00:00.456');
    });

    test('handles negative duration', () {
      const d = Duration(hours: -1, minutes: -5, seconds: -30);
      expect(TimeFormatter.full(d), startsWith('-'));
    });

    test('formats > 24h', () {
      const d = Duration(hours: 25, minutes: 10, seconds: 5, milliseconds: 99);
      expect(TimeFormatter.full(d), '25:10:05.099');
    });
  });

  group('TimeFormatter.compact', () {
    test('formats minutes and seconds', () {
      const d = Duration(minutes: 5, seconds: 30);
      expect(TimeFormatter.compact(d), '05:30');
    });

    test('includes hours when >=1h', () {
      const d = Duration(hours: 1, minutes: 5, seconds: 30);
      expect(TimeFormatter.compact(d), '1:05:30');
    });

    test('pads with zeros', () {
      const d = Duration(seconds: 3);
      expect(TimeFormatter.compact(d), '00:03');
    });
  });

  group('TimeFormatter.result', () {
    test('seconds precision', () {
      const d = Duration(minutes: 5, seconds: 30, milliseconds: 456);
      expect(TimeFormatter.result(d, precision: 'seconds'), '05:30');
    });

    test('tenths precision', () {
      const d = Duration(minutes: 5, seconds: 30, milliseconds: 456);
      expect(TimeFormatter.result(d, precision: 'tenths'), '05:30.4');
    });

    test('hundredths precision', () {
      const d = Duration(minutes: 5, seconds: 30, milliseconds: 456);
      expect(TimeFormatter.result(d, precision: 'hundredths'), '05:30.45');
    });

    test('milliseconds precision', () {
      const d = Duration(minutes: 5, seconds: 30, milliseconds: 456);
      expect(TimeFormatter.result(d, precision: 'milliseconds'), '05:30.456');
    });

    test('includes hours when >=1h', () {
      const d = Duration(hours: 1, minutes: 5, seconds: 30, milliseconds: 100);
      expect(TimeFormatter.result(d, precision: 'tenths'), '1:05:30.1');
    });
  });

  group('TimeFormatter.hms', () {
    test('formats HH:MM:SS', () {
      const d = Duration(hours: 2, minutes: 3, seconds: 4);
      expect(TimeFormatter.hms(d), '02:03:04');
    });

    test('zero duration', () {
      expect(TimeFormatter.hms(Duration.zero), '00:00:00');
    });
  });

  group('TimeFormatter.gap', () {
    test('zero gap', () {
      expect(TimeFormatter.gap(Duration.zero), '±0.0');
    });

    test('positive gap', () {
      const d = Duration(minutes: 1, seconds: 23, milliseconds: 450);
      expect(TimeFormatter.gap(d), '+1:23.4');
    });

    test('negative gap', () {
      const d = Duration(seconds: -5, milliseconds: -200);
      expect(TimeFormatter.gap(d), '-0:05.2');
    });
  });

  group('TimeFormatter.gapSeconds', () {
    test('zero', () {
      expect(TimeFormatter.gapSeconds(Duration.zero), '±0.000');
    });

    test('positive', () {
      const d = Duration(seconds: 1, milliseconds: 234);
      expect(TimeFormatter.gapSeconds(d), '+1.234');
    });
  });

  group('TimeFormatter.speed', () {
    test('null returns dash', () {
      expect(TimeFormatter.speed(null), '—');
    });

    test('zero returns dash', () {
      expect(TimeFormatter.speed(0), '—');
    });

    test('formats speed', () {
      expect(TimeFormatter.speed(12.345), '12.3 км/ч');
    });
  });

  group('TimeFormatter.pace', () {
    test('null returns dash', () {
      expect(TimeFormatter.pace(null), '—');
    });

    test('formats pace', () {
      expect(TimeFormatter.pace(4.5), '4:30 мин/км');
    });
  });

  group('TimeFormatter.clockTime', () {
    test('formats DateTime to HH:MM:SS', () {
      final dt = DateTime(2026, 3, 17, 14, 5, 30);
      expect(TimeFormatter.clockTime(dt), '14:05:30');
    });
  });

  group('TimeFormatter.clockTimeShort', () {
    test('formats DateTime to HH:MM', () {
      final dt = DateTime(2026, 3, 17, 9, 5);
      expect(TimeFormatter.clockTimeShort(dt), '09:05');
    });
  });
}

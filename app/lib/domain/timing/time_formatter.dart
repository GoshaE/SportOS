/// Единый форматтер времени для всего приложения.
///
/// Заменяет дублирующиеся `_fmtDur` / `_fmtDurMs` хелперы
/// из экранов. Чистый Dart, без зависимостей от Flutter.
///
/// ```dart
/// TimeFormatter.full(dur);    // "01:23:45.678"
/// TimeFormatter.compact(dur); // "23:45"
/// TimeFormatter.hms(dur);     // "01:23:45"
/// TimeFormatter.gap(dur);     // "+1:23.4"
/// ```
class TimeFormatter {
  const TimeFormatter._();

  // ─── Core Formats ─────────────────────────────────────────────

  /// Full race time with milliseconds: `"01:23:45.678"`
  ///
  /// Used in: Protocol, Finish screen (time marks), Judge decisions.
  static String full(Duration d) {
    final neg = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = abs.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '${neg ? '-' : ''}$h:$m:$s.$ms';
  }

  /// Compact minutes:seconds: `"23:45"`
  ///
  /// Used in: Marshal checkpoint marks, compact UI.
  static String compact(Duration d) {
    final neg = d.isNegative;
    final abs = d.abs();
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}$m:$s';
  }

  /// Hours:minutes:seconds (no ms): `"01:23:45"`
  ///
  /// Used in: Clock display, elapsed timer, marshal split times.
  static String hms(Duration d) {
    final neg = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}$h:$m:$s';
  }

  // ─── Gap / Delta Formats ──────────────────────────────────────

  /// Gap format with sign: `"+1:23.4"` or `"-0:05.2"`
  ///
  /// Used in: Gap tables, live results delta, coach screen.
  static String gap(Duration d) {
    if (d == Duration.zero) return '±0.0';
    final sign = d.isNegative ? '-' : '+';
    final abs = d.abs();
    final m = abs.inMinutes;
    final s = abs.inSeconds.remainder(60);
    final tenths = (abs.inMilliseconds.remainder(1000) ~/ 100);
    return '$sign$m:${s.toString().padLeft(2, '0')}.$tenths';
  }

  /// Gap in seconds only: `"+1.234"` or `"-0.567"`
  ///
  /// Used in: tight finish differences, precision displays.
  static String gapSeconds(Duration d) {
    if (d == Duration.zero) return '±0.000';
    final sign = d.isNegative ? '-' : '+';
    final abs = d.abs();
    final sec = abs.inSeconds;
    final ms = abs.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$sign$sec.$ms';
  }

  // ─── Speed / Pace ─────────────────────────────────────────────

  /// Speed: `"12.3 км/ч"` or `"—"` if null.
  static String speed(double? kmh) {
    if (kmh == null || kmh <= 0) return '—';
    return '${kmh.toStringAsFixed(1)} км/ч';
  }

  /// Pace: `"4:52 мин/км"` or `"—"` if null.
  static String pace(double? minKm) {
    if (minKm == null || minKm <= 0) return '—';
    final mins = minKm.floor();
    final secs = ((minKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} мин/км';
  }

  // ─── Clock Format ─────────────────────────────────────────────

  /// Time of day from DateTime: `"14:30:15"`
  ///
  /// Used in: Start list planned times, timeline.
  static String clockTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Short time of day: `"14:30"`
  static String clockTimeShort(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

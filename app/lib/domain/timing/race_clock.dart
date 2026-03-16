import 'dart:async';

/// Главные часы гонки.
///
/// Знает ZeroTime (момент GUN / firstStartTime) и clockOffset
/// (PTP-поправка). Тикает каждую секунду, предоставляя текущий elapsed.
class RaceClock {
  DateTime? _zeroTime;
  Duration _clockOffset;
  Timer? _ticker;
  final List<void Function(Duration elapsed)> _listeners = [];

  RaceClock({Duration clockOffset = Duration.zero}) : _clockOffset = clockOffset;

  // ─── Lifecycle ───────────────────────────────────────────────

  /// Запустить часы гонки.
  ///
  /// Для Mass: zeroTime = момент GUN.
  /// Для Individual: zeroTime = firstStartTime из конфигурации.
  void start(DateTime zeroTime) {
    _zeroTime = zeroTime;
    _startTicker();
  }

  /// Остановить часы.
  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Сбросить часы.
  void reset() {
    stop();
    _zeroTime = null;
  }

  void dispose() {
    stop();
    _listeners.clear();
  }

  // ─── Clock Offset ────────────────────────────────────────────

  /// Применить PTP-поправку.
  ///
  /// `offset = masterTime − localSystemTime`
  /// при записи: `correctedTime = rawSystemTime + offset`
  void applyOffset(Duration offset) {
    _clockOffset = offset;
  }

  Duration get clockOffset => _clockOffset;

  // ─── Current Time ────────────────────────────────────────────

  /// Текущее скорректированное время.
  DateTime get now => DateTime.now().add(_clockOffset);

  /// Текущий elapsed от ZeroTime.
  Duration get elapsed {
    if (_zeroTime == null) return Duration.zero;
    return now.difference(_zeroTime!);
  }

  /// Работают ли часы.
  bool get isRunning => _zeroTime != null && _ticker != null;

  /// ZeroTime (для отображения).
  DateTime? get zeroTime => _zeroTime;

  // ─── Listeners ───────────────────────────────────────────────

  /// Подписаться на тикание (каждую секунду).
  void addListener(void Function(Duration elapsed) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(Duration elapsed) listener) {
    _listeners.remove(listener);
  }

  // ─── Helpers ─────────────────────────────────────────────────

  /// Создать отсечку с текущим скорректированным временем.
  DateTime stamp() => now;

  /// Рассчитать planned start time для индивидуального старта.
  static DateTime plannedStartTime({
    required DateTime firstStart,
    required int position,
    required Duration interval,
  }) {
    return firstStart.add(interval * position);
  }

  /// Рассчитать planned start time для pursuit (Гундерсен).
  static DateTime pursuitStartTime({
    required DateTime leaderStart,
    required Duration gapFromDay1,
  }) {
    return leaderStart.add(gapFromDay1);
  }

  // ─── Internal ────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final e = elapsed;
      for (final l in _listeners) {
        l(e);
      }
    });
  }
}

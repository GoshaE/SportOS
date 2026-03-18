import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════
// GRANULAR PROVIDERS (legacy / fine-grained reactivity)
// ═══════════════════════════════════════════════════════════════════
//
// These providers expose individual services (clock, start list, marking)
// separately. For most use cases, prefer the unified [raceSessionProvider]
// from race_session.dart, which manages the full race lifecycle.
//
// Keep these if you need fine-grained reactivity for a single service
// (e.g. a widget that only needs clock ticks, not the full session).
// ═══════════════════════════════════════════════════════════════════

import 'models.dart';
import 'race_clock.dart';
import 'start_list_service.dart';
import 'marking_service.dart';
import 'elapsed_calculator.dart';
import 'gap_calculator.dart';
import 'result_calculator.dart';

// ─────────────────────────────────────────────────────────────────
// CALCULATORS (stateless singletons)
// ─────────────────────────────────────────────────────────────────

final elapsedCalculatorProvider = Provider<ElapsedCalculator>(
  (_) => const ElapsedCalculator(),
);

final gapCalculatorProvider = Provider<GapCalculator>(
  (ref) => GapCalculator(ref.read(elapsedCalculatorProvider)),
);

final resultCalculatorProvider = Provider<ResultCalculator>(
  (ref) => ResultCalculator(ref.read(elapsedCalculatorProvider)),
);

// ─────────────────────────────────────────────────────────────────
// RACE CLOCK
// ─────────────────────────────────────────────────────────────────

/// State for the race clock.
class RaceClockState {
  final Duration elapsed;
  final bool isRunning;
  final DateTime? zeroTime;

  const RaceClockState({
    this.elapsed = Duration.zero,
    this.isRunning = false,
    this.zeroTime,
  });

  RaceClockState copyWith({Duration? elapsed, bool? isRunning, DateTime? zeroTime}) {
    return RaceClockState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      zeroTime: zeroTime ?? this.zeroTime,
    );
  }
}

class RaceClockNotifier extends Notifier<RaceClockState> {
  late final RaceClock _clock;

  @override
  RaceClockState build() {
    _clock = RaceClock();
    _clock.addListener(_onTick);
    ref.onDispose(() {
      _clock.removeListener(_onTick);
      _clock.dispose();
    });
    return const RaceClockState();
  }

  void _onTick(Duration elapsed) {
    state = state.copyWith(elapsed: elapsed);
  }

  void start(DateTime zeroTime) {
    _clock.start(zeroTime);
    state = state.copyWith(isRunning: true, zeroTime: zeroTime, elapsed: _clock.elapsed);
  }

  void stop() {
    _clock.stop();
    state = state.copyWith(isRunning: false);
  }

  void applyOffset(Duration offset) {
    _clock.applyOffset(offset);
  }

  DateTime stamp() => _clock.stamp();

  RaceClock get clock => _clock;
}

@Deprecated('Use raceSessionProvider instead. Legacy provider — will be removed.')
final raceClockProvider = NotifierProvider<RaceClockNotifier, RaceClockState>(
  RaceClockNotifier.new,
);

// ─────────────────────────────────────────────────────────────────
// START LIST
// ─────────────────────────────────────────────────────────────────

@Deprecated('Use raceSessionProvider instead. Legacy provider — will be removed.')
class StartListNotifier extends Notifier<List<StartEntry>> {
  StartListService? _service;

  @override
  List<StartEntry> build() => [];

  /// Initialize the start list service with a discipline config.
  void initialize(DisciplineConfig config, {List<StartWave> waves = const []}) {
    _service = StartListService(config: config, waves: waves);
  }

  /// Build and populate start list from athlete data.
  void buildStartList(
    List<({String entryId, String bib, String name, String? category, String? waveId})> athletes, {
    Map<String, Duration>? pursuitGaps,
  }) {
    _service?.buildStartList(athletes, pursuitGaps: pursuitGaps);
    state = _service?.all ?? [];
  }

  void markStarted(String bib, {required DateTime actualTime}) {
    _service?.markStarted(bib, actualTime: actualTime);
    state = _service?.all ?? [];
  }

  void markStartedAll({required DateTime gunTime}) {
    _service?.markStartedAll(gunTime: gunTime);
    state = _service?.all ?? [];
  }

  void markDns(String bib) {
    _service?.markDns(bib);
    state = _service?.all ?? [];
  }

  void undoDns(String bib) {
    _service?.undoDns(bib);
    state = _service?.all ?? [];
  }

  void forceStart(String bib, {required DateTime actualTime}) {
    _service?.forceStart(bib, actualTime: actualTime);
    state = _service?.all ?? [];
  }

  void relayHandoff(String nextBib, DateTime handoffTime) {
    _service?.relayHandoff(nextBib, handoffTime);
    state = _service?.all ?? [];
  }

  StartEntry? get currentAthlete => _service?.currentAthlete;
  int get remaining => _service?.remaining ?? 0;
  int get startedCount => _service?.startedCount ?? 0;
  DisciplineConfig? get config => _service?.config;
  StartEntry? findByBib(String bib) => _service?.findByBib(bib);
}

@Deprecated('Use raceSessionProvider instead. Legacy provider — will be removed.')
final startListProvider = NotifierProvider<StartListNotifier, List<StartEntry>>(
  StartListNotifier.new,
);

// ─────────────────────────────────────────────────────────────────
// MARKING SERVICE
// ─────────────────────────────────────────────────────────────────

@Deprecated('Use raceSessionProvider instead. Legacy provider — will be removed.')
class MarkingNotifier extends Notifier<List<TimeMark>> {
  MarkingService? _service;

  @override
  List<TimeMark> build() => [];

  /// Initialize the marking service.
  void initialize({
    Duration minLapTime = const Duration(seconds: 20),
    int totalLaps = 1,
  }) {
    _service = MarkingService(
      minLapTime: minLapTime,
      totalLaps: totalLaps,
    );
    state = [];
  }

  TimeMark? addMark({MarkType type = MarkType.finish}) {
    final mark = _service?.addMark(type: type);
    state = _service?.marks ?? [];
    return mark;
  }

  bool assignBib(String markId, String bib, {String? entryId}) {
    final result = _service?.assignBib(markId, bib, entryId: entryId) ?? false;
    state = _service?.marks ?? [];
    return result;
  }

  void unassignBib(String markId) {
    _service?.unassignBib(markId);
    state = _service?.marks ?? [];
  }

  void swapBib(String markId, String newBib, {String? newEntryId}) {
    _service?.swapBib(markId, newBib, newEntryId: newEntryId);
    state = _service?.marks ?? [];
  }

  void correctTime(String markId, DateTime newTime, String reason) {
    _service?.correctTime(markId, newTime, reason);
    state = _service?.marks ?? [];
  }

  TimeMark? insertMark(DateTime time, {String? bib, String? entryId, String reason = ''}) {
    final mark = _service?.insertMark(time, bib: bib, entryId: entryId, reason: reason);
    state = _service?.marks ?? [];
    return mark;
  }

  void deleteMark(String markId) {
    _service?.deleteMark(markId);
    state = _service?.marks ?? [];
  }

  int resolveCurrentLap(String bib) => _service?.resolveCurrentLap(bib) ?? 1;
  bool isLastLap(String bib) => _service?.isLastLap(bib) ?? false;
  List<TimeMark> get unassigned => _service?.unassigned ?? [];
  List<TimeMark> get assigned => _service?.assigned ?? [];
  List<TimeMark> marksForBib(String bib) => _service?.marksForBib(bib) ?? [];
  int get finishedCount => _service?.finishedCount ?? 0;
  int get totalMarks => _service?.totalMarks ?? 0;
}

@Deprecated('Use raceSessionProvider instead. Legacy provider — will be removed.')
final markingProvider = NotifierProvider<MarkingNotifier, List<TimeMark>>(
  MarkingNotifier.new,
);

// ─────────────────────────────────────────────────────────────────
// COMPUTED: Results
// ─────────────────────────────────────────────────────────────────

/// Computed results provider (updates when marks or start list change).
@Deprecated('Use raceSessionProvider + ResultCalculator instead. Legacy provider — will be removed.')
final resultsProvider = Provider<List<RaceResult>>((ref) {
  final startList = ref.watch(startListProvider);
  final marks = ref.watch(markingProvider);
  final calculator = ref.read(resultCalculatorProvider);
  final startListNotifier = ref.read(startListProvider.notifier);
  final config = startListNotifier.config;

  if (config == null || startList.isEmpty) return [];

  return calculator.calculate(
    config: config,
    startList: startList,
    marks: marks,
    penalties: [], // TODO: wire from penalty provider when available
  );
});

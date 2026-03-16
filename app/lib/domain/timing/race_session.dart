import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'race_clock.dart';
import 'start_list_service.dart';
import 'marking_service.dart';
import 'elapsed_calculator.dart';
import 'gap_calculator.dart';
import 'result_calculator.dart';

// ─────────────────────────────────────────────────────────────────
// RACE SESSION
// ─────────────────────────────────────────────────────────────────

/// Единое состояние гонки.
///
/// Инициализируется **один раз** при входе в Ops Mode (TimingHub).
/// Все экраны ролей (Стартёр, Финиш, Маршал, Диктор, Тренер)
/// читают из одного экземпляра → данные синхронизированы.
///
/// ```
/// OpsTimingHub → startSession(config, athletes)
///                    ↓
///   ┌────────────────────────────────────┐
///   │          RaceSession               │
///   │  ┌─ clock (RaceClock)              │
///   │  ├─ startList (StartListService)   │
///   │  ├─ marking (MarkingService)       │
///   │  ├─ elapsed (ElapsedCalculator)    │
///   │  ├─ gap (GapCalculator)            │
///   │  └─ results (ResultCalculator)     │
///   └────────────────────────────────────┘
///              ↕        ↕        ↕
///          Стартёр   Финиш   Маршал ...
/// ```
class RaceSession {
  final DisciplineConfig config;
  final RaceClock clock;
  final StartListService startList;
  final MarkingService marking;

  // Stateless calculators
  final ElapsedCalculator elapsed;
  final GapCalculator gap;
  final ResultCalculator results;

  RaceSession({
    required this.config,
    required this.clock,
    required this.startList,
    required this.marking,
    this.elapsed = const ElapsedCalculator(),
    GapCalculator? gap,
    ResultCalculator? results,
  })  : gap = gap ?? const GapCalculator(),
        results = results ?? const ResultCalculator();

  /// Рассчитать текущие результаты.
  List<RaceResult> calculateResults() {
    return results.calculate(
      config: config,
      startList: startList.all,
      marks: marking.marks,
      penalties: [], // TODO: wire penalties
    );
  }

  /// Только стартовавшие атлеты (для Финиша / Маршала / Диктора).
  List<StartEntry> get startedAthletes =>
      startList.all.where((e) => e.status == AthleteStatus.started).toList();

  /// Есть ли атлеты в стартовом листе.
  bool get hasAthletes => startList.all.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────

/// Riverpod Notifier для управления RaceSession.
///
/// Lifecycle:
/// 1. `startSession(config, athletes)` — при входе в Ops Mode
/// 2. Экраны читают `ref.watch(raceSessionProvider)`
/// 3. Мутации через `ref.read(raceSessionProvider.notifier).действие()`
/// 4. `endSession()` — при выходе из Ops Mode
class RaceSessionNotifier extends Notifier<RaceSession?> {
  @override
  RaceSession? build() => null;

  // ─── Lifecycle ────────────────────────────────────────────────

  /// Инициализировать сессию гонки.
  ///
  /// Создаёт все сервисы, строит стартовый лист.
  /// [athletes] — список из `(entryId, bib, name, category, waveId)`.
  void startSession(
    DisciplineConfig config,
    List<({String entryId, String bib, String name, String? category, String? waveId})> athletes, {
    Map<String, Duration>? pursuitGaps,
    List<StartWave> waves = const [],
  }) {
    // Если есть активная сессия — очистить
    final old = state;
    if (old != null) {
      old.clock.dispose();
    }

    final clock = RaceClock();
    clock.start(config.firstStartTime);

    final startList = StartListService(config: config, waves: waves);
    startList.buildStartList(athletes, pursuitGaps: pursuitGaps);

    final marking = MarkingService(
      minLapTime: config.minLapTime,
      totalLaps: config.laps,
    );

    state = RaceSession(
      config: config,
      clock: clock,
      startList: startList,
      marking: marking,
    );
  }

  /// Завершить сессию.
  void endSession() {
    state?.clock.dispose();
    state = null;
  }

  // ─── StartList Actions ────────────────────────────────────────

  void markStarted(String bib, {DateTime? actualTime}) {
    state?.startList.markStarted(bib, actualTime: actualTime);
    _notify();
  }

  void markStartedAll({DateTime? gunTime}) {
    state?.startList.markStartedAll(gunTime: gunTime);
    _notify();
  }

  void markDns(String bib) {
    state?.startList.markDns(bib);
    _notify();
  }

  void undoDns(String bib) {
    state?.startList.undoDns(bib);
    _notify();
  }

  void forceStart(String bib, {DateTime? actualTime}) {
    state?.startList.forceStart(bib, actualTime: actualTime);
    _notify();
  }

  void relayHandoff(String nextBib, DateTime handoffTime) {
    state?.startList.relayHandoff(nextBib, handoffTime);
    _notify();
  }

  // ─── Athlete Management ───────────────────────────────────────

  void addAthlete({
    required String entryId,
    required String bib,
    required String name,
    String? category,
    String? waveId,
  }) {
    state?.startList.addAthlete(
      entryId: entryId,
      bib: bib,
      name: name,
      category: category,
      waveId: waveId,
    );
    _notify();
  }

  void removeAthlete(String bib) {
    state?.startList.removeAthlete(bib);
    _notify();
  }

  // ─── Marking Actions ─────────────────────────────────────────

  TimeMark? addMark({MarkType type = MarkType.finish}) {
    final mark = state?.marking.addMark(type: type);
    _notify();
    return mark;
  }

  bool assignBib(String markId, String bib, {String? entryId}) {
    final result = state?.marking.assignBib(markId, bib, entryId: entryId) ?? false;
    _notify();
    return result;
  }

  void unassignBib(String markId) {
    state?.marking.unassignBib(markId);
    _notify();
  }

  void correctTime(String markId, DateTime newTime, String reason) {
    state?.marking.correctTime(markId, newTime, reason);
    _notify();
  }

  TimeMark? insertMark(DateTime time, {String? bib, String? entryId, String reason = ''}) {
    final mark = state?.marking.insertMark(time, bib: bib, entryId: entryId, reason: reason);
    _notify();
    return mark;
  }

  void deleteMark(String markId) {
    state?.marking.deleteMark(markId);
    _notify();
  }

  // ─── Clock Actions ────────────────────────────────────────────

  void applyOffset(Duration offset) {
    state?.clock.applyOffset(offset);
  }

  DateTime stamp() => state?.clock.stamp() ?? DateTime.now();

  // ─── Internal ─────────────────────────────────────────────────

  /// Force Riverpod rebuild for all subscribers.
  ///
  /// Поскольку мы мутируем сервисы in-place (не immutable state),
  /// нужно принудительно уведомить подписчиков.
  void _notify() {
    state = state; // triggers rebuild
  }
}

// ─────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────

final raceSessionProvider = NotifierProvider<RaceSessionNotifier, RaceSession?>(
  RaceSessionNotifier.new,
);

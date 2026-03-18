import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'race_clock.dart';
import 'race_scheduler.dart';
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

  final List<Penalty> _penalties;

  /// Протокол утверждён (preliminary → official).
  bool isApproved = false;
  DateTime? approvedAt;

  RaceSession({
    required this.config,
    required this.clock,
    required this.startList,
    required this.marking,
    List<Penalty>? penalties,
    this.elapsed = const ElapsedCalculator(),
    GapCalculator? gap,
    ResultCalculator? results,
  })  : _penalties = penalties ?? [],
        gap = gap ?? const GapCalculator(),
        results = results ?? const ResultCalculator();

  /// Текущие штрафы.
  List<Penalty> get penalties => List.unmodifiable(_penalties);

  /// Добавить штраф.
  void addPenalty(Penalty penalty) => _penalties.add(penalty);

  /// Удалить штраф по ID.
  void removePenalty(String penaltyId) =>
      _penalties.removeWhere((p) => p.id == penaltyId);

  /// Рассчитать текущие результаты.
  List<RaceResult> calculateResults() {
    return results.calculate(
      config: config,
      startList: startList.all,
      marks: marking.marks,
      penalties: penalties,
    );
  }

  /// Только стартовавшие атлеты (для Финиша / Маршала / Диктора).
  List<StartEntry> get startedAthletes =>
      startList.all.where((e) => e.status == AthleteStatus.started).toList();

  /// Все «ушедшие на трассу» — started + finished + dnf + dsq.
  /// Для Финиша и Маршала: нужно видеть всех кто покинул старт.
  List<StartEntry> get onCourseAthletes =>
      startList.all.where((e) =>
          e.status == AthleteStatus.started ||
          e.status == AthleteStatus.finished ||
          e.status == AthleteStatus.dnf ||
          e.status == AthleteStatus.dsq).toList();

  /// Есть ли атлеты в стартовом листе.
  bool get hasAthletes => startList.all.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────
// RACE SESSION STATE (versioned wrapper for Riverpod)
// ─────────────────────────────────────────────────────────────────

/// Обёртка для RaceSession с версией — Riverpod сравнивает по ==,
/// поэтому мутация in-place одного объекта НЕ вызывает rebuild.
/// Version counter гарантирует что каждый _notify() создаёт «новый» state.
///
/// Делегирует все геттеры RaceSession — consumer code не меняется.
class RaceSessionState {
  final RaceSession session;
  final int version;

  const RaceSessionState(this.session, this.version);

  // ── Delegate getters ──
  DisciplineConfig get config => session.config;
  RaceClock get clock => session.clock;
  StartListService get startList => session.startList;
  MarkingService get marking => session.marking;
  ElapsedCalculator get elapsed => session.elapsed;
  GapCalculator get gap => session.gap;
  ResultCalculator get results => session.results;
  List<StartEntry> get startedAthletes => session.startedAthletes;
  List<StartEntry> get onCourseAthletes => session.onCourseAthletes;
  bool get hasAthletes => session.hasAthletes;
  bool get isApproved => session.isApproved;
  DateTime? get approvedAt => session.approvedAt;
  List<Penalty> get penalties => session.penalties;
  List<RaceResult> calculateResults() => session.calculateResults();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaceSessionState && version == other.version;

  @override
  int get hashCode => version.hashCode;
}

// ─────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────

/// Riverpod Notifier для управления RaceSession.
///
/// Lifecycle:
/// 1. `startSession(config, athletes)` — при входе в Ops Mode
/// 2. Экраны читают `ref.watch(raceSessionProvider)?.session`
/// 3. Мутации через `ref.read(raceSessionProvider.notifier).действие()`
/// 4. `endSession()` — при выходе из Ops Mode
class RaceSessionNotifier extends Notifier<RaceSessionState?> {
  int _version = 0;
  RaceScheduler? _scheduler;

  @override
  RaceSessionState? build() => null;

  /// Текущая сессия (shortcut).
  RaceSession? get _session => state?.session;

  // ─── Lifecycle ────────────────────────────────────────────────

  /// Инициализировать сессию гонки.
  void startSession(
    DisciplineConfig config,
    List<({String entryId, String bib, String name, String? category, String? waveId})> athletes, {
    Map<String, Duration>? pursuitGaps,
    List<StartWave> waves = const [],
  }) {
    // Если есть активная сессия — очистить
    final old = _session;
    if (old != null) {
      old.clock.dispose();
    }

    final clock = RaceClock();
    clock.start(config.firstStartTime);

    final startList = StartListService(config: config, waves: waves);
    startList.buildStartList(athletes, pursuitGaps: pursuitGaps);

    final marking = MarkingService(
      clock: clock,
      minLapTime: config.minLapTime,
      totalLaps: config.laps,
    );

    final session = RaceSession(
      config: config,
      clock: clock,
      startList: startList,
      marking: marking,
    );

    _version++;
    state = RaceSessionState(session, _version);

    // Start domain-level scheduler for auto-starts + cutoff
    _scheduler?.dispose();
    _scheduler = RaceScheduler(
      clock: clock,
      startList: startList,
      config: config,
      onAutoStart: (bib, actualTime) {
        session.startList.markStarted(bib, actualTime: actualTime);
        _notify();
      },
      onCutoffDnf: (bib) {
        session.startList.markDnf(bib);
        _notify();
      },
    )..start();
  }

  /// Завершить сессию.
  void endSession() {
    _scheduler?.dispose();
    _scheduler = null;
    _session?.clock.dispose();
    state = null;
  }

  // ─── StartList Actions ────────────────────────────────────────

  void markStarted(String bib, {DateTime? actualTime}) {
    final s = _session;
    if (s == null) return;
    s.startList.markStarted(bib, actualTime: actualTime ?? s.clock.stamp());
    _notify();
  }

  void markStartedAll({DateTime? gunTime}) {
    final s = _session;
    if (s == null) return;
    s.startList.markStartedAll(gunTime: gunTime ?? s.clock.stamp());
    _notify();
  }

  void markDns(String bib) {
    _session?.startList.markDns(bib);
    _notify();
  }

  void undoDns(String bib) {
    _session?.startList.undoDns(bib);
    _notify();
  }

  void forceStart(String bib, {DateTime? actualTime}) {
    final s = _session;
    if (s == null) return;
    s.startList.forceStart(bib, actualTime: actualTime ?? s.clock.stamp());
    _notify();
  }

  void relayHandoff(String nextBib, DateTime handoffTime) {
    _session?.startList.relayHandoff(nextBib, handoffTime);
    _notify();
  }

  void markDnf(String bib) {
    _session?.startList.markDnf(bib);
    _notify();
  }

  void undoDnf(String bib) {
    _session?.startList.undoDnf(bib);
    _notify();
  }

  void markDsq(String bib) {
    _session?.startList.markDsq(bib);
    _notify();
  }

  void markFinished(String bib) {
    _session?.startList.markFinished(bib);
    _notify();
  }

  // ─── Protocol Approval ─────────────────────────────────────────

  void approveResults() {
    final s = _session;
    if (s == null) return;
    s.isApproved = true;
    s.approvedAt = DateTime.now();
    _notify();
  }

  void revokeApproval() {
    final s = _session;
    if (s == null) return;
    s.isApproved = false;
    s.approvedAt = null;
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
    _session?.startList.addAthlete(
      entryId: entryId,
      bib: bib,
      name: name,
      category: category,
      waveId: waveId,
    );
    _notify();
  }

  void removeAthlete(String bib) {
    _session?.startList.removeAthlete(bib);
    _notify();
  }

  // ─── Marking Actions ─────────────────────────────────────────

  TimeMark? addMark({MarkType type = MarkType.finish, MarkOwner owner = MarkOwner.finishJudge}) {
    final mark = _session?.marking.addMark(type: type, owner: owner);
    _notify();
    return mark;
  }

  bool assignBib(String markId, String bib, {String? entryId}) {
    final s = _session;
    if (s == null) return false;
    final result = s.marking.assignBib(markId, bib, entryId: entryId);

    // Авто-финиш: если у атлета набралось достаточно финишных отсечек
    if (result) {
      final finishMarks = s.marking.officialMarksForBib(bib)
          .where((m) => m.type == MarkType.finish)
          .length;
      if (finishMarks >= s.config.laps) {
        s.startList.markFinished(bib);
      }
    }

    _notify();
    return result;
  }

  void unassignBib(String markId) {
    _session?.marking.unassignBib(markId);
    _notify();
  }

  void correctTime(String markId, DateTime newTime, String reason) {
    _session?.marking.correctTime(markId, newTime, reason);
    _notify();
  }

  TimeMark? insertMark(DateTime time, {String? bib, String? entryId, String reason = ''}) {
    final mark = _session?.marking.insertMark(time, bib: bib, entryId: entryId, reason: reason);
    _notify();
    return mark;
  }

  void deleteMark(String markId) {
    _session?.marking.deleteMark(markId);
    _notify();
  }

  // ─── Penalty Actions ───────────────────────────────────────────

  void addPenalty(Penalty penalty) {
    _session?.addPenalty(penalty);
    _notify();
  }

  void removePenalty(String penaltyId) {
    _session?.removePenalty(penaltyId);
    _notify();
  }

  // ─── Clock Actions ────────────────────────────────────────────

  void applyOffset(Duration offset) {
    _session?.clock.applyOffset(offset);
  }

  DateTime stamp() => _session?.clock.stamp() ?? DateTime.now();

  // ─── Internal ─────────────────────────────────────────────────

  /// Force Riverpod rebuild: новый version → новый RaceSessionState → rebuild.
  void _notify() {
    final s = _session;
    if (s != null) {
      _version++;
      state = RaceSessionState(s, _version);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────

final raceSessionProvider = NotifierProvider<RaceSessionNotifier, RaceSessionState?>(
  RaceSessionNotifier.new,
);


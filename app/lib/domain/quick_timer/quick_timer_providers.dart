import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quick_timer_models.dart';
import 'quick_timer_storage.dart';

// ═══════════════════════════════════════
// Текущая сессия
// ═══════════════════════════════════════

class QuickSessionNotifier extends Notifier<QuickSession?> {
  @override
  QuickSession? build() => null;

  /// Создать новую сессию.
  void createSession({
    required QuickStartMode mode,
    required int totalLaps,
    required List<({String name, String bib})> athletes,
    int intervalSeconds = 30,
    String? title,
  }) {
    final now = DateTime.now();
    state = QuickSession(
      id: 'qs-${now.millisecondsSinceEpoch}',
      date: now,
      title: title,
      mode: mode,
      totalLaps: totalLaps,
      intervalSeconds: intervalSeconds,
      athletes: athletes.asMap().entries.map((e) => QuickAthlete(
        id: 'qa-${e.key}',
        name: e.value.name,
        bib: e.value.bib,
        startOrder: e.key,
      )).toList(),
      status: QuickSessionStatus.setup,
    );
  }

  /// Масс-старт — запускает общий таймер.
  void startMass() {
    if (state == null) return;
    state = state!.copyWith(
      globalStartTime: DateTime.now(),
      status: QuickSessionStatus.running,
    );
  }

  /// Индивидуальный старт для конкретного атлета.
  void startIndividual(String athleteId) {
    if (state == null) return;
    final now = DateTime.now();
    final updated = state!.athletes.map((a) {
      if (a.id == athleteId && a.startTime == null) {
        return a.copyWith(startTime: now);
      }
      return a;
    }).toList();

    // Первый старт → записать globalStartTime
    final isFirstStart = state!.globalStartTime == null;
    final newStatus = state!.status == QuickSessionStatus.setup
        ? QuickSessionStatus.running
        : state!.status;

    state = state!.copyWith(
      athletes: updated,
      status: newStatus,
      globalStartTime: isFirstStart ? now : state!.globalStartTime,
    );
  }

  /// Авто-старт по плановому времени (для интервального режима).
  void startIndividualAt(String athleteId, DateTime at) {
    if (state == null) return;
    final updated = state!.athletes.map((a) {
      if (a.id == athleteId && a.startTime == null) {
        return a.copyWith(startTime: at);
      }
      return a;
    }).toList();
    state = state!.copyWith(athletes: updated);
  }

  /// Записать сплит/финиш для атлета (тап по плитке).
  void recordSplit(String athleteId) {
    if (state == null) return;
    final now = DateTime.now();
    final totalLaps = state!.totalLaps;

    final updated = state!.athletes.map((a) {
      if (a.id != athleteId) return a;
      if (a.isFinished(totalLaps)) return a;

      // Для ручного старта: не стартовал → ignore
      if (state!.mode == QuickStartMode.manual && a.startTime == null) return a;

      final newSplits = [...a.splits, now];
      final isNowFinished = newSplits.length >= totalLaps;
      return a.copyWith(
        splits: newSplits,
        finishTime: isNowFinished ? now : null,
      );
    }).toList();

    state = state!.copyWith(athletes: updated);

    // Авто-завершение если все финишировали
    if (state!.allFinished) {
      state = state!.copyWith(status: QuickSessionStatus.finished);
    }
  }

  /// Завершить сессию вручную.
  void finishSession() {
    if (state == null) return;
    state = state!.copyWith(status: QuickSessionStatus.finished);
  }

  /// Сохранить текущую сессию в историю.
  Future<void> saveToHistory() async {
    if (state == null) return;
    await QuickTimerStorage.saveSession(state!);
  }

  /// Загрузить сессию (из истории для просмотра).
  void loadSession(QuickSession session) => state = session;

  /// Сбросить сессию.
  void reset() => state = null;
}

final quickSessionProvider = NotifierProvider<QuickSessionNotifier, QuickSession?>(
  QuickSessionNotifier.new,
);

// ═══════════════════════════════════════
// История
// ═══════════════════════════════════════

class QuickHistoryNotifier extends Notifier<List<QuickSession>> {
  @override
  List<QuickSession> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await QuickTimerStorage.loadHistory();
  }

  Future<void> refresh() async => _load();

  Future<void> delete(String sessionId) async {
    await QuickTimerStorage.deleteSession(sessionId);
    state = state.where((s) => s.id != sessionId).toList();
  }
}

final quickHistoryProvider = NotifierProvider<QuickHistoryNotifier, List<QuickSession>>(
  QuickHistoryNotifier.new,
);

// ═══════════════════════════════════════
// Сохранённые группы
// ═══════════════════════════════════════

class SavedGroupsNotifier extends Notifier<List<SavedGroup>> {
  @override
  List<SavedGroup> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await QuickTimerStorage.loadGroups();
  }

  Future<void> save(SavedGroup group) async {
    await QuickTimerStorage.saveGroup(group);
    await _load();
  }

  Future<void> delete(String groupId) async {
    await QuickTimerStorage.deleteGroup(groupId);
    state = state.where((g) => g.id != groupId).toList();
  }
}

final savedGroupsProvider = NotifierProvider<SavedGroupsNotifier, List<SavedGroup>>(
  SavedGroupsNotifier.new,
);

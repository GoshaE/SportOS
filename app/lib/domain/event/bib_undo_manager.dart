import 'event_config.dart';

/// Снимок BIB-назначений для undo/redo.
///
/// Хранит маппинг participantId → bibValue на момент
/// **до** применения действия. При undo восстанавливаем
/// эти значения через [ParticipantsNotifier.bulkUpdate].
class BibSnapshot {
  /// Человекочитаемое описание действия.
  ///
  /// Примеры: «Авто: Скидж. 5км», «BIB 07 → Петров», «Сброс всех».
  final String label;

  /// participantId → bib (пустая строка = без номера).
  final Map<String, String> bibs;

  /// Когда создан снимок.
  final DateTime timestamp;

  const BibSnapshot({
    required this.label,
    required this.bibs,
    required this.timestamp,
  });
}

/// Менеджер undo/redo для назначения BIB-номеров.
///
/// **Использование:**
/// ```dart
/// final mgr = BibUndoManager();
///
/// // Перед каждым изменением:
/// mgr.saveSnapshot('BIB 07 → Петров', participants);
/// ref.read(participantsProvider.notifier).update(...);
///
/// // Откат:
/// final snap = mgr.undo();
/// if (snap != null) applySnapshot(snap);
/// ```
///
/// Стек ограничен [maxHistory] записями (по умолчанию 50).
/// Новое действие после undo сбрасывает redo-стек.
class BibUndoManager {
  /// Максимальное количество записей в undo-стеке.
  final int maxHistory;

  final List<BibSnapshot> _undoStack = [];
  final List<BibSnapshot> _redoStack = [];

  BibUndoManager({this.maxHistory = 50});

  // ── Публичный API ────────────────────────────────────────────

  /// Сохранить снимок **текущего** состояния BIB перед изменением.
  ///
  /// [label] — описание действия, которое **будет** выполнено.
  void saveSnapshot(String label, List<Participant> participants) {
    final bibs = {for (final p in participants) p.id: p.bib};
    _undoStack.add(BibSnapshot(
      label: label,
      bibs: bibs,
      timestamp: DateTime.now(),
    ));

    // Ограничиваем размер стека
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }

    // Новое действие после undo → redo невалиден
    _redoStack.clear();
  }

  /// Откатить последнее действие.
  ///
  /// Возвращает снимок состояния **до** этого действия.
  /// Перед вызовом нужно сохранить **текущее** состояние в redo-стек —
  /// это делается автоматически, но вызывающий код должен передать
  /// текущих участников через [currentParticipants].
  BibSnapshot? undo(List<Participant> currentParticipants) {
    if (_undoStack.isEmpty) return null;

    // Сохраняем текущее состояние в redo
    final currentBibs = {for (final p in currentParticipants) p.id: p.bib};
    final lastAction = _undoStack.removeLast();
    _redoStack.add(BibSnapshot(
      label: lastAction.label,
      bibs: currentBibs,
      timestamp: DateTime.now(),
    ));

    return lastAction;
  }

  /// Повторить отменённое действие.
  ///
  /// Возвращает снимок состояния **после** действия.
  BibSnapshot? redo(List<Participant> currentParticipants) {
    if (_redoStack.isEmpty) return null;

    // Сохраняем текущее состояние в undo
    final currentBibs = {for (final p in currentParticipants) p.id: p.bib};
    final action = _redoStack.removeLast();
    _undoStack.add(BibSnapshot(
      label: action.label,
      bibs: currentBibs,
      timestamp: DateTime.now(),
    ));

    return action;
  }

  /// Можно ли отменить?
  bool get canUndo => _undoStack.isNotEmpty;

  /// Можно ли повторить?
  bool get canRedo => _redoStack.isNotEmpty;

  /// Описание последнего действия (для tooltip).
  String? get lastUndoLabel => _undoStack.isEmpty ? null : _undoStack.last.label;

  /// Описание следующего redo-действия (для tooltip).
  String? get lastRedoLabel => _redoStack.isEmpty ? null : _redoStack.last.label;

  /// Количество записей в undo-стеке.
  int get undoCount => _undoStack.length;

  /// Количество записей в redo-стеке.
  int get redoCount => _redoStack.length;

  /// Очистить оба стека.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

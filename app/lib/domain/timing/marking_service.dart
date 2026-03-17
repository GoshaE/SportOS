import 'models.dart';

/// Сервис очереди отсечек.
///
/// Реализует паттерн «Очередь меток» (04-timing-engine.md §3):
/// 1. Судья фиксирует момент пересечения (tap → TimeMark без BIB)
/// 2. Потом назначает BIB из сетки
/// 3. Поддерживает: удаление, вставку, коррекцию, swap BIB
class MarkingService {
  final List<TimeMark> _marks = [];
  final Duration _clockOffset;
  final Duration _minLapTime;
  final int _totalLaps;
  int _nextId = 1;

  MarkingService({
    Duration clockOffset = Duration.zero,
    Duration minLapTime = const Duration(seconds: 20),
    int totalLaps = 1,
  })  : _clockOffset = clockOffset,
        _minLapTime = minLapTime,
        _totalLaps = totalLaps;

  // ─── Add Mark ────────────────────────────────────────────────

  /// Добавить отсечку (tap).
  ///
  /// Фиксирует текущее скорректированное время.
  /// BIB назначается отдельно через [assignBib].
  TimeMark addMark({MarkType type = MarkType.finish, MarkOwner owner = MarkOwner.finishJudge}) {
    final raw = DateTime.now();
    final corrected = raw.add(_clockOffset);

    final mark = TimeMark(
      id: 'mark-${_nextId++}',
      rawTime: raw,
      correctedTime: corrected,
      type: type,
      owner: owner,
    );

    _marks.add(mark);
    return mark;
  }

  // ─── Assign BIB ──────────────────────────────────────────────

  /// Назначить BIB отсечке.
  ///
  /// Автоматически определяет номер круга через [resolveCurrentLap].
  /// Возвращает false если нарушен minLapTime.
  bool assignBib(String markId, String bib, {String? entryId}) {
    final mark = _findMark(markId);
    if (mark == null) return false;

    // Проверка minLapTime
    if (!_checkMinLapTime(bib, mark.correctedTime)) {
      return false; // слишком быстро — вероятно дубль
    }

    mark.bib = bib;
    mark.entryId = entryId;
    mark.lapNumber = resolveCurrentLap(bib);

    return true;
  }

  /// Снять BIB с отсечки (вернуть на трассу).
  void unassignBib(String markId) {
    final mark = _findMark(markId);
    if (mark == null) return;

    mark.bib = null;
    mark.entryId = null;
    mark.lapNumber = null;
  }

  /// Поменять BIB на отсечке.
  void swapBib(String markId, String newBib, {String? newEntryId}) {
    final mark = _findMark(markId);
    if (mark == null) return;

    mark.bib = newBib;
    mark.entryId = newEntryId;
    mark.lapNumber = resolveCurrentLap(newBib);
  }

  // ─── Edit Mark ───────────────────────────────────────────────

  /// Ручная коррекция времени (+ обязательный reason для audit).
  void correctTime(String markId, DateTime newTime, String reason) {
    final mark = _findMark(markId);
    if (mark == null) return;

    mark.correctedTime = newTime;
    mark.correctionReason = reason;
  }

  /// Вставить метку с ручным временем (по видео и т.д.).
  TimeMark insertMark(DateTime time, {String? bib, String? entryId, String reason = '', MarkOwner owner = MarkOwner.finishJudge}) {
    final mark = TimeMark(
      id: 'mark-${_nextId++}',
      rawTime: time,
      correctedTime: time,
      type: MarkType.finish,
      source: MarkSource.manual,
      owner: owner,
      bib: bib,
      entryId: entryId,
      correctionReason: reason.isNotEmpty ? reason : null,
    );

    if (bib != null) {
      mark.lapNumber = resolveCurrentLap(bib);
    }

    // Вставить в хронологическом порядке
    final insertIndex = _marks.indexWhere((m) => m.correctedTime.isAfter(time));
    if (insertIndex == -1) {
      _marks.add(mark);
    } else {
      _marks.insert(insertIndex, mark);
    }

    return mark;
  }

  /// Удалить метку.
  void deleteMark(String markId) {
    _marks.removeWhere((m) => m.id == markId);
  }

  // ─── Lap Resolution ──────────────────────────────────────────

  /// Определить текущий круг для BIB.
  ///
  /// Считает только **официальные** отсечки (судейские) для этого BIB.
  int resolveCurrentLap(String bib) {
    final completed = _marks
        .where((m) => m.bib == bib && m.isOfficial && (m.type == MarkType.checkpoint || m.type == MarkType.finish))
        .length;

    final currentLap = completed + 1;
    if (currentLap > _totalLaps) return _totalLaps;
    return currentLap;
  }

  /// Проверить что текущий круг = последний (финиш).
  bool isLastLap(String bib) {
    return resolveCurrentLap(bib) >= _totalLaps;
  }

  // ─── Queries ─────────────────────────────────────────────────

  /// Все отсечки (отсортированные по времени).
  List<TimeMark> get marks {
    final sorted = List<TimeMark>.from(_marks);
    sorted.sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
    return sorted;
  }

  /// Отсечки конкретного владельца.
  List<TimeMark> marksBy(MarkOwner owner) {
    return _marks.where((m) => m.owner == owner).toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }

  /// Только официальные отсечки (starter + finishJudge).
  List<TimeMark> get officialMarks {
    return _marks.where((m) => m.isOfficial).toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }

  /// Официальные отсечки для BIB.
  List<TimeMark> officialMarksForBib(String bib) {
    return _marks.where((m) => m.bib == bib && m.isOfficial).toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }

  /// Неназначенные отсечки.
  List<TimeMark> get unassigned => _marks.where((m) => !m.isAssigned).toList();

  /// Неназначенные отсечки конкретного владельца.
  List<TimeMark> unassignedBy(MarkOwner owner) =>
      _marks.where((m) => !m.isAssigned && m.owner == owner).toList();

  /// Назначенные отсечки.
  List<TimeMark> get assigned => _marks.where((m) => m.isAssigned).toList();

  /// Все отсечки для BIB (всех владельцев).
  List<TimeMark> marksForBib(String bib) {
    return _marks.where((m) => m.bib == bib).toList()
      ..sort((a, b) => a.correctedTime.compareTo(b.correctedTime));
  }

  /// Количество финишировавших (только официальные метки).
  int get finishedCount {
    final finished = <String>{};
    for (final m in _marks) {
      if (m.bib != null && m.isOfficial && m.lapNumber == _totalLaps) {
        finished.add(m.bib!);
      }
    }
    return finished.length;
  }

  /// Общее количество отсечек.
  int get totalMarks => _marks.length;

  // ─── Internal ────────────────────────────────────────────────

  TimeMark? _findMark(String id) {
    return _marks.where((m) => m.id == id).firstOrNull;
  }

  /// Проверка минимального времени круга.
  bool _checkMinLapTime(String bib, DateTime markTime) {
    final prevMarks = marksForBib(bib);
    if (prevMarks.isEmpty) return true;

    final lastMark = prevMarks.last;
    final diff = markTime.difference(lastMark.correctedTime);
    return diff >= _minLapTime;
  }
}

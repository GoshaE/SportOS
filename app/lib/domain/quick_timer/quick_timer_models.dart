import 'package:flutter/foundation.dart';

/// Режим старта быстрой сессии.
enum QuickStartMode { mass, individual }

/// Статус сессии.
enum QuickSessionStatus { setup, running, finished }

/// Спортсмен в быстрой сессии.
@immutable
class QuickAthlete {
  final String id;
  final String name;
  final String bib;
  final List<DateTime> splits;     // timestamps каждого сплита (круга)
  final DateTime? startTime;       // индивидуальный старт (для разделки)
  final DateTime? finishTime;

  const QuickAthlete({
    required this.id,
    required this.name,
    required this.bib,
    this.splits = const [],
    this.startTime,
    this.finishTime,
  });

  /// Время начала (глобальный масс-старт передаётся извне).
  Duration elapsed(DateTime from) {
    if (finishTime == null) return Duration.zero;
    final start = startTime ?? from;
    return finishTime!.difference(start);
  }

  /// Сплит-длительности (между последовательными timestamps).
  List<Duration> lapDurations(DateTime globalStart) {
    final start = startTime ?? globalStart;
    final result = <Duration>[];
    DateTime prev = start;
    for (final s in splits) {
      result.add(s.difference(prev));
      prev = s;
    }
    return result;
  }

  /// Кол-во пройденных кругов.
  int get completedLaps => splits.length;

  /// Полностью ли финишировал (все круги пройдены).
  bool isFinished(int totalLaps) => completedLaps >= totalLaps;

  /// Копия с обновлениями.
  QuickAthlete copyWith({
    String? name,
    String? bib,
    List<DateTime>? splits,
    DateTime? startTime,
    DateTime? finishTime,
  }) => QuickAthlete(
    id: id,
    name: name ?? this.name,
    bib: bib ?? this.bib,
    splits: splits ?? this.splits,
    startTime: startTime ?? this.startTime,
    finishTime: finishTime ?? this.finishTime,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bib': bib,
    'splits': splits.map((s) => s.toIso8601String()).toList(),
    'startTime': startTime?.toIso8601String(),
    'finishTime': finishTime?.toIso8601String(),
  };

  factory QuickAthlete.fromJson(Map<String, dynamic> j) => QuickAthlete(
    id: j['id'] as String,
    name: j['name'] as String,
    bib: j['bib'] as String,
    splits: (j['splits'] as List).map((s) => DateTime.parse(s as String)).toList(),
    startTime: j['startTime'] != null ? DateTime.parse(j['startTime'] as String) : null,
    finishTime: j['finishTime'] != null ? DateTime.parse(j['finishTime'] as String) : null,
  );
}

/// Быстрая сессия хронометража.
@immutable
class QuickSession {
  final String id;
  final DateTime date;
  final String? title;
  final QuickStartMode mode;
  final int totalLaps;
  final List<QuickAthlete> athletes;
  final DateTime? globalStartTime;  // для масс-старта
  final QuickSessionStatus status;

  const QuickSession({
    required this.id,
    required this.date,
    this.title,
    required this.mode,
    this.totalLaps = 1,
    this.athletes = const [],
    this.globalStartTime,
    this.status = QuickSessionStatus.setup,
  });

  /// Ефективное время старта атлета.
  DateTime effectiveStart(QuickAthlete a) => a.startTime ?? globalStartTime ?? date;

  /// Кол-во финишировавших.
  int get finishedCount => athletes.where((a) => a.isFinished(totalLaps)).length;

  /// Все ли финишировали.
  bool get allFinished => athletes.every((a) => a.isFinished(totalLaps));

  QuickSession copyWith({
    String? title,
    QuickStartMode? mode,
    int? totalLaps,
    List<QuickAthlete>? athletes,
    DateTime? globalStartTime,
    QuickSessionStatus? status,
  }) => QuickSession(
    id: id,
    date: date,
    title: title ?? this.title,
    mode: mode ?? this.mode,
    totalLaps: totalLaps ?? this.totalLaps,
    athletes: athletes ?? this.athletes,
    globalStartTime: globalStartTime ?? this.globalStartTime,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'mode': mode.name,
    'totalLaps': totalLaps,
    'athletes': athletes.map((a) => a.toJson()).toList(),
    'globalStartTime': globalStartTime?.toIso8601String(),
    'status': status.name,
  };

  factory QuickSession.fromJson(Map<String, dynamic> j) => QuickSession(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    title: j['title'] as String?,
    mode: QuickStartMode.values.byName(j['mode'] as String),
    totalLaps: j['totalLaps'] as int? ?? 1,
    athletes: (j['athletes'] as List).map((a) => QuickAthlete.fromJson(a as Map<String, dynamic>)).toList(),
    globalStartTime: j['globalStartTime'] != null ? DateTime.parse(j['globalStartTime'] as String) : null,
    status: QuickSessionStatus.values.byName(j['status'] as String? ?? 'finished'),
  );
}

/// Сохранённая группа спортсменов (для быстрого ввода).
@immutable
class SavedGroup {
  final String id;
  final String name;
  final List<SavedGroupMember> members;

  const SavedGroup({required this.id, required this.name, this.members = const []});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory SavedGroup.fromJson(Map<String, dynamic> j) => SavedGroup(
    id: j['id'] as String,
    name: j['name'] as String,
    members: (j['members'] as List).map((m) => SavedGroupMember.fromJson(m as Map<String, dynamic>)).toList(),
  );
}

@immutable
class SavedGroupMember {
  final String name;
  final String defaultBib;

  const SavedGroupMember({required this.name, required this.defaultBib});

  Map<String, dynamic> toJson() => {'name': name, 'defaultBib': defaultBib};

  factory SavedGroupMember.fromJson(Map<String, dynamic> j) => SavedGroupMember(
    name: j['name'] as String,
    defaultBib: j['defaultBib'] as String,
  );
}

// Timing Engine — Domain Models
//
// Все модели данных для единого движка хронометража SportOS.
// Чистый Dart, без зависимостей от Flutter.

import '../event/event_config.dart';

// ─────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────

/// Тип старта дисциплины.
///
/// - [individual] — раздельный (с интервалом)
/// - [mass] — масс-старт (GUN)
/// - [wave] — волнами (группы стартуют с интервалом)
/// - [pursuit] — преследование / Гундерсен (интервал = отставание Day 1)
/// - [relay] — эстафета (старт по передаче этапа)
enum StartType { individual, mass, wave, pursuit, relay }

/// Тип отсечки.
enum MarkType { start, checkpoint, finish, relayHandoff }

/// Источник отсечки (как была получена).
enum MarkSource { tap, scanner, manual, camera }

/// Владелец отсечки (кто её создал).
///
/// Определяет видимость и официальный статус метки.
/// Только [starter] и [finishJudge] влияют на результаты.
enum MarkOwner {
  /// Стартёр — официальный старт.
  starter,
  /// Судья финиша — официальный финиш / круговой проход.
  finishJudge,
  /// Маршал — промежуточная отсечка на трассе (КП). Информационно.
  marshal,
  /// Тренер — личная отсечка, не влияет на результаты.
  coach,
}

/// Статус атлета на гонке.
enum AthleteStatus { waiting, current, started, finished, dns, dnf, dsq }

// ─────────────────────────────────────────────────────────────────
// DISCIPLINE CONFIG
// ─────────────────────────────────────────────────────────────────

/// Конфигурация дисциплины, задаётся организатором.
///
/// В будущем будет приходить из ConfigEngine; пока создаётся вручную.
class DisciplineConfig {
  final String id;
  final String name;
  final double distanceKm;
  final StartType startType;
  final Duration interval;
  final DateTime firstStartTime;
  final int laps;
  final Duration minLapTime;
  final Duration? cutoffTime;
  final String tieBreakMode; // 'shared' | 'start_order'
  final Duration bufferBetweenWaves;

  /// Ручной старт — стартёр подтверждает «УШЁЛ» для каждого.
  /// Если false (по умолчанию) — атлеты уходят автоматически
  /// по наступлению plannedStartTime.
  final bool manualStart;

  // ── Config Engine fields ──

  /// Привязка к трассе мероприятия.
  final String? courseId;

  /// Привязка к дню (для multi-day мероприятий).
  final int? dayNumber;

  /// Максимальное кол-во участников (null = без лимита).
  final int? maxParticipants;

  /// Настройки отображения результатов для этой дисциплины.
  final DisplaySettings displaySettings;

  /// Активные категории (М, Ж, Юн, M35...).
  final List<String> categories;

  /// Цена регистрации (₽).
  final int? priceRub;

  /// Длина круга в метрах (для точного расчёта: lapLengthM × laps / 1000 = distanceKm).
  final int? lapLengthM;

  const DisciplineConfig({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.startType,
    this.interval = const Duration(seconds: 30),
    required this.firstStartTime,
    this.laps = 1,
    this.minLapTime = const Duration(seconds: 20),
    this.cutoffTime,
    this.tieBreakMode = 'shared',
    this.bufferBetweenWaves = Duration.zero,
    this.manualStart = false,
    this.courseId,
    this.dayNumber,
    this.maxParticipants,
    this.displaySettings = const DisplaySettings(),
    this.categories = const [],
    this.priceRub,
    this.lapLengthM,
  });

  /// Точная общая дистанция (км) = lapLengthM × laps / 1000.
  double get totalDistanceKm {
    if (lapLengthM != null) return lapLengthM! * laps / 1000.0;
    return distanceKm;
  }

  /// Отображаемое название: «Скиджоринг 6.000 км».
  String get displayName =>
      '$name ${totalDistanceKm.toStringAsFixed(3)} км';

  DisciplineConfig copyWith({
    String? id,
    String? name,
    double? distanceKm,
    StartType? startType,
    Duration? interval,
    DateTime? firstStartTime,
    int? laps,
    Duration? minLapTime,
    Duration? cutoffTime,
    String? tieBreakMode,
    Duration? bufferBetweenWaves,
    bool? manualStart,
    String? courseId,
    int? dayNumber,
    int? maxParticipants,
    DisplaySettings? displaySettings,
    List<String>? categories,
    int? priceRub,
    int? lapLengthM,
  }) {
    return DisciplineConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      startType: startType ?? this.startType,
      interval: interval ?? this.interval,
      firstStartTime: firstStartTime ?? this.firstStartTime,
      laps: laps ?? this.laps,
      minLapTime: minLapTime ?? this.minLapTime,
      cutoffTime: cutoffTime ?? this.cutoffTime,
      tieBreakMode: tieBreakMode ?? this.tieBreakMode,
      bufferBetweenWaves: bufferBetweenWaves ?? this.bufferBetweenWaves,
      manualStart: manualStart ?? this.manualStart,
      courseId: courseId ?? this.courseId,
      dayNumber: dayNumber ?? this.dayNumber,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      displaySettings: displaySettings ?? this.displaySettings,
      categories: categories ?? this.categories,
      priceRub: priceRub ?? this.priceRub,
      lapLengthM: lapLengthM ?? this.lapLengthM,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// START WAVE
// ─────────────────────────────────────────────────────────────────

/// Волна старта (для wave-режима).
class StartWave {
  final String id;
  final String name;
  final List<String> categoryIds;
  final DateTime plannedStartTime;
  final Duration buffer;

  const StartWave({
    required this.id,
    required this.name,
    this.categoryIds = const [],
    required this.plannedStartTime,
    this.buffer = Duration.zero,
  });
}

// ─────────────────────────────────────────────────────────────────
// START ENTRY
// ─────────────────────────────────────────────────────────────────

/// Позиция атлета в стартовом листе.
class StartEntry {
  final String entryId;
  final String bib;
  final String name;
  final String? categoryName;
  final String? waveId;
  final int startPosition;
  DateTime plannedStartTime;
  DateTime? actualStartTime;
  AthleteStatus status;

  /// Pursuit gaps (из Day 1).
  Duration? pursuitGap;

  StartEntry({
    required this.entryId,
    required this.bib,
    required this.name,
    this.categoryName,
    this.waveId,
    required this.startPosition,
    required this.plannedStartTime,
    this.actualStartTime,
    this.status = AthleteStatus.waiting,
    this.pursuitGap,
  });

  /// Эффективное время старта: actualStartTime ?? plannedStartTime.
  DateTime get effectiveStartTime => actualStartTime ?? plannedStartTime;

  StartEntry copyWith({
    String? entryId,
    String? bib,
    String? name,
    String? categoryName,
    String? waveId,
    int? startPosition,
    DateTime? plannedStartTime,
    DateTime? actualStartTime,
    AthleteStatus? status,
    Duration? pursuitGap,
  }) {
    return StartEntry(
      entryId: entryId ?? this.entryId,
      bib: bib ?? this.bib,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      waveId: waveId ?? this.waveId,
      startPosition: startPosition ?? this.startPosition,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      status: status ?? this.status,
      pursuitGap: pursuitGap ?? this.pursuitGap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TIME MARK
// ─────────────────────────────────────────────────────────────────

/// Временная отсечка — основная единица хронометража.
///
/// При создании `entryId` и `bib` могут быть null (отсечка без BIB,
/// ожидает назначения — паттерн «очередь меток»).
class TimeMark {
  final String id;
  final DateTime rawTime;
  DateTime correctedTime;
  final MarkType type;
  final MarkSource source;
  final MarkOwner owner;
  final String deviceId;
  final String? stationName;
  String? entryId;
  String? bib;
  int? lapNumber;
  String? checkpointId;
  String? correctionReason;

  TimeMark({
    required this.id,
    required this.rawTime,
    DateTime? correctedTime,
    required this.type,
    this.source = MarkSource.tap,
    this.owner = MarkOwner.finishJudge,
    this.deviceId = 'local',
    this.stationName,
    this.entryId,
    this.bib,
    this.lapNumber,
    this.checkpointId,
    this.correctionReason,
  }) : correctedTime = correctedTime ?? rawTime;

  /// Является ли отсечка назначенной (имеет BIB).
  bool get isAssigned => bib != null;

  /// Является ли отсечка официальной (влияет на результаты).
  bool get isOfficial => owner == MarkOwner.starter || owner == MarkOwner.finishJudge;

  TimeMark copyWith({
    String? id,
    DateTime? rawTime,
    DateTime? correctedTime,
    MarkType? type,
    MarkSource? source,
    MarkOwner? owner,
    String? deviceId,
    String? stationName,
    String? entryId,
    String? bib,
    int? lapNumber,
    String? checkpointId,
    String? correctionReason,
  }) {
    return TimeMark(
      id: id ?? this.id,
      rawTime: rawTime ?? this.rawTime,
      correctedTime: correctedTime ?? this.correctedTime,
      type: type ?? this.type,
      source: source ?? this.source,
      owner: owner ?? this.owner,
      deviceId: deviceId ?? this.deviceId,
      stationName: stationName ?? this.stationName,
      entryId: entryId ?? this.entryId,
      bib: bib ?? this.bib,
      lapNumber: lapNumber ?? this.lapNumber,
      checkpointId: checkpointId ?? this.checkpointId,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PENALTY
// ─────────────────────────────────────────────────────────────────

/// Штраф атлета.
class Penalty {
  final String id;
  final String entryId;
  final Duration timePenalty;
  final String reason;
  final String? violationCode;
  final bool isActive;

  const Penalty({
    required this.id,
    required this.entryId,
    required this.timePenalty,
    required this.reason,
    this.violationCode,
    this.isActive = true,
  });
}

// ─────────────────────────────────────────────────────────────────
// RACE RESULT
// ─────────────────────────────────────────────────────────────────

/// Рассчитанный результат атлета.
class RaceResult {
  final String entryId;
  final String bib;
  final String name;
  final Duration grossTime;
  final Duration netTime;
  final Duration penaltyTime;
  final Duration resultTime;
  final double? speedKmh;
  final List<Duration> splitTimes;
  final List<Duration> lapTimes;
  int position;
  final Duration? gapToLeader;
  final Duration? gapToPrev;
  final AthleteStatus status;

  RaceResult({
    required this.entryId,
    required this.bib,
    required this.name,
    required this.grossTime,
    required this.netTime,
    required this.penaltyTime,
    required this.resultTime,
    this.speedKmh,
    this.splitTimes = const [],
    this.lapTimes = const [],
    this.position = 0,
    this.gapToLeader,
    this.gapToPrev,
    this.status = AthleteStatus.finished,
  });
}

// ─────────────────────────────────────────────────────────────────
// GAP ROW (for coach view)
// ─────────────────────────────────────────────────────────────────

/// Строка таблицы разрывов для тренерского экрана.
class GapRow {
  final String bib;
  final String name;
  final int lap;
  final Duration elapsed;
  final Duration? gapToLeader;
  final Duration? gapToPrev;
  /// '▲' gaining, '▼' losing, '=' stable, '' unknown
  final String trend;

  const GapRow({
    required this.bib,
    required this.name,
    required this.lap,
    required this.elapsed,
    this.gapToLeader,
    this.gapToPrev,
    this.trend = '',
  });
}

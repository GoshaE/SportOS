// Config Engine — Domain Models
//
// Модели данных для конфигурации мероприятия.
// Чистый Dart, без зависимостей от Flutter.
//
// Принцип наследования:
//   SportType (дефолт) → Event (override) → Discipline (override)

// ─────────────────────────────────────────────────────────────────
// EVENT CONFIG
// ─────────────────────────────────────────────────────────────────

/// Статус мероприятия.
enum EventStatus { draft, registrationOpen, registrationClosed, inProgress, completed, archived }

/// Режим итогового зачёта для многодневных мероприятий.
enum ScoringMode {
  /// Результаты каждого дня отдельно.
  perDay,
  /// Суммарное время за все дни.
  cumulative,
  /// Гундерсен — стартовый интервал = отставание Day 1.
  pursuit,
}

/// Политика допуска при DNF/DSQ в предыдущем дне.
enum DayPolicy {
  /// Не допускается к следующему дню.
  strict,
  /// Допускается последним с максимальным временем.
  penalized,
  /// Допускается с фиксированным интервалом.
  open,
}

/// Политика BIB между днями многодневного мероприятия.
enum BibDayPolicy {
  /// Те же номера, новый стартовый порядок.
  keep,
  /// Новая жеребьёвка, новые номера.
  redraw,
  /// Те же номера, порядок по отставанию (Гундерсен).
  pursuit,
}

/// Конфигурация мероприятия — верхний уровень.
///
/// Содержит общие настройки: название, даты, место, многодневность,
/// привязанные трассы и дисциплины.
class EventConfig {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final EventStatus status;

  // ── Многодневность ──
  final bool isMultiDay;
  final List<RaceDay> days;
  final ScoringMode scoringMode;
  final DayPolicy dnfDayPolicy;
  final DayPolicy dsqDayPolicy;
  final BibDayPolicy bibDayPolicy;
  final bool allowDogSwapBetweenDays;

  // ── Трассы ──
  final List<Course> courses;

  const EventConfig({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.location,
    this.status = EventStatus.draft,
    this.isMultiDay = false,
    this.days = const [],
    this.scoringMode = ScoringMode.cumulative,
    this.dnfDayPolicy = DayPolicy.penalized,
    this.dsqDayPolicy = DayPolicy.strict,
    this.bibDayPolicy = BibDayPolicy.keep,
    this.allowDogSwapBetweenDays = false,
    this.courses = const [],
  });

  EventConfig copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    EventStatus? status,
    bool? isMultiDay,
    List<RaceDay>? days,
    ScoringMode? scoringMode,
    DayPolicy? dnfDayPolicy,
    DayPolicy? dsqDayPolicy,
    BibDayPolicy? bibDayPolicy,
    bool? allowDogSwapBetweenDays,
    List<Course>? courses,
  }) {
    return EventConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      days: days ?? this.days,
      scoringMode: scoringMode ?? this.scoringMode,
      dnfDayPolicy: dnfDayPolicy ?? this.dnfDayPolicy,
      dsqDayPolicy: dsqDayPolicy ?? this.dsqDayPolicy,
      bibDayPolicy: bibDayPolicy ?? this.bibDayPolicy,
      allowDogSwapBetweenDays: allowDogSwapBetweenDays ?? this.allowDogSwapBetweenDays,
      courses: courses ?? this.courses,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// START ORDER
// ─────────────────────────────────────────────────────────────────

/// Стартовый порядок дня.
enum StartOrder {
  /// Жеребьёвка (новый случайный порядок).
  draw,
  /// Такой же порядок, как предыдущий день.
  same,
  /// Обратный порядок (лидер стартует последним).
  reverse,
  /// Гундерсен — стартовый интервал = отставание предыдущего дня.
  pursuit,
}

// ─────────────────────────────────────────────────────────────────
// RACE DAY
// ─────────────────────────────────────────────────────────────────

/// День соревнований (для многодневных мероприятий).
///
/// Каждый день может иметь свой набор дисциплин, стартовый порядок,
/// время старта и настройку ветконтроля.
class RaceDay {
  final int dayNumber;
  final DateTime date;

  /// Какие дисциплины проводятся в этот день (из общего пула).
  final List<String> disciplineIds;

  /// Стартовый порядок этого дня.
  final StartOrder startOrder;

  /// Время первого старта.
  final TimeOfDay startTime;

  /// Проводить ли ветконтроль в этот день.
  final bool vetCheck;

  const RaceDay({
    required this.dayNumber,
    required this.date,
    this.disciplineIds = const [],
    this.startOrder = StartOrder.draw,
    this.startTime = const TimeOfDay(hour: 10, minute: 0),
    this.vetCheck = true,
  });

  /// Создать новый день, скопировав настройки из другого дня (шаблон).
  factory RaceDay.copyFromDay(RaceDay template, {required int dayNumber, required DateTime date}) {
    return RaceDay(
      dayNumber: dayNumber,
      date: date,
      disciplineIds: List.of(template.disciplineIds),
      startOrder: dayNumber > 1 ? StartOrder.reverse : StartOrder.draw,
      startTime: template.startTime,
      vetCheck: template.vetCheck,
    );
  }

  RaceDay copyWith({
    int? dayNumber,
    DateTime? date,
    List<String>? disciplineIds,
    StartOrder? startOrder,
    TimeOfDay? startTime,
    bool? vetCheck,
  }) {
    return RaceDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      disciplineIds: disciplineIds ?? this.disciplineIds,
      startOrder: startOrder ?? this.startOrder,
      startTime: startTime ?? this.startTime,
      vetCheck: vetCheck ?? this.vetCheck,
    );
  }
}

/// Lightweight TimeOfDay (no Flutter dependency).
class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});

  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is TimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => hour * 60 + minute;
}

// ─────────────────────────────────────────────────────────────────
// COURSE
// ─────────────────────────────────────────────────────────────────

/// Трасса мероприятия.
///
/// Трассы определяются на уровне мероприятия и разделяются между
/// дисциплинами. Одна трасса может использоваться несколькими дисциплинами.
class Course {
  final String id;
  final String name;
  final double distanceKm;
  final String? gpxPath;
  final int? elevationGainM;
  final String? description;

  /// Именованные чекпоинты (КП) на трассе.
  /// Привязаны к трассе, а не к дисциплине (L2 из аудита).
  final List<CheckpointDef> checkpoints;

  const Course({
    required this.id,
    required this.name,
    required this.distanceKm,
    this.gpxPath,
    this.elevationGainM,
    this.description,
    this.checkpoints = const [],
  });

  Course copyWith({
    String? id,
    String? name,
    double? distanceKm,
    String? gpxPath,
    int? elevationGainM,
    String? description,
    List<CheckpointDef>? checkpoints,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      gpxPath: gpxPath ?? this.gpxPath,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      description: description ?? this.description,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CHECKPOINT DEF
// ─────────────────────────────────────────────────────────────────

/// Именованный чекпоинт (контрольная точка) на трассе.
///
/// Маршал, стоящий на КП, ставит отсечку с привязкой к этому checkpointId.
/// В протоколе отображается как именованная колонка: «КП1 (2км)».
class CheckpointDef {
  final String id;
  final String name;
  final double? distanceKm;
  final int order;

  const CheckpointDef({
    required this.id,
    required this.name,
    this.distanceKm,
    required this.order,
  });

  CheckpointDef copyWith({
    String? id,
    String? name,
    double? distanceKm,
    int? order,
  }) {
    return CheckpointDef(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      order: order ?? this.order,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DISPLAY SETTINGS
// ─────────────────────────────────────────────────────────────────

/// Настройки отображения результатов.
///
/// Применяются per-discipline с наследованием от event (L5 из аудита).
/// Организатор включает/выключает колонки и метрики в протоколе.
class DisplaySettings {
  /// Показывать сплиты по кругам (Кр.1, Кр.2...).
  final bool showLapSplits;

  /// Показывать маршальские чекпоинты (КП1, КП2...).
  final bool showCheckpoints;

  /// Показывать среднюю скорость (км/ч).
  final bool showSpeed;

  /// Показывать темп (мин/км).
  final bool showPace;

  /// Показывать отставание от лидера.
  final bool showGapToLeader;

  /// Показывать разрыв с предыдущим.
  final bool showGapToPrev;

  /// Показывать клички собак (ездовой спорт).
  final bool showDogNames;

  /// Показывать клуб/город.
  final bool showClub;

  const DisplaySettings({
    this.showLapSplits = true,
    this.showCheckpoints = true,
    this.showSpeed = false,
    this.showPace = false,
    this.showGapToLeader = true,
    this.showGapToPrev = false,
    this.showDogNames = true,
    this.showClub = false,
  });

  /// Дефолтные настройки.
  static const defaults = DisplaySettings();

  DisplaySettings copyWith({
    bool? showLapSplits,
    bool? showCheckpoints,
    bool? showSpeed,
    bool? showPace,
    bool? showGapToLeader,
    bool? showGapToPrev,
    bool? showDogNames,
    bool? showClub,
  }) {
    return DisplaySettings(
      showLapSplits: showLapSplits ?? this.showLapSplits,
      showCheckpoints: showCheckpoints ?? this.showCheckpoints,
      showSpeed: showSpeed ?? this.showSpeed,
      showPace: showPace ?? this.showPace,
      showGapToLeader: showGapToLeader ?? this.showGapToLeader,
      showGapToPrev: showGapToPrev ?? this.showGapToPrev,
      showDogNames: showDogNames ?? this.showDogNames,
      showClub: showClub ?? this.showClub,
    );
  }
}

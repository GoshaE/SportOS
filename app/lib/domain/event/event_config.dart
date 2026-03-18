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

/// Метод расчёта возраста участника.
///
/// Определяет, как система считает возраст для распределения
/// по категориям при подаче заявки.
enum AgeCalculation {
  /// По году: возраст = год гонки − год рождения.
  /// Стандарт FIS, IFSS, большинства федераций.
  byYear,

  /// Точный возраст на дату гонки.
  exactDate,
}

/// Пол для категории.
enum CategoryGender { any, male, female }

/// Категория соревнований (М, Ж, Юниоры, Ветераны, M35…).
///
/// Определяется на уровне мероприятия — чисто классификация
/// участников по полу и возрасту. Универсальна для любого спорта
/// (лыжи, бег, велосипед, ездовой спорт и т.д.).
///
/// Дисциплины ссылаются на допущенные категории по id.
class RaceCategory {
  final String id;
  final String name;
  final String shortName;
  final CategoryGender gender;
  final int? ageMin;
  final int? ageMax;
  final int sortOrder;

  const RaceCategory({
    required this.id,
    required this.name,
    required this.shortName,
    this.gender = CategoryGender.any,
    this.ageMin,
    this.ageMax,
    this.sortOrder = 0,
  });

  String get genderLabel => switch (gender) {
    CategoryGender.any => 'Любой',
    CategoryGender.male => 'Мужской',
    CategoryGender.female => 'Женский',
  };

  String get ageLabel {
    if (ageMin == null && ageMax == null) return 'Любой возраст';
    if (ageMin != null && ageMax != null) return '$ageMin–$ageMax лет';
    if (ageMin != null) return 'от $ageMin лет';
    return 'до $ageMax лет';
  }

  /// Краткое описание для карточки.
  String get subtitle {
    final parts = <String>[];
    parts.add(genderLabel);
    if (ageMin != null || ageMax != null) parts.add(ageLabel);
    return parts.join('  ·  ');
  }

  RaceCategory copyWith({
    String? id,
    String? name,
    String? shortName,
    CategoryGender? gender,
    int? ageMin,
    int? ageMax,
    int? sortOrder,
  }) {
    return RaceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      gender: gender ?? this.gender,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Пул стартовых номеров (BIB).
class BibPool {
  final String id;
  final String label;
  final int rangeStart;
  final int rangeEnd;
  /// Привязка к дисциплине (null = общий пул).
  final String? disciplineId;

  const BibPool({
    required this.id,
    required this.label,
    required this.rangeStart,
    required this.rangeEnd,
    this.disciplineId,
  });

  int get capacity => rangeEnd - rangeStart + 1;

  BibPool copyWith({
    String? id,
    String? label,
    int? rangeStart,
    int? rangeEnd,
    String? disciplineId,
  }) {
    return BibPool(
      id: id ?? this.id,
      label: label ?? this.label,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      disciplineId: disciplineId ?? this.disciplineId,
    );
  }
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
  final String? description;
  final String? contactInfo;
  final String? logoUrl;
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

  // ── BIB ──
  final List<BibPool> bibPools;

  // ── Категории ──
  final List<RaceCategory> raceCategories;
  final AgeCalculation ageCalculation;

  // ── Регистрация ──
  final RegistrationConfig registrationConfig;

  // ── Цены ──
  final PricingConfig pricingConfig;

  // ── Хронометраж ──
  final TimingConfig timingConfig;

  // ── Жеребьёвка ──
  final DrawConfig drawConfig;

  // ── Библиотека штрафов ──
  final List<PenaltyTemplate> penaltyTemplates;

  // ── Предстартовый чек-лист ──
  final List<ChecklistItemConfig> checklistItems;

  const EventConfig({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.location,
    this.description,
    this.contactInfo,
    this.logoUrl,
    this.status = EventStatus.draft,
    this.isMultiDay = false,
    this.days = const [],
    this.scoringMode = ScoringMode.cumulative,
    this.dnfDayPolicy = DayPolicy.penalized,
    this.dsqDayPolicy = DayPolicy.strict,
    this.bibDayPolicy = BibDayPolicy.keep,
    this.allowDogSwapBetweenDays = false,
    this.courses = const [],
    this.bibPools = const [],
    this.raceCategories = const [],
    this.ageCalculation = AgeCalculation.byYear,
    this.registrationConfig = const RegistrationConfig(),
    this.pricingConfig = const PricingConfig(),
    this.timingConfig = const TimingConfig(),
    this.drawConfig = const DrawConfig(),
    this.penaltyTemplates = defaultPenaltyTemplates,
    this.checklistItems = defaultChecklistItems,
  });

  EventConfig copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? description,
    String? contactInfo,
    String? logoUrl,
    EventStatus? status,
    bool? isMultiDay,
    List<RaceDay>? days,
    ScoringMode? scoringMode,
    DayPolicy? dnfDayPolicy,
    DayPolicy? dsqDayPolicy,
    BibDayPolicy? bibDayPolicy,
    bool? allowDogSwapBetweenDays,
    List<Course>? courses,
    List<BibPool>? bibPools,
    List<RaceCategory>? raceCategories,
    AgeCalculation? ageCalculation,
    RegistrationConfig? registrationConfig,
    PricingConfig? pricingConfig,
    TimingConfig? timingConfig,
    DrawConfig? drawConfig,
    List<PenaltyTemplate>? penaltyTemplates,
    List<ChecklistItemConfig>? checklistItems,
  }) {
    return EventConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      description: description ?? this.description,
      contactInfo: contactInfo ?? this.contactInfo,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      days: days ?? this.days,
      scoringMode: scoringMode ?? this.scoringMode,
      dnfDayPolicy: dnfDayPolicy ?? this.dnfDayPolicy,
      dsqDayPolicy: dsqDayPolicy ?? this.dsqDayPolicy,
      bibDayPolicy: bibDayPolicy ?? this.bibDayPolicy,
      allowDogSwapBetweenDays: allowDogSwapBetweenDays ?? this.allowDogSwapBetweenDays,
      courses: courses ?? this.courses,
      bibPools: bibPools ?? this.bibPools,
      raceCategories: raceCategories ?? this.raceCategories,
      ageCalculation: ageCalculation ?? this.ageCalculation,
      registrationConfig: registrationConfig ?? this.registrationConfig,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      timingConfig: timingConfig ?? this.timingConfig,
      drawConfig: drawConfig ?? this.drawConfig,
      penaltyTemplates: penaltyTemplates ?? this.penaltyTemplates,
      checklistItems: checklistItems ?? this.checklistItems,
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

// ─────────────────────────────────────────────────────────────────
// REGISTRATION CONFIG
// ─────────────────────────────────────────────────────────────────

/// Видимость поля в форме регистрации.
enum FieldVisibility {
  /// Обязательное поле.
  required,
  /// Необязательное (показано, но можно оставить пустым).
  optional,
  /// Скрытое (не показывается в форме).
  hidden,
}

/// Настройки формы регистрации.
///
/// Определяет какие поля собирать с участника, лимиты,
/// waitlist и политику возврата.
class RegistrationConfig {
  // ── Общие ──
  final bool isOpen;
  final int? maxParticipants;
  final bool waitlistEnabled;
  final int? waitlistMax;

  /// Дедлайн регистрации — после этой даты регистрация
  /// автоматически закрывается.
  final DateTime? registrationDeadline;

  // ── Публичность ──
  final bool publicStartList;
  final bool publicResults;

  // ── Оплата ──
  final bool refundEnabled;
  final int refundDeadlineHours;

  // ── Поля: участник ──
  final FieldVisibility fieldName;       // ФИО — всегда required
  final FieldVisibility fieldBirthDate;  // Дата рождения
  final FieldVisibility fieldGender;     // Пол
  final FieldVisibility fieldPhone;      // Телефон
  final FieldVisibility fieldEmail;      // E-mail
  final FieldVisibility fieldClub;       // Клуб / команда
  final FieldVisibility fieldCity;       // Город

  // ── Поля: собака (ездовой спорт) ──
  final FieldVisibility fieldDogName;    // Кличка собаки
  final FieldVisibility fieldDogBreed;   // Порода
  final FieldVisibility fieldVetCert;    // Вет. книжка / справка
  final FieldVisibility fieldChipNumber; // Чип-номер собаки

  // ── Кастомные поля ──
  final List<CustomField> customFields;

  const RegistrationConfig({
    this.isOpen = false,
    this.maxParticipants,
    this.registrationDeadline,
    this.waitlistEnabled = false,
    this.waitlistMax,
    this.publicStartList = true,
    this.publicResults = true,
    this.refundEnabled = true,
    this.refundDeadlineHours = 48,
    this.fieldName = FieldVisibility.required,
    this.fieldBirthDate = FieldVisibility.required,
    this.fieldGender = FieldVisibility.required,
    this.fieldPhone = FieldVisibility.optional,
    this.fieldEmail = FieldVisibility.required,
    this.fieldClub = FieldVisibility.optional,
    this.fieldCity = FieldVisibility.optional,
    this.fieldDogName = FieldVisibility.hidden,
    this.fieldDogBreed = FieldVisibility.hidden,
    this.fieldVetCert = FieldVisibility.hidden,
    this.fieldChipNumber = FieldVisibility.hidden,
    this.customFields = const [],
  });

  RegistrationConfig copyWith({
    bool? isOpen,
    int? maxParticipants,
    DateTime? registrationDeadline,
    bool? waitlistEnabled,
    int? waitlistMax,
    bool? publicStartList,
    bool? publicResults,
    bool? refundEnabled,
    int? refundDeadlineHours,
    FieldVisibility? fieldName,
    FieldVisibility? fieldBirthDate,
    FieldVisibility? fieldGender,
    FieldVisibility? fieldPhone,
    FieldVisibility? fieldEmail,
    FieldVisibility? fieldClub,
    FieldVisibility? fieldCity,
    FieldVisibility? fieldDogName,
    FieldVisibility? fieldDogBreed,
    FieldVisibility? fieldVetCert,
    FieldVisibility? fieldChipNumber,
    List<CustomField>? customFields,
  }) {
    return RegistrationConfig(
      isOpen: isOpen ?? this.isOpen,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      waitlistMax: waitlistMax ?? this.waitlistMax,
      publicStartList: publicStartList ?? this.publicStartList,
      publicResults: publicResults ?? this.publicResults,
      refundEnabled: refundEnabled ?? this.refundEnabled,
      refundDeadlineHours: refundDeadlineHours ?? this.refundDeadlineHours,
      fieldName: fieldName ?? this.fieldName,
      fieldBirthDate: fieldBirthDate ?? this.fieldBirthDate,
      fieldGender: fieldGender ?? this.fieldGender,
      fieldPhone: fieldPhone ?? this.fieldPhone,
      fieldEmail: fieldEmail ?? this.fieldEmail,
      fieldClub: fieldClub ?? this.fieldClub,
      fieldCity: fieldCity ?? this.fieldCity,
      fieldDogName: fieldDogName ?? this.fieldDogName,
      fieldDogBreed: fieldDogBreed ?? this.fieldDogBreed,
      fieldVetCert: fieldVetCert ?? this.fieldVetCert,
      fieldChipNumber: fieldChipNumber ?? this.fieldChipNumber,
      customFields: customFields ?? this.customFields,
    );
  }
}

/// Кастомное поле формы регистрации.
class CustomField {
  final String id;
  final String label;
  final CustomFieldType type;
  final FieldVisibility visibility;

  const CustomField({
    required this.id,
    required this.label,
    this.type = CustomFieldType.text,
    this.visibility = FieldVisibility.optional,
  });
}

/// Тип кастомного поля.
enum CustomFieldType { text, number, dropdown, checkbox }

// ─────────────────────────────────────────────────────────────────
// PRICING CONFIG
// ─────────────────────────────────────────────────────────────────

/// Настройки ценообразования мероприятия.
///
/// Базовая цена задаётся per-discipline (DisciplineConfig.priceRub),
/// здесь — общие настройки: early bird, промокоды, валюта.
class PricingConfig {
  /// Валюта (ISO 4217 код).
  final String currency;

  // ── Early Bird ──
  final bool earlyBirdEnabled;
  /// Скидка early bird в %. Например, 20 = минус 20%.
  final int earlyBirdDiscountPercent;
  /// Дедлайн early bird (дата окончания).
  final DateTime? earlyBirdDeadline;

  // ── Промокоды ──
  final List<PromoCode> promoCodes;

  const PricingConfig({
    this.currency = 'RUB',
    this.earlyBirdEnabled = false,
    this.earlyBirdDiscountPercent = 20,
    this.earlyBirdDeadline,
    this.promoCodes = const [],
  });

  PricingConfig copyWith({
    String? currency,
    bool? earlyBirdEnabled,
    int? earlyBirdDiscountPercent,
    DateTime? earlyBirdDeadline,
    List<PromoCode>? promoCodes,
  }) {
    return PricingConfig(
      currency: currency ?? this.currency,
      earlyBirdEnabled: earlyBirdEnabled ?? this.earlyBirdEnabled,
      earlyBirdDiscountPercent: earlyBirdDiscountPercent ?? this.earlyBirdDiscountPercent,
      earlyBirdDeadline: earlyBirdDeadline ?? this.earlyBirdDeadline,
      promoCodes: promoCodes ?? this.promoCodes,
    );
  }
}

/// Промокод.
class PromoCode {
  final String id;
  final String code;
  /// Скидка в %.
  final int discountPercent;
  /// Макс. использований (null = безлимит).
  final int? maxUses;
  /// Сколько раз уже использован.
  final int usedCount;
  /// Активен ли.
  final bool isActive;

  const PromoCode({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
  });

  bool get isExhausted => maxUses != null && usedCount >= maxUses!;
}

// ─────────────────────────────────────────────────────────────────
// TIMING CONFIG
// ─────────────────────────────────────────────────────────────────

/// Точность хронометража.
enum TimingPrecision { seconds, tenths, hundredths, milliseconds }

/// Общие настройки хронометража.
class TimingConfig {
  final TimingPrecision precision;
  final String timeFormat;      // 'HH:mm:ss.S' etc
  final bool dualTiming;        // мастер + контрольный
  final bool gpsTracking;
  final bool auditLog;
  final bool doubleDnfConfirm;  // двойное подтверждение DNF
  final bool photoFinish;

  const TimingConfig({
    this.precision = TimingPrecision.tenths,
    this.timeFormat = 'HH:mm:ss.S',
    this.dualTiming = false,
    this.gpsTracking = false,
    this.auditLog = true,
    this.doubleDnfConfirm = true,
    this.photoFinish = false,
  });

  TimingConfig copyWith({
    TimingPrecision? precision,
    String? timeFormat,
    bool? dualTiming,
    bool? gpsTracking,
    bool? auditLog,
    bool? doubleDnfConfirm,
    bool? photoFinish,
  }) {
    return TimingConfig(
      precision: precision ?? this.precision,
      timeFormat: timeFormat ?? this.timeFormat,
      dualTiming: dualTiming ?? this.dualTiming,
      gpsTracking: gpsTracking ?? this.gpsTracking,
      auditLog: auditLog ?? this.auditLog,
      doubleDnfConfirm: doubleDnfConfirm ?? this.doubleDnfConfirm,
      photoFinish: photoFinish ?? this.photoFinish,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DRAW CONFIG (жеребьёвка)
// ─────────────────────────────────────────────────────────────────

/// Режим жеребьёвки.
enum DrawMode {
  /// Автоматический случайный порядок.
  auto,
  /// Организатор назначает вручную.
  manual,
  /// Посев + случайная жеребьёвка остальных.
  combined,
}

/// Группировка при жеребьёвке.
enum DrawGrouping {
  /// Все категории вместе.
  joint,
  /// По категориям (CEC → OPEN → Юн...).
  byCategory,
}

/// Настройки жеребьёвки мероприятия.
class DrawConfig {
  final DrawMode mode;
  final DrawGrouping grouping;
  /// Буфер между группами (минуты, дефолт для новых групп).
  final int bufferMinutes;
  /// Только подтверждённые участники.
  final bool onlyApproved;

  const DrawConfig({
    this.mode = DrawMode.auto,
    this.grouping = DrawGrouping.joint,
    this.bufferMinutes = 5,
    this.onlyApproved = true,
  });

  DrawConfig copyWith({
    DrawMode? mode,
    DrawGrouping? grouping,
    int? bufferMinutes,
    bool? onlyApproved,
  }) {
    return DrawConfig(
      mode: mode ?? this.mode,
      grouping: grouping ?? this.grouping,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      onlyApproved: onlyApproved ?? this.onlyApproved,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PENALTY TEMPLATE (библиотека штрафов)
// ─────────────────────────────────────────────────────────────────

/// Шаблон штрафа для быстрого назначения.
///
/// Организатор настраивает библиотеку штрафов до старта,
/// судьи на гонке выбирают шаблон вместо ручного ввода.
class PenaltyTemplate {
  final String id;
  /// Код нарушения (напр. «P1», «F03», «ДСК»).
  final String code;
  /// Описание (напр. «Помеха на дистанции»).
  final String description;
  /// Штрафное время (null = DSQ/DNF — дисквалификация).
  final Duration? timePenalty;
  /// Порядок сортировки.
  final int sortOrder;

  const PenaltyTemplate({
    required this.id,
    required this.code,
    required this.description,
    this.timePenalty,
    this.sortOrder = 0,
  });

  /// DSQ-штраф (дисквалификация без времени).
  bool get isDsq => timePenalty == null;

  String get displayTime =>
      isDsq ? 'DSQ' : '+${timePenalty!.inSeconds}с';
}

/// Стандартная библиотека штрафов.
const List<PenaltyTemplate> defaultPenaltyTemplates = [
  PenaltyTemplate(id: 'pt-01', code: 'P1', description: 'Помеха на дистанции', timePenalty: Duration(seconds: 15), sortOrder: 1),
  PenaltyTemplate(id: 'pt-02', code: 'P2', description: 'Фальстарт', timePenalty: Duration(seconds: 10), sortOrder: 2),
  PenaltyTemplate(id: 'pt-03', code: 'P3', description: 'Срезка трассы', timePenalty: Duration(seconds: 30), sortOrder: 3),
  PenaltyTemplate(id: 'pt-04', code: 'P4', description: 'Пропуск ворот/чекпоинта', timePenalty: Duration(seconds: 60), sortOrder: 4),
  PenaltyTemplate(id: 'pt-05', code: 'P5', description: 'Жестокое обращение с собакой', sortOrder: 5), // DSQ
  PenaltyTemplate(id: 'pt-06', code: 'P6', description: 'Посторонняя помощь', timePenalty: Duration(seconds: 30), sortOrder: 6),
  PenaltyTemplate(id: 'pt-07', code: 'P7', description: 'Неспортивное поведение', sortOrder: 7), // DSQ
  PenaltyTemplate(id: 'pt-08', code: 'P8', description: 'Нарушение экипировки', timePenalty: Duration(seconds: 15), sortOrder: 8),
];

// ─────────────────────────────────────────────────────────────────
// CHECKLIST (предстартовый чек-лист)
// ─────────────────────────────────────────────────────────────────

/// Элемент предстартового чек-листа.
///
/// Организатор настраивает список обязательных пунктов
/// которые должны быть выполнены перед стартом.
class ChecklistItemConfig {
  final String id;
  /// Заголовок (напр. «Ветконтроль»).
  final String title;
  /// Описание / подсказка.
  final String? description;
  /// Обязательный пункт (блокирует старт если не выполнен).
  final bool required;
  /// Ответственная роль (напр. vet, marshal, referee).
  final String? assignedRole;
  /// Порядок сортировки.
  final int sortOrder;

  const ChecklistItemConfig({
    required this.id,
    required this.title,
    this.description,
    this.required = true,
    this.assignedRole,
    this.sortOrder = 0,
  });
}

/// Стандартный предстартовый чек-лист.
const List<ChecklistItemConfig> defaultChecklistItems = [
  ChecklistItemConfig(id: 'cl-01', title: 'Регистрация участников', description: 'Все заявки обработаны', assignedRole: 'secretary', sortOrder: 1),
  ChecklistItemConfig(id: 'cl-02', title: 'Жеребьёвка', description: 'Стартовый порядок утверждён', assignedRole: 'referee', sortOrder: 2),
  ChecklistItemConfig(id: 'cl-03', title: 'Стартовый лист', description: 'Опубликован для участников', assignedRole: 'secretary', sortOrder: 3),
  ChecklistItemConfig(id: 'cl-04', title: 'BIB номера', description: 'Все номера выданы', assignedRole: 'secretary', sortOrder: 4),
  ChecklistItemConfig(id: 'cl-05', title: 'Ветконтроль', description: 'Все собаки осмотрены', assignedRole: 'vet', sortOrder: 5),
  ChecklistItemConfig(id: 'cl-06', title: 'Мандатная комиссия', description: 'Документы проверены', assignedRole: 'referee', sortOrder: 6),
  ChecklistItemConfig(id: 'cl-07', title: 'Трасса готова', description: 'Разметка, ворота, безопасность', assignedRole: 'marshal', sortOrder: 7),
  ChecklistItemConfig(id: 'cl-08', title: 'Хронометраж', description: 'Система протестирована', assignedRole: 'timing', sortOrder: 8),
  ChecklistItemConfig(id: 'cl-09', title: 'Брифинг', description: 'Проведён для участников', required: false, assignedRole: 'referee', sortOrder: 9),
];

// ─────────────────────────────────────────────────────────────────
// PARTICIPANT (ЗАЯВКА)
// ─────────────────────────────────────────────────────────────────

/// Статус оплаты.
enum PaymentStatus { unpaid, paid, refunded }

/// Статус заявки.
enum ApplicationStatus { pending, approved, rejected, cancelled }

/// Статус мандатной комиссии.
enum MandateStatus { pending, passed, failed }

/// Статус ветконтроля.
enum VetStatus { pending, passed, failed }

/// Участник / Заявка на мероприятие.
class Participant {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String disciplineId;
  final String disciplineName;
  final String bib;
  final String? category;
  final String? dogName;
  final PaymentStatus paymentStatus;
  final ApplicationStatus applicationStatus;
  final int? priceRub;
  final DateTime registeredAt;

  // ─── Расширенные поля ───
  final String? gender;       // 'male' / 'female'
  final DateTime? birthDate;  // для авто-категории по возрасту
  final String? city;         // город
  final String? club;         // клуб / команда
  final String? rank;         // разряд / квалификация
  final String? insuranceNo;  // номер страховки

  // ─── Операционные статусы ───
  final MandateStatus mandateStatus;
  final VetStatus vetStatus;
  final DateTime? checkInTime; // null = не прибыл

  const Participant({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.disciplineId,
    required this.disciplineName,
    required this.bib,
    this.category,
    this.dogName,
    this.paymentStatus = PaymentStatus.unpaid,
    this.applicationStatus = ApplicationStatus.pending,
    this.priceRub,
    required this.registeredAt,
    this.gender,
    this.birthDate,
    this.city,
    this.club,
    this.rank,
    this.insuranceNo,
    this.mandateStatus = MandateStatus.pending,
    this.vetStatus = VetStatus.pending,
    this.checkInTime,
  });

  /// Вычисляет возраст на указанную дату (или сегодня).
  int? ageOn(DateTime date) {
    if (birthDate == null) return null;
    int age = date.year - birthDate!.year;
    if (date.month < birthDate!.month ||
        (date.month == birthDate!.month && date.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Определяет категорию автоматически по полу и возрасту.
  /// Ищет наиболее подходящую RaceCategory из списка мероприятия.
  String? resolveCategory(List<RaceCategory> categories, {DateTime? eventDate}) {
    if (categories.isEmpty) return category;
    final date = eventDate ?? DateTime.now();
    final age = ageOn(date);
    final g = gender == 'male'
        ? CategoryGender.male
        : gender == 'female'
            ? CategoryGender.female
            : CategoryGender.any;

    // Ищем наиболее точное совпадение (с полом и возрастом)
    RaceCategory? best;
    int bestScore = -1;

    for (final cat in categories) {
      int score = 0;
      // Проверка пола
      if (cat.gender != CategoryGender.any && g != CategoryGender.any) {
        if (cat.gender != g) continue; // не совпадает — пропуск
        score += 2; // точное совпадение пола
      } else if (cat.gender == CategoryGender.any) {
        score += 0; // универсальная
      }
      // Проверка возраста
      if (age != null) {
        if (cat.ageMin != null && age < cat.ageMin!) continue;
        if (cat.ageMax != null && age > cat.ageMax!) continue;
        if (cat.ageMin != null || cat.ageMax != null) score += 3;
      }
      if (score > bestScore) {
        bestScore = score;
        best = cat;
      }
    }
    return best?.shortName ?? category;
  }

  Participant copyWith({
    String? name,
    String? phone,
    String? email,
    String? disciplineId,
    String? disciplineName,
    String? bib,
    String? category,
    String? dogName,
    PaymentStatus? paymentStatus,
    ApplicationStatus? applicationStatus,
    int? priceRub,
    String? gender,
    DateTime? birthDate,
    String? city,
    String? club,
    String? rank,
    String? insuranceNo,
    MandateStatus? mandateStatus,
    VetStatus? vetStatus,
    DateTime? checkInTime,
    bool clearCheckInTime = false,
  }) {
    return Participant(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      disciplineId: disciplineId ?? this.disciplineId,
      disciplineName: disciplineName ?? this.disciplineName,
      bib: bib ?? this.bib,
      category: category ?? this.category,
      dogName: dogName ?? this.dogName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      priceRub: priceRub ?? this.priceRub,
      registeredAt: registeredAt,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      club: club ?? this.club,
      rank: rank ?? this.rank,
      insuranceNo: insuranceNo ?? this.insuranceNo,
      mandateStatus: mandateStatus ?? this.mandateStatus,
      vetStatus: vetStatus ?? this.vetStatus,
      checkInTime: clearCheckInTime ? null : (checkInTime ?? this.checkInTime),
    );
  }
}

/// Демо-участники.
final List<Participant> demoParticipants = [
  Participant(id: 'p-1', name: 'Петров Алексей', phone: '+7 912 111-11-11', disciplineId: 'd-skijor-6', disciplineName: 'Скидж. 5км', bib: '07', category: 'М', gender: 'male', birthDate: DateTime(2000, 3, 15), city: 'Екатеринбург', club: 'Сноу Дог', dogName: 'Rex', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.approved, priceRub: 2500, registeredAt: DateTime(2026, 2, 1)),
  Participant(id: 'p-2', name: 'Сидорова Мария', phone: '+7 912 222-22-22', disciplineId: 'd-skijor-6', disciplineName: 'Скидж. 5км', bib: '12', category: 'Ж', gender: 'female', birthDate: DateTime(1998, 7, 22), city: 'Челябинск', club: 'Хаски клуб', dogName: 'Luna', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.approved, priceRub: 2500, registeredAt: DateTime(2026, 2, 3)),
  Participant(id: 'p-3', name: 'Иванов Виктор', phone: '+7 912 333-33-33', disciplineId: 'd-skijor-20', disciplineName: 'Скидж. 10км', bib: '24', category: 'М', gender: 'male', birthDate: DateTime(1995, 1, 10), city: 'Пермь', club: 'Северный ветер', dogName: 'Storm', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.approved, priceRub: 3500, registeredAt: DateTime(2026, 2, 5)),
  Participant(id: 'p-4', name: 'Козлов Григорий', phone: '+7 912 444-44-44', disciplineId: 'd-sled2-15', disciplineName: 'Нарты 15км', bib: '31', category: 'М', gender: 'male', birthDate: DateTime(1988, 11, 5), city: 'Тюмень', club: 'Сноу Дог', dogName: 'Wolf', paymentStatus: PaymentStatus.unpaid, applicationStatus: ApplicationStatus.approved, priceRub: 3000, registeredAt: DateTime(2026, 2, 7)),
  Participant(id: 'p-5', name: 'Морозова Дарья', email: 'morozova@mail.ru', disciplineId: 'd-canicross-3', disciplineName: 'Каникросс', bib: '42', category: 'Ж', gender: 'female', birthDate: DateTime(1993, 6, 18), city: 'Екатеринбург', club: 'Хаски клуб', dogName: 'Buddy', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.pending, priceRub: 1500, registeredAt: DateTime(2026, 2, 10)),
  Participant(id: 'p-6', name: 'Волков Евгений', phone: '+7 912 666-66-66', disciplineId: 'd-skijor-6', disciplineName: 'Скидж. 5км', bib: '55', category: 'М', gender: 'male', birthDate: DateTime(1985, 4, 30), city: 'Курган', club: 'Северный ветер', dogName: 'Alaska', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.approved, priceRub: 2500, registeredAt: DateTime(2026, 2, 12)),
  Participant(id: 'p-7', name: 'Лебедев Жан', phone: '+7 912 777-77-77', disciplineId: 'd-sled2-15', disciplineName: 'Нарты 15км', bib: '63', category: 'М', gender: 'male', birthDate: DateTime(1982, 9, 12), city: 'Пермь', dogName: 'Max', paymentStatus: PaymentStatus.unpaid, applicationStatus: ApplicationStatus.pending, priceRub: 3000, registeredAt: DateTime(2026, 2, 14)),
  Participant(id: 'p-8', name: 'Новикова Злата', phone: '+7 912 888-88-88', disciplineId: 'd-canicross-3', disciplineName: 'Каникросс', bib: '77', category: 'Ж', gender: 'female', birthDate: DateTime(2001, 12, 3), city: 'Екатеринбург', club: 'Сноу Дог', dogName: 'Rocky', paymentStatus: PaymentStatus.paid, applicationStatus: ApplicationStatus.approved, priceRub: 1500, registeredAt: DateTime(2026, 2, 16)),
];


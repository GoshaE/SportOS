/// Библиотека видов спорта и дисциплин SportOS.
///
/// Содержит предопределённый каталог спортивных дисциплин,
/// сгруппированных по видам спорта. Используется при создании
/// дисциплин мероприятия — организатор выбирает из каталога.
library;

// ─────────────────────────────────────────────────────────────────
// SPORT CATEGORY
// ─────────────────────────────────────────────────────────────────

/// Вид спорта (верхний уровень группировки).
class SportCategory {
  final String id;
  final String name;
  final String icon;
  final List<DisciplineTemplate> disciplines;

  const SportCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.disciplines,
  });
}

// ─────────────────────────────────────────────────────────────────
// DISCIPLINE TEMPLATE
// ─────────────────────────────────────────────────────────────────

/// Шаблон дисциплины из каталога.
///
/// Содержит дефолтные значения (дистанция, круги, тип старта,
/// категории). Организатор может изменить любое значение при
/// добавлении в мероприятие.
class DisciplineTemplate {
  /// Короткое название (для списка).
  final String name;

  /// Полное описание.
  final String? description;

  /// Дефолтная длина круга (метры).
  final int lapLengthM;

  /// Дефолтное кол-во кругов.
  final int laps;

  /// Рекомендуемый тип старта.
  final String startType; // 'individual' | 'mass' | 'wave'

  /// Рекомендуемый интервал при раздельном старте (сек).
  final int intervalSec;

  /// Дефолтные категории.
  final List<String> defaultCategories;

  /// Дефолтная цена (₽).
  final int? defaultPriceRub;

  /// Иконка для визуального различия.
  final String? emoji;

  const DisciplineTemplate({
    required this.name,
    this.description,
    required this.lapLengthM,
    this.laps = 1,
    this.startType = 'individual',
    this.intervalSec = 30,
    this.defaultCategories = const ['М', 'Ж'],
    this.defaultPriceRub,
    this.emoji,
  });

  /// Общая дистанция (км).
  double get distanceKm => lapLengthM * laps / 1000.0;
}

// ═════════════════════════════════════════════════════════════════
// КАТАЛОГ ВИДОВ СПОРТА
// ═════════════════════════════════════════════════════════════════

const disciplineCatalog = <SportCategory>[

  // ── Ездовой спорт ──
  SportCategory(
    id: 'sled',
    name: 'Ездовой спорт',
    icon: '🐕',
    disciplines: [
      // Скиджоринг
      DisciplineTemplate(name: 'Скиджоринг (1 соб.)', lapLengthM: 3000, laps: 2, intervalSec: 30, emoji: '⛷🐕', defaultPriceRub: 2500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Скиджоринг (2 соб.)', lapLengthM: 5000, laps: 2, intervalSec: 30, emoji: '⛷🐕🐕', defaultPriceRub: 3000, defaultCategories: ['М', 'Ж']),
      // Нарты
      DisciplineTemplate(name: 'Нарты (2 соб.)', lapLengthM: 5000, laps: 3, intervalSec: 30, emoji: '🛷', defaultPriceRub: 3500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Нарты (4 соб.)', lapLengthM: 5000, laps: 4, intervalSec: 30, emoji: '🛷', defaultPriceRub: 4000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Нарты (6 соб.)', lapLengthM: 5000, laps: 6, intervalSec: 45, emoji: '🛷', defaultPriceRub: 4500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Нарты (8+ соб.)', lapLengthM: 5000, laps: 8, intervalSec: 60, emoji: '🛷', defaultPriceRub: 5000, defaultCategories: ['М', 'Ж']),
      // Пулка
      DisciplineTemplate(name: 'Пулка', lapLengthM: 3000, laps: 2, intervalSec: 30, emoji: '🎿', defaultPriceRub: 2500, defaultCategories: ['М', 'Ж']),
      // Каникросс
      DisciplineTemplate(name: 'Каникросс', lapLengthM: 2500, laps: 2, startType: 'mass', emoji: '🏃🐕', defaultPriceRub: 1500, defaultCategories: ['М', 'Ж', 'Юн', 'Юнк', 'Дети']),
      // Байкджоринг
      DisciplineTemplate(name: 'Байкджоринг (1 соб.)', lapLengthM: 3000, laps: 2, intervalSec: 30, emoji: '🚴🐕', defaultPriceRub: 2500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Байкджоринг (2 соб.)', lapLengthM: 5000, laps: 2, intervalSec: 30, emoji: '🚴🐕🐕', defaultPriceRub: 3000, defaultCategories: ['М', 'Ж']),
      // Скутер
      DisciplineTemplate(name: 'Скутер (1 соб.)', lapLengthM: 3000, laps: 2, intervalSec: 30, emoji: '🛴🐕', defaultPriceRub: 2500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Скутер (2 соб.)', lapLengthM: 5000, laps: 2, intervalSec: 30, emoji: '🛴🐕🐕', defaultPriceRub: 3000, defaultCategories: ['М', 'Ж']),
      // Догтрекинг
      DisciplineTemplate(name: 'Догтрекинг', lapLengthM: 5000, laps: 1, startType: 'mass', emoji: '🥾🐕', defaultPriceRub: 1000, defaultCategories: ['М', 'Ж', 'Юн', 'Дети']),
    ],
  ),

  // ── Лыжные гонки ──
  SportCategory(
    id: 'ski',
    name: 'Лыжные гонки',
    icon: '⛷',
    disciplines: [
      DisciplineTemplate(name: 'Классика 5 км', lapLengthM: 2500, laps: 2, intervalSec: 30, emoji: '🎿', defaultPriceRub: 500, defaultCategories: ['М', 'Ж', 'Юн', 'Юнк']),
      DisciplineTemplate(name: 'Классика 10 км', lapLengthM: 5000, laps: 2, intervalSec: 30, emoji: '🎿', defaultPriceRub: 700, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Классика 15 км', lapLengthM: 5000, laps: 3, intervalSec: 30, emoji: '🎿', defaultPriceRub: 800, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Свободный 5 км', lapLengthM: 2500, laps: 2, intervalSec: 30, emoji: '⛷', defaultPriceRub: 500, defaultCategories: ['М', 'Ж', 'Юн', 'Юнк']),
      DisciplineTemplate(name: 'Свободный 10 км', lapLengthM: 5000, laps: 2, intervalSec: 30, emoji: '⛷', defaultPriceRub: 700, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Свободный 15 км', lapLengthM: 5000, laps: 3, intervalSec: 30, emoji: '⛷', defaultPriceRub: 800, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Скиатлон', lapLengthM: 5000, laps: 2, startType: 'mass', emoji: '🎿⛷', defaultPriceRub: 1000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Спринт', lapLengthM: 1500, laps: 1, intervalSec: 15, emoji: '⚡', defaultPriceRub: 500, defaultCategories: ['М', 'Ж', 'Юн', 'Юнк']),
      DisciplineTemplate(name: 'Марафон 30 км', lapLengthM: 10000, laps: 3, startType: 'mass', emoji: '🏔', defaultPriceRub: 1500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Марафон 50 км', lapLengthM: 10000, laps: 5, startType: 'mass', emoji: '🏔', defaultPriceRub: 2000, defaultCategories: ['М']),
      DisciplineTemplate(name: 'Эстафета 4×5 км', lapLengthM: 5000, laps: 1, startType: 'mass', emoji: '🔄', defaultPriceRub: 2000, defaultCategories: ['М', 'Ж']),
    ],
  ),

  // ── Трейлраннинг ──
  SportCategory(
    id: 'trail',
    name: 'Трейлраннинг',
    icon: '🏔',
    disciplines: [
      DisciplineTemplate(name: 'Трейл 10 км', lapLengthM: 10000, laps: 1, startType: 'mass', emoji: '🥾', defaultPriceRub: 1500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Трейл 21 км', lapLengthM: 21000, laps: 1, startType: 'wave', emoji: '🏃', defaultPriceRub: 2500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Трейл 42 км', lapLengthM: 42000, laps: 1, startType: 'wave', emoji: '🏃‍♂️', defaultPriceRub: 4000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Ультра 50 км', lapLengthM: 50000, laps: 1, startType: 'wave', emoji: '🦸', defaultPriceRub: 5000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Ультра 100 км', lapLengthM: 100000, laps: 1, startType: 'wave', emoji: '🦸', defaultPriceRub: 8000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Забег 5 км', lapLengthM: 5000, laps: 1, startType: 'mass', emoji: '🏃', defaultPriceRub: 800, defaultCategories: ['М', 'Ж', 'Юн', 'Юнк', 'Дети']),
      DisciplineTemplate(name: 'Детский забег 1 км', lapLengthM: 1000, laps: 1, startType: 'mass', emoji: '👧', defaultPriceRub: 300, defaultCategories: ['Дети']),
    ],
  ),

  // ── Велоспорт ──
  SportCategory(
    id: 'cycle',
    name: 'Велоспорт',
    icon: '🚴',
    disciplines: [
      DisciplineTemplate(name: 'Кросс-кантри XCO', lapLengthM: 4000, laps: 5, startType: 'mass', emoji: '🚵', defaultPriceRub: 2000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Кросс-кантри XCM', lapLengthM: 20000, laps: 3, startType: 'wave', emoji: '🚵', defaultPriceRub: 3000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Гонка с раздельным стартом', lapLengthM: 20000, laps: 1, intervalSec: 60, emoji: '🚴‍♂️', defaultPriceRub: 1500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Критериум', lapLengthM: 1500, laps: 20, startType: 'mass', emoji: '🚴', defaultPriceRub: 1000, defaultCategories: ['М', 'Ж']),
    ],
  ),

  // ── Биатлон ──
  SportCategory(
    id: 'biathlon',
    name: 'Биатлон',
    icon: '🎯',
    disciplines: [
      DisciplineTemplate(name: 'Спринт 7.5 км', lapLengthM: 2500, laps: 3, intervalSec: 30, emoji: '🔫', defaultPriceRub: 1000, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Спринт 10 км', lapLengthM: 2500, laps: 4, intervalSec: 30, emoji: '🔫', defaultPriceRub: 1000, defaultCategories: ['М']),
      DisciplineTemplate(name: 'Индивидуальная 15 км', lapLengthM: 3000, laps: 5, intervalSec: 30, emoji: '🎯', defaultPriceRub: 1500, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Масс-старт 12.5 км', lapLengthM: 2500, laps: 5, startType: 'mass', emoji: '🎯', defaultPriceRub: 1200, defaultCategories: ['М', 'Ж']),
      DisciplineTemplate(name: 'Гонка преследования', lapLengthM: 2500, laps: 4, startType: 'mass', emoji: '🔄', defaultPriceRub: 1200, defaultCategories: ['М', 'Ж']),
    ],
  ),

  // ── Другое ──
  SportCategory(
    id: 'other',
    name: 'Другое',
    icon: '🏁',
    disciplines: [
      DisciplineTemplate(name: 'Своя дисциплина', lapLengthM: 5000, laps: 1, startType: 'individual', emoji: '⭐', defaultPriceRub: 1000, defaultCategories: ['М', 'Ж']),
    ],
  ),
];

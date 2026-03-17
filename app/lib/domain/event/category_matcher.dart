// Category Matcher — сервис авто-распределения по категориям.
//
// Принимает дату рождения, пол, дату гонки → возвращает категорию.
// Участник НЕ может выбрать категорию — строго автомат.

import '../event/event_config.dart';

/// Результат матчинга категории.
class CategoryMatch {
  /// Назначенная категория (самая узкая подходящая).
  final RaceCategory category;

  /// Все допустимые категории (для отладки / отображения).
  final List<RaceCategory> allMatching;

  /// Рассчитанный возраст по правилам мероприятия.
  final int calculatedAge;

  const CategoryMatch({
    required this.category,
    required this.allMatching,
    required this.calculatedAge,
  });
}

/// Сервис авто-распределения участников по категориям.
///
/// Логика:
/// 1. Считает возраст (по году или точный — настройка мероприятия)
/// 2. Фильтрует категории по полу и возрасту
/// 3. Выбирает самую узкую (с наименьшим диапазоном)
class CategoryMatcher {
  const CategoryMatcher._();

  /// Рассчитать спортивный возраст.
  ///
  /// [birthDate] — дата рождения участника
  /// [raceDate] — дата гонки
  /// [method] — метод расчёта (по году / точный)
  static int calculateAge(
    DateTime birthDate,
    DateTime raceDate,
    AgeCalculation method,
  ) {
    switch (method) {
      case AgeCalculation.byYear:
        // Стандарт FIS/IFSS: возраст = год гонки − год рождения
        return raceDate.year - birthDate.year;

      case AgeCalculation.exactDate:
        // Точный возраст на дату гонки
        var age = raceDate.year - birthDate.year;
        if (raceDate.month < birthDate.month ||
            (raceDate.month == birthDate.month && raceDate.day < birthDate.day)) {
          age--;
        }
        return age;
    }
  }

  /// Найти все подходящие категории для участника.
  ///
  /// [birthDate] — дата рождения
  /// [gender] — пол участника
  /// [raceDate] — дата гонки
  /// [categories] — доступные категории мероприятия
  /// [method] — метод расчёта возраста
  static List<RaceCategory> findMatching({
    required DateTime birthDate,
    required CategoryGender gender,
    required DateTime raceDate,
    required List<RaceCategory> categories,
    required AgeCalculation method,
  }) {
    final age = calculateAge(birthDate, raceDate, method);
    return categories.where((cat) {
      // Проверка пола
      if (cat.gender != CategoryGender.any && cat.gender != gender) {
        return false;
      }
      // Проверка возраста
      if (cat.ageMin != null && age < cat.ageMin!) return false;
      if (cat.ageMax != null && age > cat.ageMax!) return false;
      return true;
    }).toList();
  }

  /// Автоматически определить категорию участника.
  ///
  /// Возвращает null если ни одна категория не подходит.
  /// Выбирает самую узкую (специфичную) категорию — с наименьшим
  /// диапазоном возрастов.
  ///
  /// Приоритет при равном диапазоне:
  ///   1. С ограничением по полу (male/female) > any
  ///   2. С ограничением по возрасту > без ограничений
  ///   3. По sortOrder
  static CategoryMatch? match({
    required DateTime birthDate,
    required CategoryGender gender,
    required DateTime raceDate,
    required List<RaceCategory> categories,
    required AgeCalculation method,
  }) {
    final age = calculateAge(birthDate, raceDate, method);
    final matching = findMatching(
      birthDate: birthDate,
      gender: gender,
      raceDate: raceDate,
      categories: categories,
      method: method,
    );

    if (matching.isEmpty) return null;

    // Сортируем: самая узкая (специфичная) первая
    final sorted = List<RaceCategory>.from(matching)..sort((a, b) {
      // 1. Приоритет: с ограничением по полу > any
      final aGenderSpecific = a.gender != CategoryGender.any ? 0 : 1;
      final bGenderSpecific = b.gender != CategoryGender.any ? 0 : 1;
      if (aGenderSpecific != bGenderSpecific) return aGenderSpecific.compareTo(bGenderSpecific);

      // 2. Приоритет: с ограничением по возрасту > без
      final aHasAge = (a.ageMin != null || a.ageMax != null) ? 0 : 1;
      final bHasAge = (b.ageMin != null || b.ageMax != null) ? 0 : 1;
      if (aHasAge != bHasAge) return aHasAge.compareTo(bHasAge);

      // 3. Самый узкий диапазон
      final aRange = (a.ageMax ?? 999) - (a.ageMin ?? 0);
      final bRange = (b.ageMax ?? 999) - (b.ageMin ?? 0);
      if (aRange != bRange) return aRange.compareTo(bRange);

      // 4. По sortOrder
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return CategoryMatch(
      category: sorted.first,
      allMatching: matching,
      calculatedAge: age,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_config.dart';
import '../timing/models.dart';
import '../../data/config_storage.dart';
import '../../data/participants_storage.dart';
// ─────────────────────────────────────────────────────────────────
// EVENT CONFIG PROVIDER
// ─────────────────────────────────────────────────────────────────

/// Единый источник правды для конфигурации мероприятия.
///
/// Все экраны читают из этого провайдера. Settings UI пишет сюда.
class EventConfigNotifier extends Notifier<EventConfig> {
  @override
  EventConfig build() {
    // Start with demo, then load saved config asynchronously
    _loadSaved();
    return _demoEvent();
  }

  Future<void> _loadSaved() async {
    final saved = await ConfigStorage.load();
    if (saved != null) {
      state = saved.config;
      _disciplines = saved.disciplines;
    }
  }

  /// Auto-save after any mutation.
  void _save() {
    ConfigStorage.save(state, _disciplines);
  }

  /// Обновить конфигурацию мероприятия.
  void update(EventConfig Function(EventConfig current) updater) {
    state = updater(state);
    _save();
  }

  /// Обновить конкретную дисциплину в конфиге.
  void updateDiscipline(String disciplineId, DisciplineConfig Function(DisciplineConfig) updater) {
    final updated = _disciplines.map((d) {
      if (d.id == disciplineId) return updater(d);
      return d;
    }).toList();
    _disciplines = updated;
    // Trigger rebuild by touching state
    state = state.copyWith();
    _save();
  }

  /// Добавить день из шаблона (копия предыдущего дня).
  void addDayFromTemplate({int? copyFromDayNumber}) {
    final template = copyFromDayNumber != null
        ? state.days.firstWhere((d) => d.dayNumber == copyFromDayNumber, orElse: () => state.days.last)
        : state.days.isNotEmpty ? state.days.last : null;

    final newDayNumber = (state.days.map((d) => d.dayNumber).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    final newDate = state.startDate.add(Duration(days: newDayNumber - 1));

    final newDay = template != null
        ? RaceDay.copyFromDay(template, dayNumber: newDayNumber, date: newDate)
        : RaceDay(dayNumber: newDayNumber, date: newDate, disciplineIds: disciplines.map((d) => d.id).toList());

    state = state.copyWith(
      isMultiDay: true,
      days: [...state.days, newDay],
      endDate: newDate,
    );
    _save();
  }

  /// Обновить конкретный день.
  void updateDay(int dayNumber, RaceDay Function(RaceDay) updater) {
    state = state.copyWith(
      days: state.days.map((d) => d.dayNumber == dayNumber ? updater(d) : d).toList(),
    );
    _save();
  }

  /// Удалить день.
  void removeDay(int dayNumber) {
    final updated = state.days.where((d) => d.dayNumber != dayNumber).toList();
    state = state.copyWith(
      days: updated,
      isMultiDay: updated.length > 1,
    );
    _save();
  }

  /// Переключить многодневность.
  void toggleMultiDay(bool value) {
    if (value && state.days.isEmpty) {
      // Включили: создаём 2 дня с умными дефолтами
      final allDiscIds = disciplines.map((d) => d.id).toList();
      state = state.copyWith(
        isMultiDay: true,
        days: [
          RaceDay(dayNumber: 1, date: state.startDate, disciplineIds: allDiscIds, startOrder: StartOrder.draw),
          RaceDay(dayNumber: 2, date: state.startDate.add(const Duration(days: 1)), disciplineIds: allDiscIds, startOrder: StartOrder.reverse),
        ],
        endDate: state.startDate.add(const Duration(days: 1)),
      );
    } else if (!value) {
      state = state.copyWith(isMultiDay: false);
    }
    _save();
  }

  // ── Internal disciplines storage ──
  // Дисциплины хранятся отдельно, т.к. DisciplineConfig уже существует
  // в timing models и используется race session. Провайдер ниже читает их.
  List<DisciplineConfig> _disciplines = _demoDisciplines();

  List<DisciplineConfig> get disciplines => _disciplines;

  void setDisciplines(List<DisciplineConfig> list) {
    _disciplines = list;
    state = state.copyWith(); // trigger rebuild
    _save();
  }

  /// Добавить новую дисциплину.
  void addDiscipline(DisciplineConfig disc) {
    _disciplines = [..._disciplines, disc];
    state = state.copyWith(); // trigger rebuild
    _save();
  }

  /// Удалить дисциплину по ID.
  void removeDiscipline(String disciplineId) {
    _disciplines = _disciplines.where((d) => d.id != disciplineId).toList();
    state = state.copyWith(); // trigger rebuild
    _save();
  }
}

final eventConfigProvider = NotifierProvider<EventConfigNotifier, EventConfig>(
  EventConfigNotifier.new,
);

// ─────────────────────────────────────────────────────────────────
// COMPUTED PROVIDERS
// ─────────────────────────────────────────────────────────────────

/// Список всех трасс мероприятия.
final coursesProvider = Provider<List<Course>>((ref) {
  return ref.watch(eventConfigProvider).courses;
});

/// Список всех дисциплин мероприятия (typed).
final disciplineConfigsProvider = Provider<List<DisciplineConfig>>((ref) {
  // Watch event config to trigger rebuilds
  ref.watch(eventConfigProvider);
  return ref.read(eventConfigProvider.notifier).disciplines;
});

/// Дисциплины для выбранного дня (multi-day).
final disciplinesForDayProvider = Provider.family<List<DisciplineConfig>, int>((ref, dayNumber) {
  final all = ref.watch(disciplineConfigsProvider);
  return all.where((d) => d.dayNumber == dayNumber || d.dayNumber == null).toList();
});

/// Текущий выбранный день (для multi-day UI).
final activeDayProvider = NotifierProvider<_ActiveDayNotifier, int>(
  _ActiveDayNotifier.new,
);

class _ActiveDayNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void set(int day) => state = day;
}

/// DisplaySettings для конкретной дисциплины.
final displaySettingsForDisciplineProvider = Provider.family<DisplaySettings, String>((ref, disciplineId) {
  final disciplines = ref.watch(disciplineConfigsProvider);
  final discipline = disciplines.where((d) => d.id == disciplineId).firstOrNull;
  return discipline?.displaySettings ?? const DisplaySettings();
});

// ─────────────────────────────────────────────────────────────────
// PARTICIPANTS PROVIDER
// ─────────────────────────────────────────────────────────────────

/// Управление списком участников мероприятия.
class ParticipantsNotifier extends Notifier<List<Participant>> {
  final _storage = ParticipantsStorage();

  @override
  List<Participant> build() {
    _loadSaved();
    return []; // Пустой список по умолчанию; данные из storage загрузятся асинхронно
  }

  Future<void> _loadSaved() async {
    final saved = await _storage.load();
    if (saved != null) {
      state = saved;
    }
  }

  void _save() {
    _storage.save(state);
  }

  /// Очистить всех участников (в том числе демо).
  void clearAll() {
    state = [];
    _storage.clear();
  }

  /// Добавить участника.
  void add(Participant p) {
    state = [...state, p];
    _save();
  }

  /// Добавить список участников (batch — одна запись на диск).
  void addAll(List<Participant> participants) {
    state = [...state, ...participants];
    _save();
  }

  /// Удалить участника.
  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  /// Обновить участника.
  void update(String id, Participant Function(Participant) updater) {
    state = state.map((p) => p.id == id ? updater(p) : p).toList();
    _save();
  }

  /// Подтвердить заявку.
  void approve(String id) {
    update(id, (p) => p.copyWith(applicationStatus: ApplicationStatus.approved));
  }

  /// Отметить как оплаченного.
  void markPaid(String id) {
    update(id, (p) => p.copyWith(paymentStatus: PaymentStatus.paid));
  }

  /// Установить статус мандатной комиссии.
  void setMandateStatus(String id, MandateStatus status) {
    update(id, (p) => p.copyWith(mandateStatus: status));
  }

  /// Установить статус ветконтроля.
  void setVetStatus(String id, VetStatus status) {
    update(id, (p) => p.copyWith(vetStatus: status));
  }

  /// Массовое обновление нескольких участников.
  void bulkUpdate(Set<String> ids, Participant Function(Participant) updater) {
    state = state.map((p) => ids.contains(p.id) ? updater(p) : p).toList();
    _save();
  }

  /// Массовое удаление.
  void bulkRemove(Set<String> ids) {
    state = state.where((p) => !ids.contains(p.id)).toList();
    _save();
  }

  /// Переключить чек-ин (прибытие).
  void toggleCheckIn(String id) {
    final p = state.firstWhere((p) => p.id == id);
    if (p.checkInTime != null) {
      update(id, (p) => p.copyWith(clearCheckInTime: true));
    } else {
      update(id, (p) => p.copyWith(checkInTime: DateTime.now()));
    }
  }
}

final participantsProvider = NotifierProvider<ParticipantsNotifier, List<Participant>>(
  ParticipantsNotifier.new,
);


// ─────────────────────────────────────────────────────────────────
// DEMO DATA
// ─────────────────────────────────────────────────────────────────

/// Демо-мероприятие: Чемпионат Урала 2026.
EventConfig _demoEvent() {
  return EventConfig(
    id: 'evt-1',
    name: 'Чемпионат Урала 2026',
    startDate: DateTime(2026, 3, 15),
    endDate: DateTime(2026, 3, 16),
    location: 'Екатеринбург, Шарташ',
    description: 'Официальный чемпионат Уральского Федерального Округа по ездовому спорту. Зимние дисциплины: скиджоринг, нарты, каникросс, трейл.',
    contactInfo: '+7 (912) 345-67-89, org@sportos.live',
    status: EventStatus.draft,
    isMultiDay: true,
    scoringMode: ScoringMode.cumulative,
    dnfDayPolicy: DayPolicy.penalized,
    dsqDayPolicy: DayPolicy.strict,
    bibDayPolicy: BibDayPolicy.keep,
    days: [
      RaceDay(
        dayNumber: 1,
        date: DateTime(2026, 3, 15),
        disciplineIds: ['d-skijor-6', 'd-skijor-20', 'd-sled2-15', 'd-canicross-3'],
        startOrder: StartOrder.draw,
        startTime: const TimeOfDay(hour: 10, minute: 0),
      ),
      RaceDay(
        dayNumber: 2,
        date: DateTime(2026, 3, 16),
        disciplineIds: ['d-skijor2-40', 'd-sled4-20', 'd-trail-10'],
        startOrder: StartOrder.reverse,
        startTime: const TimeOfDay(hour: 10, minute: 0),
      ),
    ],
    courses: [
      const Course(
        id: 'course-small',
        name: 'Малый круг',
        distanceKm: 3.0,
        description: 'Лёгкая трасса вокруг озера',
        checkpoints: [
          CheckpointDef(id: 'cp-s1', name: 'Берёзовая роща', distanceKm: 1.0, order: 1),
          CheckpointDef(id: 'cp-s2', name: 'Мост', distanceKm: 2.0, order: 2),
        ],
      ),
      const Course(
        id: 'course-medium',
        name: 'Средний круг',
        distanceKm: 5.0,
        description: 'Средняя трасса с подъёмом',
        checkpoints: [
          CheckpointDef(id: 'cp-m1', name: 'Подъём', distanceKm: 2.0, order: 1),
          CheckpointDef(id: 'cp-m2', name: 'Перевал', distanceKm: 3.5, order: 2),
        ],
      ),
      const Course(
        id: 'course-large',
        name: 'Большой круг',
        distanceKm: 10.0,
        elevationGainM: 350,
        description: 'Трейл с набором высоты',
        checkpoints: [
          CheckpointDef(id: 'cp-l1', name: 'Лесной подъём', distanceKm: 3.0, order: 1),
          CheckpointDef(id: 'cp-l2', name: 'Хребет', distanceKm: 6.0, order: 2),
          CheckpointDef(id: 'cp-l3', name: 'Спуск', distanceKm: 8.5, order: 3),
        ],
      ),
    ],
  );
}

/// Демо-дисциплины (из doc-20, «Чемпионат Урала 2026»).
List<DisciplineConfig> _demoDisciplines() {
  final day1 = DateTime(2026, 3, 15, 10, 0);
  final day2 = DateTime(2026, 3, 16, 10, 0);

  return [
    DisciplineConfig(
      id: 'd-skijor-6',
      name: 'Скиджоринг (1 соб.)',
      distanceKm: 6.0,
      lapLengthM: 3000,
      laps: 2,
      startType: StartType.individual,
      interval: const Duration(seconds: 30),
      firstStartTime: day1,
      cutoffTime: const Duration(hours: 2),
      categories: const ['М', 'Ж', 'Юн', 'Юнк', 'M35', 'M40'],
      priceRub: 2500,
      courseId: 'course-small',
      dayNumber: 1,
    ),
    DisciplineConfig(
      id: 'd-skijor-20',
      name: 'Скиджоринг (1 соб.)',
      distanceKm: 20.0,
      lapLengthM: 5000,
      laps: 4,
      startType: StartType.individual,
      interval: const Duration(seconds: 60),
      firstStartTime: day1.add(const Duration(hours: 2)),
      cutoffTime: const Duration(hours: 4),
      categories: const ['М', 'Ж', 'M35', 'F35'],
      priceRub: 3500,
      courseId: 'course-medium',
      dayNumber: 1,
    ),
    DisciplineConfig(
      id: 'd-skijor2-40',
      name: 'Скиджоринг (2 соб.)',
      distanceKm: 40.0,
      lapLengthM: 5000,
      laps: 8,
      startType: StartType.individual,
      interval: const Duration(seconds: 90),
      firstStartTime: day2,
      cutoffTime: const Duration(hours: 6),
      categories: const ['М', 'Ж'],
      priceRub: 4000,
      courseId: 'course-medium',
      dayNumber: 2,
    ),
    DisciplineConfig(
      id: 'd-sled2-15',
      name: 'Нарты (2 соб.)',
      distanceKm: 15.0,
      lapLengthM: 5000,
      laps: 3,
      startType: StartType.individual,
      interval: const Duration(seconds: 90),
      firstStartTime: day1.add(const Duration(hours: 4, minutes: 30)),
      cutoffTime: const Duration(hours: 4),
      categories: const ['М', 'Ж', 'Юн', 'Юнк'],
      priceRub: 3000,
      courseId: 'course-medium',
      dayNumber: 1,
    ),
    DisciplineConfig(
      id: 'd-sled4-20',
      name: 'Нарты (4 соб.)',
      distanceKm: 20.0,
      lapLengthM: 5000,
      laps: 4,
      startType: StartType.individual,
      interval: const Duration(seconds: 120),
      firstStartTime: day2.add(const Duration(hours: 3)),
      cutoffTime: const Duration(hours: 5),
      categories: const ['М', 'Ж'],
      priceRub: 3500,
      courseId: 'course-medium',
      dayNumber: 2,
    ),
    DisciplineConfig(
      id: 'd-canicross-3',
      name: 'Каникросс',
      distanceKm: 3.0,
      lapLengthM: 3000,
      laps: 1,
      startType: StartType.mass,
      firstStartTime: day1.add(const Duration(hours: 7)),
      cutoffTime: const Duration(hours: 1),
      categories: const ['М', 'Ж', 'Дети', 'M40', 'F40'],
      priceRub: 1500,
      courseId: 'course-small',
      dayNumber: 1,
    ),
    DisciplineConfig(
      id: 'd-trail-10',
      name: 'Трейл (до 21 км)',
      distanceKm: 10.0,
      lapLengthM: 10000,
      laps: 1,
      startType: StartType.mass,
      firstStartTime: day2.add(const Duration(hours: 6)),
      cutoffTime: const Duration(hours: 3),
      categories: const ['М', 'Ж', 'M35', 'F35'],
      priceRub: 2000,
      courseId: 'course-large',
      dayNumber: 2,
      displaySettings: const DisplaySettings(
        showSpeed: true,
        showPace: true,
        showDogNames: false,
      ),
    ),
  ];
}

# Документирование кода

## Документация (`///`)
- Оформляется над объектом с `///`.
- **Обязательна** для всех: классов, конструкторов, публичных полей, методов, провайдеров.
- Краткая, ёмкая, указывает назначение.

### Шаблоны
- **Классы**: `{@template name}` / `{@endtemplate}`.
- **Конструкторы**: `{@macro name}` если один.
- **Параметры**: ссылки `[paramName]`.

### Пример Entity
```dart
/// {@template timing_record}
/// Запись хронометража одного участника.
///
/// Содержит отметки [startTime] и [finishTime],
/// из которых вычисляется [duration].
/// {@endtemplate}
class TimingRecord {
  /// {@macro timing_record}
  const TimingRecord({
    required this.bib,
    required this.startTime,
    this.finishTime,
  });

  /// Номер нагрудника участника.
  final int bib;

  /// Время старта (UTC).
  final DateTime startTime;

  /// Время финиша. Null если ещё не финишировал.
  final DateTime? finishTime;

  /// Вычисляемая длительность. Null если не финишировал.
  Duration? get duration =>
      finishTime != null ? finishTime!.difference(startTime) : null;
}
```

### Пример Riverpod-провайдера
```dart
/// Провайдер списка записей хронометража для текущего мероприятия.
///
/// Автоматически обновляется при изменениях в [ITimingRepository].
/// Использует [autoDispose] — данные освобождаются когда экран закрыт.
@riverpod
Future<List<TimingRecord>> timingRecords(TimingRecordsRef ref) async {
  final repo = ref.watch(timingRepositoryProvider);
  return repo.fetchAll();
}
```

## Комментарии (`//`)
- Только для неочевидного кода.
- НЕ дублировать то, что понятно из имён.

```dart
// ✅ Хорошо
// Используем UTC чтобы избежать проблем с часовыми поясами на трассе
final now = DateTime.now().toUtc();

// ❌ Плохо
// Получаем текущее время
final now = DateTime.now();
```

## TODO
- Формат: `// TODO(имя): описание [ISSUE-номер]`
- Указывать имя разработчика.
- Ссылка на задачу, если известна.

```dart
// TODO(alex): Добавить offline-queue для синхронизации [SPORT-42]
```

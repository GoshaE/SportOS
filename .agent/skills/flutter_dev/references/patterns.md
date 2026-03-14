# Паттерны и рецепты (Cookbook)

Готовые решения для типовых задач. Каждый рецепт — copy-paste шаблон.

---

## 1. Создать новый экран

```dart
// presentation/screens/my_feature_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран [описание назначения].
class MyFeatureScreen extends ConsumerWidget {
  const MyFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myFeatureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Заголовок')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Ошибка: $e')),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) => ListTile(title: Text(items[i].name)),
        ),
      ),
    );
  }
}
```

**Checklist при создании экрана:**
1. Файл в `presentation/screens/`, постфикс `Screen`.
2. Наследовать `ConsumerWidget` (или `ConsumerStatefulWidget` если нужен `initState`).
3. Добавить маршрут в `router.dart`.
4. Добавить `///` документацию.

---

## 2. Создать Riverpod-провайдер (с code-gen)

```dart
// domain/provider/timing_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entity/timing_record.dart';
import '../repository/i_timing_repository.dart';

part 'timing_providers.g.dart';

/// Список записей хронометража. Автоматически обновляется из БД.
@riverpod
class TimingNotifier extends _$TimingNotifier {
  @override
  Future<List<TimingRecord>> build() async {
    final repo = ref.watch(timingRepositoryProvider);
    return repo.fetchAll();
  }

  /// Добавить запись финиша для участника [bib].
  Future<void> recordFinish(int bib) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(timingRepositoryProvider);
      await repo.saveFinish(bib: bib, time: DateTime.now().toUtc());
      return repo.fetchAll();
    });
  }
}
```

**После создания:** запустить `dart run build_runner build --delete-conflicting-outputs`.

---

## 3. Создать Riverpod-провайдер (без code-gen)

```dart
// Простой провайдер для чтения данных
final timingRecordsProvider = FutureProvider.autoDispose<List<TimingRecord>>((ref) async {
  final repo = ref.watch(timingRepositoryProvider);
  return repo.fetchAll();
});

// Провайдер с параметром
final timingByBibProvider = FutureProvider.autoDispose.family<TimingRecord?, int>((ref, bib) async {
  final repo = ref.watch(timingRepositoryProvider);
  return repo.findByBib(bib);
});
```

---

## 4. Создать Entity (Freezed)

```dart
// domain/entity/timing_record.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'timing_record.freezed.dart';
part 'timing_record.g.dart';

/// {@template timing_record}
/// Запись хронометража участника.
/// {@endtemplate}
@freezed
class TimingRecord with _$TimingRecord {
  /// {@macro timing_record}
  const factory TimingRecord({
    required String id,
    required int bib,
    required DateTime startTime,
    DateTime? finishTime,
    @Default(false) bool synced,
  }) = _TimingRecord;

  factory TimingRecord.fromJson(Map<String, dynamic> json) =>
      _$TimingRecordFromJson(json);
}
```

---

## 5. Создать Repository (Offline-first)

```dart
// domain/repository/i_timing_repository.dart
abstract class ITimingRepository {
  Future<List<TimingRecord>> fetchAll();
  Future<void> saveFinish({required int bib, required DateTime time});
  Stream<List<TimingRecord>> watchAll();
}

// data/repository/timing_repository.dart
class TimingRepository implements ITimingRepository {
  final AppDatabase _db;    // Drift
  final Dio _dio;           // API
  final SyncQueue _queue;   // Очередь синхронизации

  TimingRepository(this._db, this._dio, this._queue);

  @override
  Future<List<TimingRecord>> fetchAll() async {
    final rows = await _db.select(_db.timingRecords).get();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<void> saveFinish({required int bib, required DateTime time}) async {
    // 1. Локально (мгновенно)
    await _db.into(_db.timingRecords).insertOnConflictUpdate(
      TimingRecordsCompanion(bib: Value(bib), finishTime: Value(time)),
    );
    // 2. В очередь синхронизации (фоново)
    _queue.enqueue('timing_records', {'bib': bib, 'finish_time': time.toIso8601String()});
  }

  @override
  Stream<List<TimingRecord>> watchAll() {
    return _db.select(_db.timingRecords).watch().map(
      (rows) => rows.map((r) => r.toEntity()).toList(),
    );
  }
}
```

---

## 6. Гранулярный ребилд (оптимизация)

```dart
// ❌ Плохо: весь виджет пересобирается при любом изменении
final allData = ref.watch(timingNotifierProvider);

// ✅ Хорошо: пересобирается только при смене количества записей
final count = ref.watch(
  timingNotifierProvider.select((data) => data.valueOrNull?.length ?? 0),
);
```

---

## 7. Навигация (GoRouter)

```dart
// Перейти вперёд
context.go('/ops/$eventId/dash');

// Вернуться назад
context.pop();

// Перейти с заменой (без кнопки "назад")
context.go('/hub');

// Получить параметры маршрута
final eventId = GoRouterState.of(context).pathParameters['eventId']!;
```

---

## 8. Показать ошибку пользователю

```dart
// Snackbar для некритичных ошибок
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Нет подключения. Данные сохранены локально'),
    action: SnackBarAction(label: 'OK', onPressed: () {}),
  ),
);

// Dialog для критичных ошибок
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Ошибка синхронизации'),
    content: const Text('Конфликт данных на финишном посту. Проверьте вручную.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
    ],
  ),
);
```

---

## 9. Добавить маршрут в router.dart

```dart
// 1. Импортировать экран
import '../features/timing/presentation/screens/finish_screen.dart';

// 2. Добавить GoRoute в нужное место
GoRoute(
  path: '/ops/:eventId/timing/finish',
  name: 'ops-finish',
  builder: (context, state) => const FinishScreen(),
),
```

---

## 10. Drift: создать таблицу

```dart
// data/tables/timing_records_table.dart

class TimingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bib => integer()();
  TextColumn get eventId => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get finishTime => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

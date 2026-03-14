# Обработка ошибок

Единый подход к ошибкам во всём приложении.

## Принцип: Три уровня серьёзности

| Уровень | Когда | Как показать | Пример |
|---|---|---|---|
| 🟢 **Info** | Мягкое уведомление | Snackbar (3 сек) | "Данные сохранены локально" |
| 🟡 **Warning** | Нужно внимание, но не блокирует | Snackbar + action | "Нет сети. Синхронизация позже" |
| 🔴 **Error** | Блокирует действие | Dialog | "Конфликт данных. Проверьте." |

## AsyncValue — основа обработки в Riverpod

Все провайдеры возвращают `AsyncValue<T>` — он содержит три состояния:

```dart
data.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
  data: (items) => ItemsList(items: items),
);
```

### Важно: не теряйте предыдущие данные при обновлении

```dart
// ✅ Хорошо: показываем старые данные + индикатор обновления
data.when(
  skipLoadingOnRefresh: true, // НЕ показывать loading при refresh
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => ErrorBanner(message: '$e'),
  data: (items) => ItemsList(items: items),
);
```

## Паттерн: AsyncValue.guard

```dart
Future<void> saveRecord() async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(() async {
    await repository.save(record);
    return repository.fetchAll();
  });
}
```

`AsyncValue.guard` автоматически ловит исключения и оборачивает в `AsyncValue.error`.

## Offline-ошибки

Приложение **не должно падать** без сети. Правила:

1. **Запись** → всегда сначала в Drift, потом в очередь.
2. **Чтение** → всегда из Drift. Если данных нет — показать placeholder.
3. **Синхронизация** → при ошибке сети — молча retry через N секунд.

```dart
// В Repository:
Future<void> syncToCloud(TimingRecord record) async {
  try {
    await _dio.post('/timing', data: record.toJson());
    await _db.markSynced(record.id);
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError) {
      // Нет сети — ничего не делаем, запись уже в sync_queue
      return;
    }
    rethrow; // Другие ошибки — пробрасываем
  }
}
```

## Валидация форм

```dart
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) return 'Обязательное поле';
    if (int.tryParse(value) == null) return 'Введите число';
    final bib = int.parse(value);
    if (bib < 1 || bib > 999) return 'BIB от 1 до 999';
    return null; // Валидно
  },
);
```

## Retry-логика (Dio Interceptor)

```dart
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor(this.dio, {this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.type == DioExceptionType.connectionError && _retryCount < maxRetries) {
      await Future.delayed(Duration(seconds: _retryCount * 2)); // Exponential backoff
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
      return;
    }
    handler.next(err);
  }
}
```

## Глобальный ErrorWidget

Для продакшна — заменить красный экран Flutter:

```dart
void main() {
  ErrorWidget.builder = (details) => Material(
    child: Center(
      child: Text('Что-то пошло не так', style: TextStyle(color: Colors.red)),
    ),
  );
  runApp(const ProviderScope(child: SportOsApp()));
}
```

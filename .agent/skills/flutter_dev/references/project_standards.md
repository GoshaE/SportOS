# Стандарты проекта

## Технологический стек

| Категория | Пакет | Версия | Назначение |
|---|---|---|---|
| State & DI | `riverpod` + `riverpod_annotation` | ^3.x | Управление состоянием + Dependency Injection |
| Routing | `go_router` | ^17.x | Навигация, deep links, ShellRoute |
| Local DB | `drift` | ^2.x | Offline-first SQLite, type-safe queries, streams |
| Backend | `supabase_flutter` | ^2.x | Auth, Realtime, Postgres, Storage |
| HTTP | `dio` | ^5.x | Interceptors, retry, cancel |
| Models | `freezed` + `json_serializable` | latest | Immutable модели, toJson/fromJson |
| Background | `workmanager` | latest | Фоновая синхронизация |
| Fonts | `google_fonts` | ^8.x | Inter / Outfit |
| Code-gen | `build_runner` | latest | Генерация drift, freezed, riverpod |
| Lint | `very_good_analysis` | latest | Строгие правила анализа |

## Управление файлами

### Сгенерированные файлы (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`)
- **Хранить в репозитории**.
- Ветка `main` работает сразу после `git clone` без ожидания `build_runner`.
- Контролировать конфликты при merge.

### `pubspec.lock`
- **Хранить** для приложения.
- Гарантирует воспроизводимость сборки.

## Сборка и запуск

### Повседневная разработка
```bash
# Запуск (macOS / iOS / Android)
flutter run -d macos

# Code-gen (Drift, Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Анализ
flutter analyze

# Форматирование
dart format .

# Тесты
flutter test
```

### Перед PR (обязательно)
1. `dart format .`
2. `flutter analyze` — 0 ошибок, 0 warnings.
3. `flutter test` — все тесты зелёные.

## Offline-first принципы

SportOS работает на трассе без интернета. Ключевые правила:

1. **Drift — источник истины**. UI читает данные из локальной БД, не из API.
2. **Write locally first**. Запись всегда идёт сначала в Drift, потом синхронизируется в Supabase.
3. **Conflict resolution**. При конфликтах: last-write-wins + логирование конфликтов.
4. **Pending queue**. Неотправленные записи хранятся в таблице `sync_queue`, отправляются при появлении сети.

```dart
// ✅ Правильно: записываем локально, синхронизируем фоново
Future<void> saveTimingRecord(TimingRecord record) async {
  await _drift.insertRecord(record.toCompanion());  // 1. Локально
  _syncQueue.enqueue(SyncAction.upsert, 'timing_records', record.toJson());  // 2. В очередь
}

// ❌ Неправильно: ждём API, падаем без сети
Future<void> saveTimingRecord(TimingRecord record) async {
  await _dio.post('/timing', data: record.toJson());  // Упадёт offline!
}
```

## Производительность и батарея

1. **`const`** — помечать все stateless виджеты. Flutter пропускает их при rebuild.
2. **`autoDispose`** — Riverpod автоматически убивает провайдеры закрытых экранов.
3. **`select()`** — подписка на конкретное поле, не на весь объект.
4. **`RepaintBoundary`** — изолировать тяжёлые виджеты (карта, таймер).
5. **GPS** — включать только при необходимости, background = интервальный (30с).
6. **WebSocket** — только в Ops-режиме. Участники = polling 30с.

## macOS Entitlements

Для работы на macOS необходимы в `DebugProfile.entitlements` и `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

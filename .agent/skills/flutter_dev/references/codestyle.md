# Правила именования и стиль кода

Придерживаемся **Effective Dart** и внутренних стандартов SportOS.

## Именование

### Интерфейсы
- Начинаются с заглавной **I**: `IAuthRepository`, `ITimingRepository`.
- Определяются в `domain/repository/`.

### Классы и файлы
- **Классы**: `UpperCamelCase`. Приватные — с `_`. Содержат тип в конце: `UserEntity`, `TimingRecordDto`.
- **Файлы**: `snake_case`. Формат: `[раздел]_[тип].dart`. Пример: `timing_record_entity.dart`.

### Репозитории
- Интерфейс: `ITimingRepository` (в `domain/`).
- Основная реализация: `TimingRepository` (в `data/`).
- Альтернативные: `TimingRepositoryMock`, `TimingRepositoryLocal`.

### Виджеты
- **Экраны**: Постфикс `Screen` → `StarterScreen`, `CheckInScreen`.
- **Контент экрана**: Постфикс `View` → `CheckInView`.
- **Глобальные виджеты**: Префикс `App` → `AppButton`, `AppCard`.
- **НЕ** использовать слово `Widget` в названии.

### Riverpod Провайдеры
- Используем `@riverpod` аннотацию для code-gen.
- Имя = описание данных + `Provider`: `timingRecordsProvider`, `currentUserProvider`.
- `Notifier`-классы: `TimingNotifier`, `AuthNotifier`.

## Методы и переменные
- **Методы**: начинаются с глагола (`fetch`, `update`, `delete`, `sync`). Без `And/Or`.
- **Переменные/Константы**: `lowerCamelCase`.

## Структура класса (порядок)
1. Конструкторы (default, named, factory).
2. Static элементы.
3. Инстанс-поля (final → обычные; public → private).
4. Геттеры / Сеттеры.
5. Методы (overridden → public → protected → private).

## Константы
- Помечайте `const` всё, что возможно — виджеты, конструкторы, списки.
- Это критично для производительности: Flutter пропускает `const`-виджеты при rebuild.

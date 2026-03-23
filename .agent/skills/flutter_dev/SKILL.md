---
name: flutter_dev
description: Скилл для разработки Flutter-приложения SportOS. Используйте при написании кода, создании фич, ревью и настройке архитектуры. Включает правила именования, структуру слоев (data/domain/presentation), стандарты Git, и технологический стек (Riverpod, Drift, Supabase, Dio).
---

# Flutter Dev Skill (SportOS)

Стандарты разработки Flutter-приложения SportOS, адаптированные из корпоративных правил Friflex под специфику проекта.

## Основные принципы

1. **Архитектура**: Clean Architecture — `data`, `domain`, `presentation` слои.
2. **State Management**: `Riverpod` (провайдеры + DI в одном пакете, autoDispose для батареи).
3. **Offline-first**: Локальная БД `Drift` (SQLite) — приложение работает без интернета.
4. **Именование**: Интерфейсы с `I`-префиксом. Экраны с `Screen`-постфиксом.
5. **Документация**: Весь публичный API покрыт `///`.
6. **Git**: Conventional Commits на русском.

## Технологический стек

| Слой | Технология |
|---|---|
| State & DI | `riverpod` + `riverpod_annotation` |
| Routing | `go_router` |
| Local DB | `drift` (SQLite, type-safe) |
| Backend | `supabase_flutter` (Auth, Realtime, Postgres) |
| HTTP | `dio` (interceptors, retry, offline queue) |
| Models | `freezed` + `json_serializable` |
| Background | `workmanager` |
| Lint | `very_good_analysis` |
| Fonts | `google_fonts` |

## Справочники (References)

### Архитектура и навигация
- [Обзор архитектуры](references/architecture_overview.md) — Mermaid-диаграммы системы, потоков данных и sync.
- [Карта экранов](references/screen_map.md) — Все 44 экрана с маршрутами и файлами.

### Стандарты кода
- [Правила именования и стиль кода](references/codestyle.md) — Классы, файлы, провайдеры, const.
- [Структура проекта и слои](references/project_structure.md) — Clean Architecture, feature-модули, Riverpod.
- [Документирование кода](references/documentation.md) — `///`, шаблоны, TODO.
- [Работа с Git и ветками](references/gitflow.md) — Conventional Commits, ветки, PR.
- [Стандарты проекта и сборка](references/project_standards.md) — Стек, offline-first, батарея.

### Практические руководства
- [Паттерны и рецепты](references/patterns.md) — 10 copy-paste шаблонов для типовых задач.
- [Продвинутые паттерны](references/advanced_patterns.md) — World-class: Slivers, кеширование, пагинация, анимации, responsive.
- [Продвинутые паттерны II](references/advanced_patterns_2.md) — Формы, тема, auth guards, тесты, NFC, миграции, i18n.
- [Обработка ошибок](references/error_handling.md) — AsyncValue, offline, retry, валидация.
- [Web Release паттерны](references/web_release_patterns.md) — dart2js подводные камни, CanvasKit ограничения, безопасные паттерны для web.

### Предметная область и дизайн
- [Глоссарий](references/glossary.md) — 35+ терминов ездового спорта и системы.
- [Дизайн-система](references/design_system.md) — Цвета, типографика, готовые виджеты.
- [UI Компоненты (Атомы)](references/ui_components.md) — Полный каталог переиспользуемых виджетов и паттернов (кнопки, аватары, карточки, бейджи).

## Remote Config (обновления без App Store)

SportOS использует **Supabase Remote Config** ($0) для управления фичами без обновления:

```dart
// Supabase таблица: app_config (key TEXT PRIMARY KEY, value JSONB)
// Riverpod провайдер:
@riverpod
Future<AppConfig> appConfig(AppConfigRef ref) async {
  final data = await Supabase.instance.client.from('app_config').select();
  return AppConfig.fromRows(data);
}

// Использование: ref.watch(appConfigProvider).value?.featureEnabled('gps_map')
```

**Что можно менять**: feature flags, force update (`min_version`), maintenance mode, тексты, лимиты.  
**Что нельзя**: новые экраны, логику UI, навигацию (нужен App Store).  
**Не используем**: Shorebird, Firebase, Server-Driven UI — overengineering для нашего масштаба.

## Когда использовать этот скилл

- При создании новых классов или файлов (проверка именования).
- При реализации новой feature (выбор структуры папок).
- При подключении нового провайдера или репозитория (проверка слоёв).
- Перед созданием Pull Request (соответствие стандартам).
- При вопросах по архитектурному взаимодействию слоев.

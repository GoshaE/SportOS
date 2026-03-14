# Структура проекта

Проект построен на **Clean Architecture** с feature-модулями.

## Общая иерархия

```
lib/
├── app/                   # Глобальные настройки, тема, роутер
│   ├── router.dart        # GoRouter конфигурация
│   └── app.dart           # MaterialApp.router
├── core/                  # Shared код (тема, виджеты, утилиты)
│   ├── theme/             # AppColors, AppTheme, AppTypography
│   ├── widgets/           # AppButton, AppCard, StatusBadge, OpsContextBanner
│   ├── constants/         # Глобальные константы
│   └── utils/             # Хелперы, расширения
├── di/                    # Провайдеры верхнего уровня (Riverpod)
│   └── app_providers.dart # supabaseProvider, dioProvider, driftProvider
├── features/              # Функциональные модули
│   ├── auth/
│   ├── events/
│   ├── timing/
│   ├── ops/
│   └── results/
├── ui/                    # Shells и layout-обёртки
│   └── shells/            # MainShell, OpsRootShell
└── gen/                   # Сгенерированный код (Drift, Freezed)
```

## Структура Feature-папки

Каждая фича делится на три слоя:

```
features/timing/
├── data/                  # Поставщик данных
│   ├── dto/               # TimingRecordDto — модели для API/JSON
│   └── repository/        # TimingRepository — реализация (Drift + Dio)
├── domain/                # Бизнес-логика
│   ├── entity/            # TimingRecord — чистая модель для UI
│   ├── repository/        # ITimingRepository — интерфейс
│   └── provider/          # Riverpod-провайдеры (timingProvider)
└── presentation/          # Представление
    ├── screens/           # StarterScreen, FinishScreen
    └── components/        # TimerWidget, BibInput (переиспользуемые внутри фичи)
```

## Правила взаимодействия слоёв

```
Presentation → Domain → Data
     ↓            ↓         ↓
  ref.watch    Entities   Drift + Dio
  (Provider)   (чистые)   (конкретные)
```

- **Data** → маппит DTO ↔ Entity. Не знает про UI.
- **Domain** → работает через интерфейсы (`IRepository`). Не знает про Drift или Dio.
- **Presentation** → подписывается на Riverpod-провайдеры. Не знает про Data.

### Зависимости
```dart
// ✅ Правильно: Presentation читает из Domain
final records = ref.watch(timingRecordsProvider);

// ❌ Неправильно: Presentation напрямую использует Data
final db = ref.watch(driftDatabaseProvider);
final records = db.select(db.timingRecords).get();
```

## Глобальные vs Локальные объекты

- **Глобальные** (используются в 2+ фичах): выносятся в `core/` или `di/`.
- **Локальные** (только внутри фичи): остаются инкапсулированными в папке фичи.

## Riverpod: организация провайдеров

```dart
// domain/provider/timing_providers.dart

@riverpod
class TimingNotifier extends _$TimingNotifier {
  @override
  Future<List<TimingRecord>> build() async {
    final repo = ref.watch(timingRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> addRecord(TimingRecord record) async {
    final repo = ref.read(timingRepositoryProvider);
    await repo.save(record);
    ref.invalidateSelf();
  }
}
```

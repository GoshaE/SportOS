# Продвинутые паттерны Flutter (World-Class)

Собрание лучших практик и паттернов от мировых разработчиков:
Google Flutter team, Andrea Bizzotto (codewithandrea.com), VGV (Very Good Ventures), Reso Coder.

---

## 1. Widget Decomposition — "Маленькие виджеты"

**Проблема**: Один Screen = 500+ строк, перестраивается целиком при любом изменении.

**Решение**: Разбивать на мелкие `const`-виджеты. Flutter пропускает `const`-поддерево целиком.

```dart
// ❌ Монолитный экран
class TimingScreen extends ConsumerWidget {
  Widget build(context, ref) {
    final data = ref.watch(timingProvider);
    return Column(children: [
      Text(data.eventName),           // Не меняется, но ребилдится!
      Text(data.currentTime),         // Меняется каждую секунду
      ListView(...),                  // Ребилдится целиком!
    ]);
  }
}

// ✅ Декомпозиция — каждый виджет обновляется независимо
class TimingScreen extends StatelessWidget {
  const TimingScreen({super.key});
  Widget build(context) => const Column(children: [
    EventHeader(),       // const → Flutter пропускает
    CurrentTimeDisplay(), // ConsumerWidget → обновляется сам
    ParticipantList(),   // ConsumerWidget → обновляется сам
  ]);
}

class CurrentTimeDisplay extends ConsumerWidget {
  const CurrentTimeDisplay({super.key});
  Widget build(context, ref) {
    // Подписка ТОЛЬКО на время — остальной UI не трогается
    final time = ref.watch(timingProvider.select((s) => s.currentTime));
    return Text(time);
  }
}
```

> **Правило**: если виджет > 100 строк — разбей. Если виджет не зависит от стейта — сделай `const`.

---

## 2. Riverpod: Кеширование и жизненный цикл

### autoDispose + keepAlive = умный кеш

```dart
@riverpod
class ParticipantList extends _$ParticipantList {
  @override
  Future<List<Participant>> build() async {
    // Данные живут 5 минут после ухода с экрана
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 5), link.close);
    ref.onDispose(timer.cancel);

    return ref.watch(participantRepositoryProvider).fetchAll();
  }
}
```

### Паттерн: Optimistic Update (мгновенный UI)

```dart
Future<void> checkIn(int bib) async {
  // 1. Мгновенно обновить UI (оптимистично)
  state = AsyncValue.data(
    state.value!.map((p) => p.bib == bib ? p.copyWith(checkedIn: true) : p).toList(),
  );

  // 2. Записать в БД (фоново)
  try {
    await ref.read(repositoryProvider).checkIn(bib);
  } catch (e) {
    // 3. Откатить если ошибка
    ref.invalidateSelf();
  }
}
```

### Паттерн: Debounce для поиска

```dart
@riverpod
Future<List<Participant>> searchParticipants(SearchParticipantsRef ref, String query) async {
  // Ждём 300мс после последнего нажатия
  await Future.delayed(const Duration(milliseconds: 300));

  // Если за это время ввели ещё символ — отменяем
  if (ref.state is AsyncLoading) return [];

  return ref.watch(participantRepositoryProvider).search(query);
}
```

---

## 3. CustomScrollView + Slivers — профессиональный скролл

**Зачем**: `ListView` + `shrinkWrap: true` = производительностная катастрофа.
 `CustomScrollView` + Slivers = ленивая отрисовка, sticky headers, parallax.

### Экран мероприятия — мировой стандарт

```dart
CustomScrollView(
  slivers: [
    // 1. Схлопывающийся хедер с обложкой
    SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Чемпионат Урала'),
        background: Image.network(event.coverUrl, fit: BoxFit.cover),
      ),
    ),

    // 2. Статус-баннер (обычный виджет в sliver-контейнере)
    SliverToBoxAdapter(
      child: StatusBanner(event: event),
    ),

    // 3. Sticky-заголовок секции
    SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate('Участники (${participants.length})'),
    ),

    // 4. Ленивый список участников (только видимые отрисовываются)
    SliverList.builder(
      itemCount: participants.length,
      itemBuilder: (ctx, i) => ParticipantTile(participant: participants[i]),
    ),

    // 5. Ещё одна секция
    SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate('Результаты'),
    ),

    SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemCount: results.length,
      itemBuilder: (ctx, i) => ResultCard(result: results[i]),
    ),
  ],
);
```

### SectionHeaderDelegate (переиспользуемый)

```dart
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _SectionHeaderDelegate(this.title);

  @override double get maxExtent => 48;
  @override double get minExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Theme.of(context).colorScheme.surface,
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  @override bool shouldRebuild(covariant _SectionHeaderDelegate old) => title != old.title;
}
```

---

## 4. Responsive Layout — адаптивная вёрстка

### Breakpoints (стандарт Material 3)

```dart
// core/utils/breakpoints.dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile &&
      MediaQuery.sizeOf(context).width < desktop;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
```

### Адаптивный Layout

```dart
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({super.key, required this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) return desktop!;
        if (constraints.maxWidth >= 600 && tablet != null) return tablet!;
        return mobile;
      },
    );
  }
}

// Использование:
AdaptiveLayout(
  mobile: const ParticipantListView(),         // Список
  tablet: const ParticipantGridView(columns: 2), // Сетка 2 колонки
  desktop: const ParticipantTableView(),        // Полноценная таблица
)
```

### Навигация: BottomBar → SideRail → SideDrawer

```dart
// В MainShell: автоматическое переключение навигации
@override
Widget build(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= 600;

  if (isWide) {
    return Row(children: [
      NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: destinations.map((d) =>
          NavigationRailDestination(icon: d.icon, label: Text(d.label)),
        ).toList(),
      ),
      const VerticalDivider(width: 1),
      Expanded(child: body),
    ]);
  }

  return Scaffold(
    body: body,
    bottomNavigationBar: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: destinations,
    ),
  );
}
```

---

## 5. Пагинация — бесконечный скролл

```dart
@riverpod
class PaginatedResults extends _$PaginatedResults {
  int _page = 0;
  bool _hasMore = true;

  @override
  Future<List<Result>> build() => _fetchPage(0);

  Future<List<Result>> _fetchPage(int page) async {
    final repo = ref.read(resultsRepositoryProvider);
    final newItems = await repo.fetchPage(page: page, limit: 20);
    _hasMore = newItems.length == 20;
    return [...?state.valueOrNull, ...newItems];
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    _page++;
    state = AsyncValue.data(await _fetchPage(_page));
  }
}

// В UI — NotificationListener для автоматической подгрузки
NotificationListener<ScrollNotification>(
  onNotification: (scroll) {
    if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
      ref.read(paginatedResultsProvider.notifier).loadMore();
    }
    return false;
  },
  child: ListView.builder(
    itemCount: items.length + (hasMore ? 1 : 0),
    itemBuilder: (ctx, i) {
      if (i == items.length) return const Center(child: CircularProgressIndicator());
      return ResultTile(result: items[i]);
    },
  ),
)
```

---

## 6. Анимации — micro-interactions

### Hero-переход (карточка → детальный экран)

```dart
// В списке
Hero(
  tag: 'participant-${p.bib}',
  child: CircleAvatar(backgroundImage: NetworkImage(p.avatarUrl)),
)

// На детальном экране
Hero(
  tag: 'participant-${p.bib}',
  child: CircleAvatar(radius: 48, backgroundImage: NetworkImage(p.avatarUrl)),
)
```

### AnimatedSwitcher (плавная смена контента)

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: isLoading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : ResultsList(key: const ValueKey('results'), items: items),
)
```

### Staggered List Animation (элементы появляются по очереди)

```dart
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
```

---

## 7. Offline-first: Repository + SyncQueue

### Полный offline-first паттерн

```dart
class TimingRepository implements ITimingRepository {
  final AppDatabase _db;
  final Dio _dio;

  // ЧТЕНИЕ — всегда из локальной БД (stream)
  @override
  Stream<List<TimingRecord>> watchAll() =>
      _db.select(_db.timingRecords).watch().map(
        (rows) => rows.map((r) => r.toEntity()).toList(),
      );

  // ЗАПИСЬ — локально + в очередь
  @override
  Future<void> save(TimingRecord record) async {
    await _db.into(_db.timingRecords).insertOnConflictUpdate(
      record.toCompanion(),
    );
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      table: const Value('timing_records'),
      recordId: Value(record.id),
      action: const Value('upsert'),
      payload: Value(jsonEncode(record.toJson())),
      createdAt: Value(DateTime.now().toUtc()),
    ));
  }

  // СИНХРОНИЗАЦИЯ — фоновая, с retry
  Future<void> syncPending() async {
    final pending = await (_db.select(_db.syncQueue)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        ..limit(50))
      .get();

    for (final item in pending) {
      try {
        await _dio.post('/sync/${item.table}', data: jsonDecode(item.payload));
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionError) break; // Нет сети → стоп
        rethrow;
      }
    }
  }
}
```

---

## 8. Performance Checklist

| # | Практика | Эффект |
|---|---|---|
| 1 | **`const` всё что можно** | Flutter пропускает целое поддерево |
| 2 | **`select()` в ref.watch** | Ребилд только при смене конкретного поля |
| 3 | **`ListView.builder` вместо `ListView`** | Ленивая отрисовка, экономия RAM |
| 4 | **`RepaintBoundary`** вокруг карты/таймера | Изоляция перерисовки тяжёлых виджетов |
| 5 | **`autoDispose`** в провайдерах | Автоматическое освобождение памяти |
| 6 | **Мелкие виджеты** (< 100 строк) | Точечный ребилд, читаемость |
| 7 | **`compute()`** для тяжёлых вычислений | UI-thread свободен, нет фризов |
| 8 | **`cached_network_image`** | Кеш изображений, меньше сетевых запросов |
| 9 | **Avoid `Opacity` widget** | Используй цвет с opacity вместо виджета |
| 10 | **`shrinkWrap: true` — ЗАПРЕЩЕНО** | Принуждает отрисовать ВСЁ сразу |

---

## 9. Compose, не наследуй

```dart
// ❌ Наследование — хрупко
class SpecialButton extends ElevatedButton { ... }

// ✅ Композиция — гибко
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonStyle style;

  const AppButton({required this.text, required this.onPressed, this.style = AppButtonStyle.primary});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: _resolveStyle(context),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

---

## 10. Extension Methods — чистые хелперы

```dart
// core/utils/context_extensions.dart
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  void showSnack(String message) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
}

// Использование:
Text('Привет', style: context.textTheme.headlineSmall);
if (context.isMobile) { ... }
context.showSnack('Сохранено!');
```

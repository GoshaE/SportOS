# 28. UI Deep Dive — Темы, модалки, навигация, отказоустойчивость

> Расширение [27-frontend-dev-guide.md](./27-frontend-dev-guide.md).
> Всё что нужно продумать **заранее**, чтобы потом не возвращаться.

---

## 0. Стандарт документирования кода

### 0.1 Заголовок файла (обязательный)

Каждый файл виджета/экрана **обязательно начинается** с блока документации:

```dart
/// ═══════════════════════════════════════════
/// Screen ID: R1 — Стартёр
/// ═══════════════════════════════════════════
///
/// Описание: Экран для хронометриста/стартёра.
///           Отправляет спортсменов на трассу.
///
/// Связи:
///   ← Откуда: CheckInScreen (P6), EventOverviewScreen (E1)
///   → Куда:   FinishScreen (R2), MarshalScreen (R3)
///
/// Данные:
///   - Читает: StartListProvider (стартовый лист)
///   - Пишет:  RaceLogProvider (запись стартов)
///
/// Бизнес-логика:
///   1. Показывает очередь по стартовому листу
///   2. Обратный отсчёт 3-2-1-GO при нажатии
///   3. Записывает точное время старта
///   4. Обновляет статус спортсмена: waiting → started
///   5. Поддерживает масс-старт (несколько BIB одновременно)
///
/// Особенности:
///   - Работает офлайн (все данные в Isar)
///   - Haptic feedback при старте (heavyImpact)
///   - Блокировка случайного выхода (PopScope)
/// ═══════════════════════════════════════════
```

### 0.2 Комментарии внутри кода

```dart
// ── Секция: визуальный разделитель блоков ──
// Используем для группировки виджетов внутри build()

// ── Таймер обратного отсчёта ──
// Логика: при нажатии START запускается countdown 3→2→1→GO.
// После GO записывается точное время в RaceLogProvider.
// Связь: время уходит на FinishScreen для расчёта результата.
Widget _buildCountdown() { ... }

// ── Масс-старт ──
// Бизнес-правило: при масс-старте все выбранные BIB получают
// одинаковое время старта. Используется в дисциплинах
// с общим стартом (нарты, каникросс).
Widget _buildMassStart() { ... }

// TODO(Phase2): Добавить GPS timestamp синхронизацию
// TODO(Phase3): Интеграция с аппаратным стартовым пистолетом
```

### 0.3 Правила документирования

| Что | Где | Формат |
|---|---|---|
| ID экрана и связи | Начало файла | `/// Screen ID: R1` |
| Откуда/Куда навигация | Начало файла | `/// ← Откуда: ...` / `/// → Куда: ...` |
| Какие данные читает/пишет | Начало файла | `/// Данные: - Читает: ...` |
| Бизнес-логика (шаги) | Начало файла | Нумерованный список |
| Секции в build() | Перед блоком | `// ── Название секции ──` |
| Сложная логика | Перед функцией | `// Логика: ... Связь: ...` |
| Будущие доработки | В коде | `// TODO(PhaseN): описание` |
| Почему так, а не иначе | В коде | `// Причина: ...` |

---

## 1. Система тем — shadcn-подход (ручные палитры)

> **НЕ используем** M3 `colorSchemeSeed` — он генерирует некрасивые палитры.
> Вместо этого **вручную задаём каждый цветовой слот**, как в [shadcn/ui](https://ui.shadcn.com/docs/theming).

### 1.1 Цветовые слоты

Каждая тема определяет конкретные значения для каждого слота:

| Слот | Назначение | Пример (Zinc Light) |
|---|---|---|
| `background` | Фон приложения | `#FAFAFA` |
| `foreground` | Основной текст | `#18181B` |
| `card` | Фон карточки | `#FFFFFF` |
| `cardForeground` | Текст на карточке | `#18181B` |
| `primary` | Акцентный цвет (кнопки, ссылки) | Задаётся пользователем |
| `primaryForeground` | Текст на primary | `#FAFAFA` |
| `secondary` | Второстепенные кнопки, чипы | `#F4F4F5` |
| `secondaryForeground` | Текст на secondary | `#18181B` |
| `muted` | Приглушённый фон (disabled, hint) | `#F4F4F5` |
| `mutedForeground` | Приглушённый текст | `#71717A` |
| `accent` | Hover, выделение | `#F4F4F5` |
| `accentForeground` | Текст на accent | `#18181B` |
| `destructive` | Ошибки, удаление | `#EF4444` |
| `destructiveForeground` | Текст на destructive | `#FAFAFA` |
| `border` | Границы, разделители | `#E4E4E7` |
| `input` | Граница инпутов | `#E4E4E7` |
| `ring` | Фокус-кольцо | `#A1A1AA` |

### 1.2 Базовые темы (base color)

Базовая тема задаёт **нейтральные** оттенки (серые). Primary цвет выбирается отдельно.

```dart
/// lib/app/theme_data.dart

class AppColorSlots {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  const AppColorSlots({required this.background, ...});
}
```

#### Тема: Zinc (деловая, нейтральная — по умолчанию)

```dart
// Light
const zincLight = AppColorSlots(
  background:           Color(0xFFFAFAFA),  // zinc-50
  foreground:           Color(0xFF18181B),  // zinc-900
  card:                 Color(0xFFFFFFFF),
  cardForeground:       Color(0xFF18181B),
  secondary:            Color(0xFFF4F4F5),  // zinc-100
  secondaryForeground:  Color(0xFF18181B),
  muted:                Color(0xFFF4F4F5),
  mutedForeground:      Color(0xFF71717A),  // zinc-500
  accent:               Color(0xFFF4F4F5),
  accentForeground:     Color(0xFF18181B),
  destructive:          Color(0xFFEF4444),
  destructiveForeground:Color(0xFFFAFAFA),
  border:               Color(0xFFE4E4E7),  // zinc-200
  input:                Color(0xFFE4E4E7),
  ring:                 Color(0xFFA1A1AA),  // zinc-400
  // primary задаётся отдельно!
);

// Dark
const zincDark = AppColorSlots(
  background:           Color(0xFF09090B),  // zinc-950
  foreground:           Color(0xFFFAFAFA),
  card:                 Color(0xFF18181B),  // zinc-900
  cardForeground:       Color(0xFFFAFAFA),
  secondary:            Color(0xFF27272A),  // zinc-800
  secondaryForeground:  Color(0xFFFAFAFA),
  muted:                Color(0xFF27272A),
  mutedForeground:      Color(0xFFA1A1AA),
  accent:               Color(0xFF27272A),
  accentForeground:     Color(0xFFFAFAFA),
  destructive:          Color(0xFF7F1D1D),
  destructiveForeground:Color(0xFFFAFAFA),
  border:               Color(0xFF27272A),
  input:                Color(0xFF27272A),
  ring:                 Color(0xFF52525B),  // zinc-600
);
```

#### Тема: Stone (тёплая, уютная)

```dart
const stoneLight = AppColorSlots(
  background:           Color(0xFFFAFAF9),  // stone-50
  foreground:           Color(0xFF1C1917),  // stone-900
  card:                 Color(0xFFFFFFFF),
  muted:                Color(0xFFF5F5F4),  // stone-100
  mutedForeground:      Color(0xFF78716C),  // stone-500
  border:               Color(0xFFE7E5E4),  // stone-200
  // ...
);

const stoneDark = AppColorSlots(
  background:           Color(0xFF0C0A09),  // stone-950
  foreground:           Color(0xFFFAFAF9),
  card:                 Color(0xFF1C1917),
  muted:                Color(0xFF292524),  // stone-800
  mutedForeground:      Color(0xFFA8A29E),
  border:               Color(0xFF292524),
  // ...
);
```

#### Тема: Slate (холодная, техническая)

```dart
const slateLight = AppColorSlots(
  background:           Color(0xFFF8FAFC),  // slate-50
  foreground:           Color(0xFF0F172A),  // slate-900
  muted:                Color(0xFFF1F5F9),  // slate-100
  mutedForeground:      Color(0xFF64748B),  // slate-500
  border:               Color(0xFFE2E8F0),  // slate-200
  // ...
);
```

#### Тема: Neutral (чисто серая)

```dart
const neutralLight = AppColorSlots(
  background:           Color(0xFFFAFAFA),  // neutral-50
  foreground:           Color(0xFF171717),  // neutral-900
  muted:                Color(0xFFF5F5F5),  // neutral-100
  mutedForeground:      Color(0xFF737373),  // neutral-500
  border:               Color(0xFFE5E5E5),  // neutral-200
  // ...
);
```

### 1.3 Primary цвета (акцент — выбирает пользователь)

Отдельно от базовой темы пользователь выбирает **primary** цвет:

```dart
/// Акцентные пресеты
abstract class PrimaryColors {
  static const forest    = PrimaryPreset(name: 'Лес',     light: Color(0xFF16A34A), dark: Color(0xFF22C55E));  // green
  static const ocean     = PrimaryPreset(name: 'Океан',   light: Color(0xFF2563EB), dark: Color(0xFF3B82F6));  // blue
  static const sunset    = PrimaryPreset(name: 'Закат',   light: Color(0xFFEA580C), dark: Color(0xFFF97316));  // orange
  static const violet    = PrimaryPreset(name: 'Фиолет',  light: Color(0xFF7C3AED), dark: Color(0xFF8B5CF6));  // violet
  static const rose      = PrimaryPreset(name: 'Роза',    light: Color(0xFFE11D48), dark: Color(0xFFFB7185));  // rose
  static const zinc      = PrimaryPreset(name: 'Цинк',    light: Color(0xFF18181B), dark: Color(0xFFFAFAFA));  // zinc (деловой)
}

class PrimaryPreset {
  final String name;
  final Color light;          // primary для светлой темы
  final Color dark;           // primary для тёмной темы
  Color get lightForeground => Color(0xFFFAFAFA); // текст на primary (светлый)
  Color get darkForeground  => Color(0xFF18181B); // текст на primary (тёмный)
}
```

### 1.4 Итого: пользователь выбирает 3 вещи

```
Настройки → Оформление
  ├── 1. Яркость: [☀️ Светлая] [🌙 Тёмная] [📱 Системная]
  ├── 2. Базовая тема: [Zinc] [Stone] [Slate] [Neutral]
  └── 3. Акцент (primary): [🌲Лес] [🌊Океан] [🌅Закат] [💜Фиолет] [🌹Роза] [⚙️Цинк]
```

Итого: 4 базы × 6 акцентов × 2 яркости = **48 комбинаций** из 12 пресетов. Добавить новые — просто.

### 1.5 Как применять в коде

```dart
// ✅ ПРАВИЛЬНО — через слоты темы
Container(
  color: theme.card,
  child: Text('Текст', style: TextStyle(color: theme.cardForeground)),
)

FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: theme.primary,
    foregroundColor: theme.primaryForeground,
  ),
)

Container(
  decoration: BoxDecoration(
    border: Border.all(color: theme.border),
    borderRadius: BorderRadius.circular(12),
  ),
)

// ❌ НЕПРАВИЛЬНО
Container(color: Colors.grey.shade100)  // Не адаптируется к теме!
Text(style: TextStyle(color: Colors.black))  // Сломается в dark mode!
```

---

## 2. Семантические цвета (не зависят от темы)

```dart
/// lib/app/semantic_colors.dart
///
/// Эти цвета НЕ меняются от пресета — они имеют фиксированный смысл.
/// Но они адаптируются к яркости (light/dark) через opacity.

abstract class SemanticColors {
  // ── Статусы спортсмена ──
  static const finished  = Color(0xFF4CAF50); // зелёный
  static const onTrack   = Color(0xFF2196F3); // синий
  static const waiting   = Color(0xFF9E9E9E); // серый
  static const dns       = Color(0xFFF44336); // красный
  static const dnf       = Color(0xFFFF9800); // оранжевый
  static const dsq       = Color(0xFF9C27B0); // фиолетовый

  // ── Оплата ──
  static const paid      = Color(0xFF4CAF50);
  static const pending   = Color(0xFFFF9800);
  static const overdue   = Color(0xFFF44336);

  // ── Пол / Категория ──
  static const male      = Color(0xFF2196F3);
  static const female    = Color(0xFFE91E63);

  // ── Роли ──
  static const organizer = Color(0xFFFF9800);
  static const judge     = Color(0xFF9C27B0);
  static const marshal   = Color(0xFFFF5722);
  static const volunteer = Color(0xFF607D8B);

  // ── Система ──
  static const online    = Color(0xFF4CAF50);
  static const offline   = Color(0xFF9E9E9E);
  static const synced    = Color(0xFF4CAF50);
  static const syncing   = Color(0xFFFF9800);
  static const noSync    = Color(0xFFF44336);

  // ── Медали ──
  static const gold      = Color(0xFFFFD700);
  static const silver    = Color(0xFFC0C0C0);
  static const bronze    = Color(0xFFCD7F32);

  /// Адаптировать к фону: на тёмной теме background полупрозрачный
  static Color bg(Color c, Brightness brightness) {
    return c.withOpacity(brightness == Brightness.dark ? 0.15 : 0.08);
  }
}
```

---

## 3. Модальные окна — стратегия

### 3.1 Типы модалок

| Тип | Когда | Компонент Flutter | Закрытие |
|---|---|---|---|
| **BottomSheet** | Выбор из списка, фильтры, быстрые действия | `showModalBottomSheet` | Свайп / крестик |
| **FullScreenSheet** | Формы, визарды, сложные настройки | `showModalBottomSheet` (full height) | Крестик / «Отмена» |
| **Dialog** | Подтверждение, ошибка, PIN-код | `showDialog` / `AlertDialog` | Кнопки «Да/Нет» |
| **Snackbar** | Уведомление о действии (сохранено, удалено) | `ScaffoldMessenger` | Авто-скрытие 3с |
| **Banner** | Предупреждение на экране (нет сети, не сохранено) | `MaterialBanner` | «Закрыть» / «Повторить» |

### 3.2 Правила

```dart
// ── BottomSheet (стандарт) ──
// Используем DraggableScrollableSheet для длинного контента
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // ОБЯЗАТЕЛЬНО для контроля высоты
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (ctx) => DraggableScrollableSheet(
    initialChildSize: 0.6,   // 60% экрана
    minChildSize: 0.3,        // мин 30%
    maxChildSize: 0.9,        // макс 90%
    expand: false,
    builder: (ctx, scroll) => ListView(
      controller: scroll,
      children: [
        // Хэндл (всегда первый элемент)
        Center(child: Container(
          width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        // ... контент
      ],
    ),
  ),
);

// ── Dialog (подтверждение) ──
// Компактный, 2-3 кнопки максимум
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    icon: const Icon(Icons.warning_amber, size: 48),
    title: const Text('Утвердить протокол?'),
    content: const Text('После утверждения изменения возможны только через протест.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
      FilledButton(onPressed: () { /* действие */ }, child: const Text('Утвердить')),
    ],
  ),
);

// ── Snackbar ──
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: const Text('✅ Сохранено'),
  duration: const Duration(seconds: 3),
  action: SnackBarAction(label: 'Отменить', onPressed: () { /* undo */ }),
));
```

### 3.3 Паттерн «Подтверждение опасного действия»

```
1. Действие «Удалить» → показать Dialog
2. Требовать ввод (например 'УДАЛИТЬ') для необратимых действий
3. Показать snackbar с 'Отменить' (undo buffer 5 секунд)
```

### 3.4 Модалки на разных экранах

| Ширина | BottomSheet | Dialog |
|---|---|---|
| Mobile (< 600) | Полная ширина, 60-90% высоты | Полная ширина с отступами |
| Tablet (600-900) | 70% ширины, по центру | 50% ширины |
| Desktop (> 900) | 400px max, по центру | 400px max |

```dart
// Адаптивная модалка
void showAdaptiveModal(BuildContext context, Widget content) {
  final width = MediaQuery.of(context).size.width;
  if (width > 900) {
    showDialog(context: context, builder: (_) => Dialog(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480), child: content,
    )));
  } else {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => content);
  }
}
```

---

## 4. Навигация — UX продуманность

### 4.1 Запоминание состояния вкладок

`go_router` с `StatefulShellRoute.indexedStack` **уже** сохраняет состояние каждой вкладки — когда переключаешься между табами, позиция скролла и открытый экран остаются. Это уже работает в нашем роутере.

```dart
// ✅ Уже настроено в router.dart:
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(routes: [...]), // Каждая ветка сохраняет стек
  ],
)
```

### 4.2 Глубокая навигация — возврат

**Проблема**: Зашёл в Manage → Team → назначил роль → как вернуться?

**Решение**: Breadcrumb-стиль + `context.go()` (не `push`)

```
Хаб ← Мероприятие ← Управление ← Команда
                                      ↑ back = /manage/:eventId
```

```dart
// Кнопка «Назад» всегда ведёт на КОНКРЕТНЫЙ маршрут, а не pop():
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.go('/manage/$eventId'), // НЕ context.pop()!
  ),
)
```

**Почему `go()` а не `pop()`?**
- `pop()` может вернуть непредсказуемо (если пользователь перешёл по deeplink)
- `go()` всегда ведёт туда, куда мы ожидаем

### 4.3 Ops-режим — изоляция

Экраны гонки (Стартёр, Финиш, Маршал) работают в отдельном `ShellRoute` (`OpsShell`). При входе в Ops-режим:
- Bottom navigation скрывается
- Нужен явный выход через `← Назад к управлению`
- Случайный свайп назад блокируется (`WillPopScope`)

```dart
// В OpsShell:
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) _showExitDialog(context);
  },
  child: child,
)
```

### 4.4 Deeplinks / push notifications

```
sportos://event/evt-123              → EventDetailScreen
sportos://event/evt-123/register     → RegisterWizard
sportos://manage/evt-123/team        → TeamScreen
sportos://results/evt-123/live       → LiveResults
sportos://club/club-1                → ClubProfile
```

go_router поддерживает это из коробки — каждый route есть URL.

### 4.5 Навигация — чеклист UX

- [ ] Каждый экран знает куда ведёт «Назад» (всегда `go()`)
- [ ] Табы запоминают состояние (IndexedStack ✅)
- [ ] Ops-режим изолирован (нет случайного выхода)
- [ ] Deeplinks работают для ключевых экранов  
- [ ] Breadcrumbs видны на desktop (опционально)
- [ ] Long lists сохраняют scroll position при возврате

---

## 5. Отказоустойчивость (Resilience)

### 5.1 Три уровня ошибок

| Уровень | Пример | Поведение |
|---|---|---|
| **Сеть** | Нет интернета, timeout | Banner «Офлайн», работаем с кешем |
| **API** | 500, невалидный JSON | Snackbar + retry button |
| **Логика** | Null, неожиданный enum | Fallback значение + лог |

### 5.2 Состояния данных

Каждый экран с данными должен обрабатывать **4 состояния**:

```dart
// Riverpod AsyncValue автоматически даёт:
ref.watch(dataProvider).when(
  loading: () => LoadingState(),   // shimmer / skeleton
  error: (e, st) => ErrorState(),   // ошибка + retry
  data: (data) {
    if (data.isEmpty) return EmptyState(); // пустой список
    return ContentState(data);              // данные
  },
);
```

### 5.3 Виджеты состояний

```dart
/// lib/ui/states/loading_state.dart
class LoadingState extends StatelessWidget {
  // Shimmer-скелетон: серые плашки мигают
  // Повторяет структуру контента (3-5 блоков)
}

/// lib/ui/states/error_state.dart
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  // Иконка ❌ + текст + кнопка «Повторить»
}

/// lib/ui/states/empty_state.dart
class EmptyState extends StatelessWidget {
  final String title;      // 'Нет участников'
  final String? subtitle;  // 'Добавьте первого участника'
  final Widget? action;    // кнопка 'Добавить'
  final String? emoji;     // '📭'
}

/// lib/ui/states/offline_banner.dart
class OfflineBanner extends StatelessWidget {
  // MaterialBanner: '📡 Нет подключения · Работаем офлайн'
  // Sticky top, автоматически скрывается при восстановлении сети
}
```

### 5.4 Оффлайн-режим

```
┌─────────────────────────────────┐
│ 📡 Нет подключения к серверу    │  ← OfflineBanner (sticky)
│ Данные актуальны на 18:30       │
└─────────────────────────────────┘
│ Обычный контент из кеша         │  ← Isar / local cache
│ ...                             │
│                                 │
│ [Синхронизировать]              │  ← Видна при восстановлении сети
└─────────────────────────────────┘
```

### 5.5 Правила

1. **Никогда не показывать пустой белый экран** → Loading / Error / Empty
2. **Retry всегда доступен** → кнопка «↻ Повторить» на ErrorState
3. **Snackbar для действий** → «Сохранено» / «Ошибка, повторить?»
4. **Banner для системных** → офлайн, синхронизация, обновление
5. **Оптимистичный UI** → показываем результат до ответа сервера, откатываем при ошибке
6. **Таймауты** → 10 секунд API, 30 секунд WebSocket reconnect

---

## 6. Ещё что стоит продумать заранее

### 6.1 Загрузка и скелетоны

```dart
// Skeleton повторяет структуру реального контента:
// - Card → серый прямоугольник с shimmer
// - Avatar → серый кружок
// - Text → серая полоска 60% ширины
// - Number → серая полоска 30% ширины

// Пакет: shimmer: ^3.0.0
Shimmer.fromColors(
  baseColor: Colors.grey.shade300,
  highlightColor: Colors.grey.shade100,
  child: Container(height: 20, width: 120, color: Colors.white),
)
```

### 6.2 Pull-to-refresh

```dart
// Все списочные экраны оборачиваем в RefreshIndicator:
RefreshIndicator(
  onRefresh: () async => ref.invalidate(dataProvider),
  child: ListView(...),
)
```

### 6.3 Пагинация

```dart
// Для длинных списков (участники, результаты, история):
// Infinite scroll с индикатором загрузки внизу
NotificationListener<ScrollNotification>(
  onNotification: (scroll) {
    if (scroll.metrics.pixels > scroll.metrics.maxScrollExtent - 200) {
      ref.read(dataProvider.notifier).loadMore();
    }
    return false;
  },
  child: ListView.builder(itemCount: items.length + 1, ...),
)
```

### 6.4 Формы — валидация

```dart
// Паттерн: Form + GlobalKey + валидаторы
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  autovalidateMode: AutovalidateMode.onUserInteraction, // живая валидация
  child: Column(children: [
    TextFormField(
      validator: (v) {
        if (v == null || v.isEmpty) return 'Обязательное поле';
        if (v.length < 2) return 'Минимум 2 символа';
        return null;
      },
    ),
  ]),
)

// Сабмит: if (_formKey.currentState!.validate()) { ... }
```

### 6.5 Хиптические отклики (Haptics)

```dart
// Тап на BIB:
HapticFeedback.lightImpact();

// Успешное действие (старт дан, финиш записан):
HapticFeedback.mediumImpact();

// Ошибка (DNS, DSQ):
HapticFeedback.heavyImpact();
```

### 6.6 Accessibility (a11y)

```dart
// Семантика для скринридеров:
Semantics(
  label: 'Участник 07, Петров, время 38 минут 12 секунд, первое место',
  child: AthleteCard(...),
)

// Минимальные touch targets: 48×48 dp
// Контраст текста: ≥ 4.5:1 (WCAG AA)
// НЕ полагаться только на цвет — добавлять иконки/текст
```

### 6.7 Форматирование

```dart
/// lib/utils/formatters.dart

// Время гонки: '00:38:12' или '00:38:12.345'
String formatRaceTime(Duration d, {bool millis = false});

// Дельта: '+1:33' или '-0:05'
String formatDelta(Duration d);

// Валюта: '2 500 ₽' (с пробелом тысяч)
String formatCurrency(int amount, {String symbol = '₽'});

// Дата: '10 мар 2026' / '10.03.2026'
String formatDate(DateTime d, {bool short = true});

// BIB: '07' (всегда 2+ цифры, с лидирующим нулём)
String formatBib(int bib);
```

### 6.8 Платформенные особенности

| Элемент | iOS | Android | macOS / Desktop |
|---|---|---|---|
| Навигация | iOS swipe back | Standard back | Sidebar |
| Шрифт | SF Pro (system) | Roboto (system) | Inter (наш) |
| StatusBar | Transparent | Colored (primary) | N/A |
| Safe area | Notch + home indicator | Status bar | Menu bar |
| Keyboard | iOS keyboard done btn | Standard | Physical |
| Scroll | Bounce | Glow | Scroll bar |

```dart
// Platform-aware:
import 'dart:io' show Platform;

if (Platform.isIOS) {
  // CupertinoDatePicker вместо Material
}
```

### 6.9 Локализация (i18n)

```dart
// Готовим инфраструктуру, даже если сейчас только русский:
// intl + arb файлы

// lib/l10n/app_ru.arb — русский (основной)
// lib/l10n/app_en.arb — английский (будущее)

// Использование:
Text(AppLocalizations.of(context)!.participants) // вместо Text('Участники')
```

### 6.10 Перформанс

```dart
// ✅ ListView.builder — для списков > 20 элементов
ListView.builder(itemCount: 200, itemBuilder: (ctx, i) => ...);

// ✅ const — везде где можно
const EdgeInsets.all(16)  // ✅
EdgeInsets.all(16)        // ❌ аллокация каждый ребилд

// ✅ RepaintBoundary — для тяжёлых виджетов (таймер, карта)
RepaintBoundary(child: TimerWidget())

// ✅ Image caching
CachedNetworkImage(imageUrl: url, placeholder: shimmer)

// ✅ Avoid rebuild
// Riverpod select() для точечного rebuild
ref.watch(eventProvider.select((e) => e.name))
```

---

## 7. Сводная таблица: «Не забыть продумать»

| # | Тема | Статус | Документ |
|---|---|---|---|
| 1 | Цветовые пресеты (17 шт.) | ✅ Описано выше | §1 |
| 2 | Светлая + Тёмная тема | ✅ Описано выше | §1.3 |
| 3 | Семантические цвета | ✅ Описано выше | §2 |
| 4 | Модальные окна (5 типов) | ✅ Описано выше | §3 |
| 5 | Навигация (запоминание, возврат) | ✅ Описано выше | §4 |
| 6 | Отказоустойчивость (4 состояния) | ✅ Описано выше | §5 |
| 7 | Loading / Error / Empty состояния | ✅ Описано выше | §5.3 |
| 8 | Оффлайн-режим | ✅ Описано выше | §5.4 |
| 9 | Скелетоны и shimmer | ✅ Описано выше | §6.1 |
| 10 | Pull-to-refresh | ✅ Описано выше | §6.2 |
| 11 | Пагинация (infinite scroll) | ✅ Описано выше | §6.3 |
| 12 | Валидация форм | ✅ Описано выше | §6.4 |
| 13 | Haptic feedback | ✅ Описано выше | §6.5 |
| 14 | Accessibility | ✅ Описано выше | §6.6 |
| 15 | Форматирование (время, валюта) | ✅ Описано выше | §6.7 |
| 16 | Платформенные различия | ✅ Описано выше | §6.8 |
| 17 | Локализация (i18n) | ✅ Описано выше | §6.9 |
| 18 | Перформанс | ✅ Описано выше | §6.10 |
| 19 | Анимации | ⏳ Нужен отдельный раздел |
| 20 | Тестирование (golden, widget) | ⏳ Нужен отдельный раздел |
| 21 | CI/CD (сборка, деплой) | ⏳ |
| 22 | Analytics / Crash reporting | ⏳ |
| 23 | Feature flags | ⏳ |

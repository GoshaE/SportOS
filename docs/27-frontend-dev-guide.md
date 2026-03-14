# 27. Frontend Development Guide — SportOS

> Полное руководство по вёрстке, компонентам, библиотекам и стандартам разработки UI.
> Цель — любой разработчик может взять этот документ и начать верстать качественно и быстро.

---

## 1. Стек технологий

| Технология | Версия | Назначение |
|---|---|---|
| **Flutter** | 3.10+ | UI Framework (iOS, Android, macOS, Web) |
| **Dart** | 3.10+ | Язык |
| **Material 3** | Встроен | Design System базис |
| **Riverpod** | 3.3+ | State Management |
| **go_router** | 17.1+ | Navigation |
| **Inter** | Google Fonts | Основной шрифт |

---

## 2. Библиотеки (рекомендованные)

### Ядро (уже установлены)
```yaml
dependencies:
  flutter_riverpod: ^3.3.1      # Стейт-менеджмент
  riverpod_annotation: ^4.0.2   # Codegen для Riverpod
  go_router: ^17.1.0            # Навигация
```

### Рекомендованы к добавлению

#### UI / Виджеты
```yaml
  google_fonts: ^6.2.1          # Шрифты без assets
  flutter_animate: ^4.5.0       # Декларативные анимации
  shimmer: ^3.0.0               # Skeleton loading
  cached_network_image: ^3.4.1  # Кеш картинок
  flutter_svg: ^2.0.10          # SVG иконки
  gap: ^3.0.1                   # SizedBox замена: Gap(8)
  sliver_tools: ^0.2.12         # Улучшенные Slivers
```

#### Данные / Хранение
```yaml
  isar: ^4.0.0-dev.14           # Локальная БД (offline-first)
  freezed_annotation: ^3.0.0    # Immutable models
  json_annotation: ^4.9.0       # JSON serialization
  dio: ^5.7.0                   # HTTP клиент
  web_socket_channel: ^3.0.1    # WebSocket (P2P sync)
```

#### Утилиты
```yaml
  intl: ^0.19.0                 # i18n, форматирование дат/валют
  uuid: ^4.5.1                  # UUID генерация
  share_plus: ^10.1.2           # Шаринг
  url_launcher: ^6.3.1          # Открытие URL
  permission_handler: ^11.3.1   # Запрос пермишенов
  connectivity_plus: ^6.1.0     # Проверка сети
  package_info_plus: ^8.0.3     # Версия приложения
```

#### Dev
```yaml
dev_dependencies:
  riverpod_generator: ^4.0.2    # Codegen
  build_runner: ^2.4.13         # Build codegen
  freezed: ^3.0.4               # Codegen для моделей
  json_serializable: ^6.8.0     # JSON codegen
  mocktail: ^1.0.4              # Моки для тестов
  golden_toolkit: ^0.15.0       # Golden tests
```

### НЕ используем
| ❌ Пакет | Почему |
|---|---|
| `provider` | Заменён на Riverpod |
| `bloc` / `flutter_bloc` | Riverpod покрывает потребности |
| `get_it` | Riverpod — DI + State |
| `http` | Dio лучше (interceptors, retry) |
| `hive` | Isar — преемник от того же автора |
| `auto_route` | go_router — стандарт от Flutter team |

---

## 3. Дизайн-система

### 3.1 Дизайн-токены

```dart
/// lib/app/tokens.dart
abstract class SportOsTokens {
  // ── Цвета (seed: 0xFF1B5E20 Deep Green) ──
  // Используем Material 3 ColorScheme, НЕ хардкодим цвета.
  // Доступ: Theme.of(context).colorScheme.primary / secondary / etc.
  
  // Семантические цвета (для бизнес-логики):
  static const statusOnline   = Color(0xFF4CAF50);
  static const statusOffline  = Color(0xFF9E9E9E);
  static const statusDns      = Color(0xFFF44336);
  static const statusDnf      = Color(0xFFFF9800);
  static const statusFinished = Color(0xFF4CAF50);
  static const statusOnTrack  = Color(0xFF2196F3);
  
  static const paymentPaid    = Color(0xFF4CAF50);
  static const paymentPending = Color(0xFFFF9800);
  static const paymentOverdue = Color(0xFFF44336);
  
  static const genderMale     = Color(0xFF2196F3);
  static const genderFemale   = Color(0xFFE91E63);
  
  // ── Отступы ──
  static const spacing4  = 4.0;
  static const spacing8  = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  
  // ── Радиусы ──
  static const radiusS  = 4.0;   // chip, badge
  static const radiusM  = 8.0;   // card, input
  static const radiusL  = 12.0;  // modal, sheet
  static const radiusXL = 16.0;  // hero card
  static const radiusFull = 999.0; // circle
  
  // ── Тени (Elevation) ──
  static const elevNone = 0.0;
  static const elevLow  = 1.0;   // cards
  static const elevMed  = 4.0;   // modals
  static const elevHigh = 8.0;   // FAB

  // ── Анимации ──
  static const animFast   = Duration(milliseconds: 150);
  static const animNormal = Duration(milliseconds: 300);
  static const animSlow   = Duration(milliseconds: 500);
}
```

### 3.2 Типография

```dart
/// Используем TextTheme из Material 3
/// Доступ: Theme.of(context).textTheme

// Заголовки:
//   displayLarge   — 57px (hero числа: таймер, BIG BIB)
//   headlineLarge  — 32px (заголовок экрана)
//   headlineMedium — 28px 
//   titleLarge     — 22px (AppBar title)
//   titleMedium    — 16px (карточка title)

// Тело:
//   bodyLarge      — 16px (основной текст)
//   bodyMedium     — 14px (описание)
//   bodySmall      — 12px (подпись)

// Числа:
//   Всегда fontFamily: 'monospace' для таймеров, BIB, результатов

// Пример:
Text('00:38:12', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
));
```

---

## 4. Атомарная система виджетов

### Уровни

```
Атомы → Молекулы → Организмы → Шаблоны → Экраны
```

| Уровень | Описание | Примеры |
|---|---|---|
| **Атом** | Минимальный неделимый элемент | Badge, StatusDot, BibChip, TimerText |
| **Молекула** | Комбинация 2-3 атомов | AthleteRow, RoleChip, PaymentBadge, SplitTime |
| **Организм** | Самостоятельный блок UI | AthleteCard, TeamMemberCard, ResultRow, FilterBar |
| **Шаблон** | Layout с слотами | ListWithFilters, TabbedScreen, DashboardGrid |
| **Экран** | Финальная страница | StarterScreen, ProtocolScreen |

### 4.1 Каталог атомов

```dart
// ═══ BADGE (статус/роль) ═══
class SportBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  // → Container с padding, borderRadius, цветной фон
}

// ═══ BIB CHIP ═══
class BibChip extends StatelessWidget {
  final String bib;
  final bool isActive;     // синий vs серый
  final bool isFinished;   // зачёркнутый
  final VoidCallback? onTap;
}

// ═══ STATUS DOT ═══
class StatusDot extends StatelessWidget {
  final SportStatus status; // online, offline, dns, dnf, finished, onTrack
  final double size;
}

// ═══ TIMER TEXT ═══
class TimerText extends StatelessWidget {
  final String time;       // '00:38:12.345'
  final TextStyle? style;
  // → Monospace, bold, по умолчанию headlineLarge
}

// ═══ SECTION HEADER ═══
class SectionHeader extends StatelessWidget {
  final String title;      // '⚖️ Судьи'
  final Widget? trailing;  // кнопка, count badge
}

// ═══ STAT CARD ═══
class StatCard extends StatelessWidget {
  final String value;      // '48'
  final String label;      // 'Участников'
  final Color color;
  final IconData? icon;
}
```

### 4.2 Каталог молекул

```dart
// ═══ ATHLETE ROW ═══
class AthleteRow extends StatelessWidget {
  final String bib;
  final String name;
  final String? dog;
  final String? time;
  final SportStatus status;
  final String? category;    // 'M 25-34'
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
}

// ═══ PAYMENT BADGE ═══
class PaymentBadge extends StatelessWidget {
  final PaymentStatus status; // paid, pending, overdue, free
}

// ═══ ROLE CHIP ═══
class RoleChip extends StatelessWidget {
  final EventRole role;     // Enum: headJudge, starter, marshal...
  final bool selected;
  final VoidCallback? onTap;
}

// ═══ DISCIPLINE FILTER ═══
class DisciplineFilter extends StatelessWidget {
  final List<String> disciplines;
  final String selected;
  final ValueChanged<String> onChanged;
  // → Горизонтальный ListView с ChoiceChips
}

// ═══ DAY SWITCHER ═══
class DaySwitcher extends StatelessWidget {
  final int totalDays;
  final int currentDay;     // 0 = общий зачёт
  final ValueChanged<int> onChanged;
}

// ═══ NAV ROW ═══
class NavRow extends StatelessWidget {
  final List<NavButton> buttons; // [{label, route, icon}]
  // → Row с OutlinedButtons для навигации между экранами
}
```

### 4.3 Каталог организмов

```dart
// ═══ ATHLETE CARD (полная) ═══
// BIB + ФИО + собака + время + статус + категория + меню
class AthleteCard extends StatelessWidget { ... }

// ═══ RESULT TABLE ═══
// Таблица результатов с сортировкой, фильтрами, экспортом
class ResultTable extends StatelessWidget { ... }

// ═══ FILTER BAR ═══
// Дисциплина + день + статус + поиск
class FilterBar extends StatelessWidget { ... }

// ═══ STATS PANEL ═══
// Ряд StatCard'ов
class StatsPanel extends StatelessWidget { ... }

// ═══ QR INVITE CARD ═══
// Роль + описание + QR + кнопка генерации
class QrInviteCard extends StatelessWidget { ... }

// ═══ TEAM MEMBER CARD ═══
// Аватар + имя + роль badge + online dot + checkpoint + меню
class TeamMemberCard extends StatelessWidget { ... }
```

---

## 5. Адаптивная вёрстка

### 5.1 Breakpoints

```dart
/// lib/app/breakpoints.dart
abstract class Breakpoints {
  static const mobile   = 600.0;   // < 600 — телефон
  static const tablet   = 900.0;   // 600-900 — планшет
  static const desktop  = 1200.0;  // > 900 — десктоп
}

// Использование:
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.desktop) return desktop;
    if (width >= Breakpoints.tablet) return tablet ?? desktop;
    return mobile;
  }
}
```

### 5.2 Стратегия

| Элемент | Mobile | Tablet | Desktop |
|---|---|---|---|
| **Навигация** | BottomNavigationBar | NavigationRail | NavigationRail + Drawer |
| **Списки** | ListView (full width) | ListView (2/3 width) | Master-Detail split |
| **Таблицы** | Прокрутка горизонт. | Полная таблица | Полная таблица |
| **Модалки** | BottomSheet (full) | BottomSheet (60%) | Dialog (центр) |
| **Карточки** | 1 колонка | 2 колонки | 3 колонки |
| **FAB** | Bottom-right | Bottom-right | В AppBar или Sidebar |
| **Фильтры** | Горизонт. scroll | Wrap | Row всегда видны |

### 5.3 Подход — Mobile-First

```
1. Верстаем сначала mobile (< 600px)
2. Добавляем tablet layout (600-900px)  
3. Добавляем desktop layout (> 900px)
```

```dart
// Пример: List → Grid переключение
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final crossAxisCount = width > Breakpoints.desktop ? 3 
                        : width > Breakpoints.tablet ? 2 
                        : 1;
  return GridView.count(crossAxisCount: crossAxisCount, ...);
}
```

---

## 6. Структура файлов виджетов

### 6.1 Правила

```
lib/
├── app/
│   ├── router.dart         # Маршруты
│   ├── theme.dart          # ThemeData
│   ├── tokens.dart         # Дизайн-токены
│   └── breakpoints.dart    # Breakpoints
│
├── ui/                     # Переиспользуемые виджеты
│   ├── atoms/              # Атомы
│   │   ├── sport_badge.dart
│   │   ├── bib_chip.dart
│   │   ├── status_dot.dart
│   │   ├── timer_text.dart
│   │   └── stat_card.dart
│   ├── molecules/          # Молекулы
│   │   ├── athlete_row.dart
│   │   ├── role_chip.dart
│   │   ├── discipline_filter.dart
│   │   ├── day_switcher.dart
│   │   └── payment_badge.dart
│   ├── organisms/          # Организмы
│   │   ├── athlete_card.dart
│   │   ├── result_table.dart
│   │   ├── filter_bar.dart
│   │   └── stats_panel.dart
│   ├── templates/          # Шаблоны
│   │   ├── adaptive_layout.dart
│   │   ├── list_with_filters.dart
│   │   └── tabbed_screen.dart
│   └── shells/             # Shells (уже есть)
│       ├── main_shell.dart
│       └── ops_shell.dart
│
├── features/               # Экраны (уже есть)
│   ├── auth/
│   ├── events/
│   ├── ops/
│   ├── results/
│   ├── profile/
│   └── clubs/
│
├── domain/                 # Модели данных
│   ├── models/
│   │   ├── athlete.dart
│   │   ├── event.dart
│   │   ├── discipline.dart
│   │   ├── result.dart
│   │   └── role.dart
│   └── enums/
│       ├── sport_status.dart
│       ├── payment_status.dart
│       └── event_role.dart
│
├── data/                   # Данные
│   ├── providers/          # Riverpod providers
│   ├── repositories/       # Репозитории
│   └── services/           # API, WS, Storage
│
└── utils/                  # Утилиты
    ├── formatters.dart     # Форматирование времени, валюты
    └── validators.dart     # Валидация
```

---

## 7. Стандарт описания виджета

Каждый виджет в `lib/ui/` должен иметь:

```dart
/// [SportBadge] — Цветной бейдж для статуса или роли.
///
/// ## Использование
/// ```dart
/// SportBadge(text: 'DNS', color: Colors.red)
/// SportBadge(text: '⚖️ Судья', color: Colors.purple, icon: Icons.gavel)
/// ```
///
/// ## Параметры
/// - [text] — текст внутри бейджа (обязательный)
/// - [color] — цвет фона и текста (обязательный)
/// - [icon] — иконка слева (опциональный)
///
/// ## Размеры
/// Padding: 4×2 (horizontal×vertical)
/// Font: bodySmall (12px), bold
/// BorderRadius: radiusS (4px)
///
/// ## Экраны где используется
/// - CheckInScreen (статус оплаты/мандатной)
/// - TeamScreen (роль участника)
/// - ProtocolScreen (категория)
class SportBadge extends StatelessWidget {
  const SportBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SportOsTokens.spacing4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SportOsTokens.radiusS),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ]),
    );
  }
}
```

---

## 8. Enums (модели данных)

```dart
/// lib/domain/enums/sport_status.dart
enum SportStatus {
  waiting,    // ⏳ ожидает
  started,    // 🏃 стартовал
  onTrack,    // 🏃 на трассе
  finished,   // ✅ финишировал
  dns,        // ❌ не стартовал
  dnf,        // ⚠️ не финишировал
  dsq,        // 🚫 дисквалифицирован
}

/// lib/domain/enums/event_role.dart
enum EventRole {
  organizer,   // 👑 Организатор
  headJudge,   // ⚖️ Главный судья
  secretary,   // 📝 Секретарь
  starter,     // ⏱ Стартёр
  finishJudge, // 🏁 Судья на финише
  marshal,     // 🚩 Маршал
  vet,         // 🩺 Ветеринар
  announcer,   // 🎙 Диктор
  timekeeper,  // ⏱ Хронометрист
  volunteer,   // 🤝 Волонтёр
}

/// lib/domain/enums/payment_status.dart
enum PaymentStatus {
  free,        // Бесплатное
  paid,        // ✅ Оплачено
  pending,     // ⏳ Ожидает
  overdue,     // ❌ Просрочено
  refunded,    // ↩️ Возврат
}
```

---

## 9. Правила вёрстки

### 9.1 Обязательные

1. **Никогда не хардкодить цвета** → `Theme.of(context).colorScheme` или `SportOsTokens`
2. **Никогда не хардкодить размеры текста** → `Theme.of(context).textTheme`
3. **Отступы только из токенов** → `SportOsTokens.spacing8`
4. **Радиусы только из токенов** → `SportOsTokens.radiusM`
5. **Моноширинный для чисел** → таймеры, BIB, результаты, время
6. **`const` везде где возможно** → const constructors, const EdgeInsets
7. **Именование файлов** → snake_case: `athlete_card.dart`
8. **Один виджет — один файл** для `ui/`, можно несколько для `features/`

### 9.2 Паттерны

```dart
// ✅ ПРАВИЛЬНО — используем токены
Container(
  padding: const EdgeInsets.all(SportOsTokens.spacing12),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(SportOsTokens.radiusM),
  ),
)

// ❌ НЕПРАВИЛЬНО — хардкод
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

### 9.3 Работа с состоянием

```dart
// Простой UI-стейт (табы, фильтры) → StatefulWidget + setState
// Бизнес-стейт (данные, API) → Riverpod Provider
// Форма → TextEditingController + Form

// Riverpod паттерн:
@riverpod
class EventNotifier extends _$EventNotifier {
  @override
  AsyncValue<Event> build(String eventId) async {
    return ref.watch(eventRepositoryProvider).getEvent(eventId);
  }
}
```

---

## 10. Чеклист для PR (Code Review)

- [ ] Виджет использует токены, а не хардкод
- [ ] Есть документация (/// комментарий с примером)
- [ ] Адаптив проверен на mobile / desktop
- [ ] `const` расставлен где возможно
- [ ] Числа в `monospace`
- [ ] Нет `Colors.xxx` для семантики → используем `SportOsTokens.statusXxx`
- [ ] Длинные списки через `ListView.builder`, не `Column + map`
- [ ] Нет overflow'ов (проверить shrink wrapping)
- [ ] Тёмная тема не сломана

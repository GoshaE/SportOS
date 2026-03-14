# Flutter Frontend — Документация по Вёрстке и Компонентам

> Полный каталог виджетов (Atomic Design), дерево маршрутов (go_router), и план поэтапной сборки каркаса приложения SportOS.

---

## Содержание

1. [Atomic Design (Уровни абстракции)](#1-atomic-design)
2. [Каталог Атомов](#2-каталог-атомов)
3. [Каталог Молекул](#3-каталог-молекул)
4. [Каталог Организмов](#4-каталог-организмов)
5. [Шаблоны Страниц (Layouts)](#5-шаблоны-страниц)
6. [Дерево Маршрутов (go_router)](#6-дерево-маршрутов)
7. [Порядок Реализации](#7-порядок-реализации)

---

## 1. Atomic Design

Весь UI строится по принципу **Atom → Molecule → Organism → Template → Screen**.

```
Atom         = Неделимый виджет (кнопка, иконка, текст, бейдж)
Molecule     = Группа атомов (строка отсечки, плитка BIB, карточка)
Organism     = Группа молекул (список отсечек, сетка BIB, модалка)
Template     = Layout страницы (Shell + AppBar + Content + BottomBar)
Screen       = Template + данные из Provider-а (конкретная страница)
```

---

## 2. Каталог Атомов (24 шт.)

Каждый Атом — это один файл `lib/ui/atoms/xxx.dart`.

| # | Атом | Файл | Описание | Где используется |
|---|---|---|---|---|
| A1 | **BigActionButton** | `big_action_button.dart` | Полноширинная кнопка ~20% высоты экрана. Вибрация + звук при тапе. | Финиш (ОТСЕЧКА), Старт (УШЁЛ), Старт (GUN START) |
| A2 | **BibChip** | `bib_chip.dart` | Квадратная плитка 80×80dp с номером BIB + мини-имя. Состояния: idle, checked, disabled, urgent. | Маршал, Финиш (модалка назначения) |
| A3 | **SyncIndicator** | `sync_indicator.dart` | Значок статуса связи: 🟢 Облако / 🔵 Хаб / 🔴 Оффлайн + текст `Pending: N`. | Все Ops-экраны (AppBar) |
| A4 | **TimerDisplay** | `timer_display.dart` | Моноширинный текст бегущего времени `HH:mm:ss.S`. Размер: Large / Medium / Compact. | Финиш, Старт, Маршал |
| A5 | **CountdownRing** | `countdown_ring.dart` | Круговая анимация обратного отсчёта с числом секунд в центре. | Стартёр (раздельный старт) |
| A6 | **StatusBadge** | `status_badge.dart` | Цветной бейдж: `Provisional`, `Official`, `DNS`, `DNF`, `DSQ`. | Результаты, Карточка заявки |
| A7 | **RoleBadge** | `role_badge.dart` | Иконка+текст роли: 👑 Админ, ⚖️ Судья, 🚩 Маршал... | Профиль, Команда |
| A8 | **DisciplineChip** | `discipline_chip.dart` | Filter-chip с названием дисциплины (Скиджоринг, Нарта, Пулка). | Финиш (фильтр BIB), стартовый лист |
| A9 | **SearchField** | `search_field.dart` | Текстовое поле поиска с иконкой лупы и кнопкой очистки. | Финиш (поиск BIB), Хаб (поиск мероприятий) |
| A10 | **EventStatusLabel** | `event_status_label.dart` | Статус мероприятия: `Черновик`, `Регистрация`, `В процессе`, `Завершено`. | Карточка мероприятия |
| A11 | **AvatarCircle** | `avatar_circle.dart` | Круглый аватар (фото/инициалы). Размеры: S/M/L. | Профиль, карточка атлета |
| A12 | **IconLabel** | `icon_label.dart` | Иконка + текст в одну строку (📅 Дата, 📍 Город, 👥 Участники). | Карточка мероприятия |
| A13 | **ProgressBar** | `progress_bar.dart` | Тонкий прогресс-бар: `12/35 финишировали`. | Финиш, Маршал, Ветконтроль |
| A14 | **VoiceMemoButton** | `voice_memo_button.dart` | Кнопка микрофона с анимацией записи. Tap→Record, Tap→Stop. | Финиш (аудиозаметка к отсечке) |
| A15 | **SosButton** | `sos_button.dart` | Красная кнопка 🆘 с двухэтапным подтверждением. | Маршал |
| A16 | **DeltaTime** | `delta_time.dart` | Зелёный/красный текст дельты: `+1:33` или `-0:12` от лидера. | Результаты, Диктор |
| A17 | **NotificationDot** | `notification_dot.dart` | Красная точка с числом (badge на иконке Tab-а). | Bottom Bar (Уведомления) |
| A18 | **SectionHeader** | `section_header.dart` | Заголовок секции с опциональной кнопкой действия справа. | Все списковые экраны |
| A19 | **EmptyState** | `empty_state.dart` | Иллюстрация + текст когда список пуст. | Все списки |
| A20 | **ErrorState** | `error_state.dart` | Иллюстрация ошибки + кнопка "Повторить". | Все экраны |
| A21 | **ConfirmDialog** | `confirm_dialog.dart` | Универсальный диалог подтверждения (Да/Нет). | Удаление, DNS, DNF, DSQ |
| A22 | **InputField** | `input_field.dart` | Стилизованное текстовое поле с label, validation, error text. | Регистрация, Создание мероприятия |
| A23 | **PhotoCapture** | `photo_capture.dart` | Квадратная область для фото (камера / галерея). | Нарушение (Маршал), Профиль |
| A24 | **PinInput** | `pin_input.dart` | Ввод PIN-кода (4-6 цифр) с экспоненциальной задержкой. | Авторизация |

---

## 3. Каталог Молекул (18 шт.)

`lib/ui/molecules/xxx.dart` — группы атомов.

| # | Молекула | Содержит атомы | Описание |
|---|---|---|---|
| M1 | **TimeMarkRow** | TimerDisplay + StatusBadge + текст BIB/имя | Одна строка отсечки в списке Финиша |
| M2 | **BibGrid** | N × BibChip + DisciplineChip (фильтр) | Сетка плиток BIB (3 колонки) для Финиша и Маршала |
| M3 | **StartQueueItem** | CountdownRing + текст BIB/имя + StatusBadge | Строка атлета в очереди Стартёра |
| M4 | **EventCard** | AvatarCircle + IconLabel × 3 + EventStatusLabel + ProgressBar | Карточка мероприятия в ленте Хаба |
| M5 | **AthleteCard** | AvatarCircle + текст ФИО/город/клуб + DeltaTime | Карточка атлета (Диктор, Результаты) |
| M6 | **ResultRow** | позиция + BibChip(mini) + имя + TimerDisplay + DeltaTime + StatusBadge | Одна строка в таблице результатов |
| M7 | **VetCheckRow** | текст кличка/чип + StatusBadge(допуск) + дата вакцинации | Строка собаки в экране Ветеринара |
| M8 | **TeamMemberRow** | AvatarCircle + имя + RoleBadge + действия | Строка члена команды (Организатор → Команда) |
| M9 | **NotificationItem** | иконка типа + текст + время + NotificationDot | Строка в Inbox |
| M10 | **OpsAppBar** | TimerDisplay(compact) + SyncIndicator + DisciplineChip + RoleBadge | AppBar для всех Ops-экранов (Финиш/Старт/Маршал) |
| M11 | **DisciplineSettingsForm** | InputField × N + Switch-и + Dropdown-ы | Форма настроек дисциплины (тип старта, интервал, cutoff) |
| M12 | **RegistrationStep** | SectionHeader + InputField × N + PhotoCapture | Один шаг визарда регистрации |
| M13 | **DrawItem** | drag handle + позиция + BibChip(mini) + имя + InputField(время) | Строка жеребьёвки (Drag & Drop) |
| M14 | **QrPairCard** | QR-код (динамический TOTP) + текст инструкции + таймер | Карточка пайринга маршала на экране Секретаря |
| M15 | **FinanceRow** | иконка + текст + сумма (зелёная/красная) | Строка финансового отчёта |
| M16 | **PenaltyForm** | Dropdown(тип) + InputField(описание) + PhotoCapture + TimerDisplay | Форма фиксации нарушения |
| M17 | **ProtestCard** | StatusBadge + BibChip × 2 + текст причины | Карточка протеста (Результаты) |
| M18 | **HubConnectionCard** | SyncIndicator + текст(имя Хаба) + кнопка "Переподключить" | Виджет состояния подключения к Хабу |

---

## 4. Каталог Организмов (12 шт.)

`lib/ui/organisms/xxx.dart` — самодостаточные блоки с логикой.

| # | Организм | Содержит молекулы | Описание |
|---|---|---|---|
| O1 | **TimeMarkList** | TimeMarkRow × N | Скроллируемый список отсечек (Финиш). Автоскролл к новой. |
| O2 | **BibPickerSheet** | SearchField + DisciplineChip-фильтр + BibGrid | Модальное окно назначения BIB с фильтрацией |
| O3 | **StartQueue** | StartQueueItem × N | Очередь стартового листа (Стартёр) |
| O4 | **MarshalGrid** | OpsAppBar + BibGrid | Полная сетка маршала с отслеживанием прохождения |
| O5 | **EventFeed** | EventCard × N + SearchField | Лента мероприятий с поиском и фильтрами |
| O6 | **ResultsTable** | ResultRow × N + SectionHeader(дисциплина) + фильтры(категория) | Полная таблица результатов |
| O7 | **RegistrationWizard** | RegistrationStep × 4 + Stepper | 4-шаговый визард регистрации участника |
| O8 | **DrawBoard** | DrawItem × N (ReorderableListView) | Экран жеребьёвки с Drag & Drop |
| O9 | **TeamManager** | TeamMemberRow × N + QrPairCard | Управление командой + генерация QR |
| O10 | **ProtestFlow** | ProtestCard × N + PenaltyForm | Подача и рассмотрение протестов |
| O11 | **VetCheckList** | VetCheckRow × N + кнопки допуска | Экран ветконтроля |
| O12 | **DictatorDashboard** | AthleteCard (ТОП-5) + ResultRow (последний финиш) + подсказки | Панель диктора |

---

## 5. Шаблоны Страниц (3 Layouts)

| # | Шаблон | Где | Описание |
|---|---|---|---|
| L1 | **MainShell** | Все не-Ops экраны | Scaffold + BottomNavigationBar (4 табы: Хаб, Мои, Уведомления, Профиль) |
| L2 | **OpsShell** | Режим Гонки | Scaffold + OpsAppBar (бегущее время, sync, роль) + Wakelock ON + Landscape Optional. Без BottomBar. |
| L3 | **DesktopShell** | Desktop Hub | Scaffold + Sidebar Navigation + Toolbar. Window always-on-top. Для ноутбука Секретаря. |

---

## 6. Дерево Маршрутов (go_router)

```dart
GoRouter(
  initialLocation: '/hub',
  routes: [
    // ── Shell: BottomBar (MainShell) ──
    ShellRoute(
      builder: MainShell,
      routes: [
        // Tab 1: Хаб
        GoRoute('/hub',         → HubFeedScreen),          // H1
        GoRoute('/hub/search',  → HubSearchScreen),        // H2
        GoRoute('/hub/event/:id', → EventDetailScreen),    // H3
        GoRoute('/hub/event/:id/register', → RegisterWizardScreen), // H4

        // Tab 2: Мои
        GoRoute('/my',          → MyEventsScreen),          // M1, M2
        GoRoute('/my/create',   → CreateEventWizardScreen), // M3

        // Tab 3: Уведомления
        GoRoute('/notifications', → InboxScreen),           // N1

        // Tab 4: Профиль
        GoRoute('/profile',     → ProfileScreen),           // PR1
        GoRoute('/profile/dogs', → MyDogsScreen),           // PR2
        GoRoute('/profile/dogs/:id', → DogDetailScreen),    // PR2.1
        GoRoute('/profile/results', → MyResultsScreen),     // PR3
        GoRoute('/profile/diplomas', → MyDiplomasScreen),   // PR4
        GoRoute('/profile/settings', → SettingsScreen),     // PR6
      ],
    ),

    // ── Управление Мероприятием (TabBar внутри) ──
    GoRoute('/manage/:eventId', → EventManageShell, routes: [
      GoRoute('overview',    → EventOverviewScreen),   // E1
      GoRoute('disciplines', → DisciplinesScreen),     // E2
      GoRoute('participants',→ ParticipantsScreen),    // E3
      GoRoute('team',        → TeamScreen),            // E4
      GoRoute('finances',    → FinancesScreen),        // E5
      GoRoute('documents',   → DocumentsScreen),       // E6
      GoRoute('settings',    → EventSettingsScreen),   // E7
    ]),

    // ── Подготовка к Гонке ──
    GoRoute('/manage/:eventId/draw',      → DrawScreen),      // P1
    GoRoute('/manage/:eventId/startlist', → StartListScreen),  // P2
    GoRoute('/manage/:eventId/bibs',      → BibAssignScreen),  // P3
    GoRoute('/manage/:eventId/vetcheck',  → VetCheckScreen),   // P4
    GoRoute('/manage/:eventId/checkin',   → CheckInScreen),    // P6

    // ── Режим Гонки (OpsShell — отдельный Shell без BottomBar) ──
    ShellRoute(
      builder: OpsShell,  // Wakelock ON, OpsAppBar
      routes: [
        GoRoute('/ops/:eventId/start',   → StarterScreen),   // R1
        GoRoute('/ops/:eventId/finish',  → FinishScreen),    // R2
        GoRoute('/ops/:eventId/marshal', → MarshalScreen),   // R3
        GoRoute('/ops/:eventId/dictator',→ DictatorScreen),  // R4
        GoRoute('/ops/:eventId/map',     → GpsMapScreen),    // R5
      ],
    ),

    // ── Результаты ──
    GoRoute('/results/:eventId/live',     → LiveResultsScreen), // RS1
    GoRoute('/results/:eventId/protocol', → ProtocolScreen),    // RS2
    GoRoute('/results/:eventId/protests', → ProtestsScreen),    // RS3
    GoRoute('/results/:eventId/diplomas', → DiplomaGenScreen),  // RS4

    // ── Авторизация ──
    GoRoute('/welcome',  → WelcomeScreen),    // A1
    GoRoute('/login',    → LoginScreen),       // A2
    GoRoute('/verify',   → OtpVerifyScreen),   // A3

    // ── QR Pairing (Маршал-волонтёр) ──
    GoRoute('/pair',     → QrPairingScreen),
  ],

  // ── Guards (Redirect) ──
  redirect: (context, state) {
    // 1. Не авторизован → /welcome
    // 2. Нет роли Организатор → нет /manage/*
    // 3. Нет роли Судья/Стартёр/Маршал → нет /ops/*
    // 4. Маршал по QR → только /ops/:id/marshal
  },
);
```

---

## 7. Порядок Реализации (3 Фазы)

### Фаза 1: Скелет (Каркас без данных) 🏗️
1. Инициализация Flutter-проекта (Material 3, go_router, Riverpod)
2. Реализация **3-х Shell-ов** (MainShell, OpsShell, DesktopShell)
3. Создание **всех 38 пустых Screen-файлов** с заглушками (Text: "Экран Финиша")
4. Прокинуть **весь go_router** с Role-based Guards
5. Навигация: убедиться, что каждый маршрут открывается из правильного экрана
6. Проверить: BottomBar, Back-кнопка, Deep Links

### Фаза 2: Вёрстка (Atoms → Screens) 🎨
1. Создать все **24 Атома** (чистые Stateless Widget-ы, без логики)
2. Собрать **18 Молекул** из Атомов
3. Собрать **12 Организмов** из Молекул
4. Встроить Организмы в заглушечные Screen-ы → они оживут с mock-данными
5. Приоритет: **Ops-экраны первыми** (Финиш → Старт → Маршал)

### Фаза 3: Данные и Состояние (Riverpod + Isar) ⚡
1. Подключить Isar Database
2. Создать модели (`freezed` + `json_serializable`)
3. Создать Riverpod Providers для каждого Feature
4. Подключить WebSocket-клиент (sync_engine)
5. Подключить mDNS Discovery
6. Интегрировать криптографию (Ed25519 подпись отсечек)

> [!IMPORTANT]
> **Итого виджетов для реализации:**
> - Атомов: **24**
> - Молекул: **18**
> - Организмов: **12**
> - Шаблонов: **3**
> - Экранов: **~38** (+ ~22 модалки/вложенных)
> - **Всего: ~95 компонентов**

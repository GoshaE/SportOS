# SportOS: Карта экранов приложения

## 1. Общая структура (High-Level)

```mermaid
graph TD
    SPLASH["🚀 Splash / Auth"] --> HUB["🏠 Hub (Главная)"]
    
    HUB --> EVENTS["📋 Мои мероприятия"]
    HUB --> ATHLETES_GLOBAL["👥 База атлетов"]
    HUB --> PROFILE["⚙️ Профиль / Настройки"]
    
    EVENTS --> EVENT_CARD["🏔 Карточка мероприятия"]
    
    EVENT_CARD --> TAB_OVERVIEW["📄 Обзор"]
    EVENT_CARD --> TAB_DISCIPLINES["🏁 Дисциплины"]
    EVENT_CARD --> TAB_PARTICIPANTS["👥 Участники"]
    EVENT_CARD --> TAB_TEAM["🛡 Команда"]
    EVENT_CARD --> TAB_FINANCE["💰 Финансы"]
    EVENT_CARD --> TAB_DOCS["📎 Документы"]
    
    EVENT_CARD --> OPS["⚡ Ops (Режим работы)"]
    
    OPS --> OPS_START["🟢 Стартёр"]
    OPS --> OPS_FINISH["🔴 Финиш"]
    OPS --> OPS_MARSHAL["🚩 Маршал"]
    OPS --> OPS_VET["🩺 Ветеринар"]
    OPS --> OPS_ANNOUNCER["🎙 Диктор"]
    
    EVENT_CARD --> RESULTS["📊 Результаты"]
    RESULTS --> LIVE["🌐 Live-трансляция (Web)"]
```

---

## 2. Детальная карта по разделам

### 2.1 Авторизация и вход

```mermaid
graph LR
    SPLASH["🚀 Splash"] --> AUTH_CHECK{"Авторизован?"}
    AUTH_CHECK -->|Да| HUB["🏠 Hub"]
    AUTH_CHECK -->|Нет| LOGIN["🔐 Вход"]
    
    LOGIN --> LOGIN_PIN["PIN"]
    LOGIN --> LOGIN_QR["📷 QR-маршала"]
    LOGIN --> LOGIN_BIO["👆 Биометрия"]
    
    LOGIN_PIN --> HUB
    LOGIN_QR --> OPS_MARSHAL["🚩 Маршал (ограниченный)"]
    LOGIN_BIO --> HUB
```

---

### 2.2 Hub (Главная)

```mermaid
graph TD
    HUB["🏠 Hub"]
    
    HUB --> EVENTS_LIST["📋 Мероприятия"]
    EVENTS_LIST --> FILTER_UPCOMING["Предстоящие"]
    EVENTS_LIST --> FILTER_PAST["Прошедшие"]
    EVENTS_LIST --> FILTER_TEMPLATES["Шаблоны"]
    EVENTS_LIST --> CREATE_EVENT["+ Создать мероприятие"]
    EVENTS_LIST --> CREATE_FROM_TEMPLATE["+ Из шаблона"]
    
    HUB --> ATHLETES_DB["👥 База атлетов"]
    ATHLETES_DB --> ATHLETE_PROFILE["Профиль атлета"]
    ATHLETE_PROFILE --> ATHLETE_DOGS["🐕 Собаки атлета"]
    ATHLETE_PROFILE --> ATHLETE_HISTORY["📈 История стартов"]
    ATHLETES_DB --> IMPORT_CSV["📥 Импорт Excel/CSV"]
    
    HUB --> SETTINGS["⚙️ Настройки"]
    SETTINGS --> LANG["🌐 Язык (RU/EN)"]
    SETTINGS --> SYNC_SETTINGS["📡 Sync / P2P"]
    SETTINGS --> BACKUP["💾 Бэкап / Экспорт"]
```

---

### 2.3 Карточка мероприятия (6 вкладок)

```mermaid
graph TD
    EVENT["🏔 Карточка мероприятия"]
    
    subgraph "Вкладка: Обзор"
        OV_INFO["Название, даты, место, лого"]
        OV_STATUS["Статус: Черновик → ... → Архив"]
        OV_STATS["Статистика: участники, слоты, оплаты"]
    end
    
    subgraph "Вкладка: Дисциплины"
        DISC_LIST["Список дисциплин"]
        DISC_LIST --> DISC_DETAIL["Настройка дисциплины"]
        DISC_DETAIL --> DISC_TRACK["Трасса (круг × кол-во)"]
        DISC_DETAIL --> DISC_START_TYPE["Тип старта"]
        DISC_DETAIL --> DISC_CATEGORIES["Категории (конструктор)"]
        DISC_DETAIL --> DISC_RULES["Правила (DNF, min lap time)"]
        DISC_LIST --> ADD_DISC["+ Добавить из каталога"]
    end
    
    subgraph "Вкладка: Участники"
        PART_LIST["Список заявок"]
        PART_LIST --> ENTRY_DETAIL["Заявка атлета"]
        ENTRY_DETAIL --> ENTRY_DOGS["Собаки в заявке"]
        ENTRY_DETAIL --> ENTRY_PAYMENT["Статус оплаты"]
        ENTRY_DETAIL --> ENTRY_CHECKLIST["Предстартовый чек-лист"]
        PART_LIST --> ADD_MANUAL["+ Добавить вручную"]
        PART_LIST --> WAITLIST["📋 Лист ожидания"]
        PART_LIST --> DRAW["🎲 Жеребьёвка"]
    end
    
    subgraph "Вкладка: Команда"
        TEAM_LIST["Список ролей"]
        TEAM_LIST --> ADD_ROLE["+ Добавить (PIN)"]
        TEAM_LIST --> GEN_QR["📱 QR для маршала"]
        TEAM_LIST --> SUCCESSION["⛓ Цепочка наследования"]
    end
    
    subgraph "Вкладка: Финансы"
        FIN_REQS["Реквизиты для оплаты"]
        FIN_STATUS["Статус оплат (оплач/не оплач)"]
        FIN_REFUNDS["К возврату / к переносу"]
    end
    
    subgraph "Вкладка: Документы"
        DOC_REG["📄 Регламент (PDF)"]
        DOC_GPX["🗺 Треки трасс (GPX)"]
        DOC_DIPLOMA["🏆 Шаблон диплома"]
        DOC_PROTOCOL["📊 Настройка протокола"]
    end

    EVENT --> OV_INFO
    EVENT --> DISC_LIST
    EVENT --> PART_LIST
    EVENT --> TEAM_LIST
    EVENT --> FIN_REQS
    EVENT --> DOC_REG
```

---

### 2.4 Жеребьёвка

```mermaid
graph TD
    DRAW["🎲 Жеребьёвка"]
    DRAW --> DRAW_CONFIG["Настройки"]
    DRAW_CONFIG --> DRAW_MODE["Режим: авто / ручная"]
    DRAW_CONFIG --> DRAW_GENDER["М и Ж: вместе / раздельно"]
    DRAW_CONFIG --> DRAW_GROUPS["По группам / общая"]
    DRAW_CONFIG --> DRAW_SEED["Посев: случайный / ручной"]
    
    DRAW --> DRAW_RUN["▶ Провести жеребьёвку"]
    DRAW_RUN --> DRAW_RESULT["Результат жеребьёвки"]
    DRAW_RESULT --> EDIT_MANUAL["✏️ Ручная корректировка"]
    DRAW_RESULT --> APPROVE["✅ Утвердить"]
    APPROVE --> START_LIST["📋 Стартовый лист"]
```

---

### 2.5 Ops — Рабочие экраны (переключаемые роли)

```mermaid
graph TD
    OPS["⚡ Ops: выбор режима"] --> SEL{"Мои роли"}
    
    SEL --> START_SCREEN["🟢 СТАРТЁР"]
    SEL --> FINISH_SCREEN["🔴 ФИНИШ"]
    SEL --> MARSHAL_SCREEN["🚩 МАРШАЛ"]
    SEL --> VET_SCREEN["🩺 ВЕТЕРИНАР"]
    SEL --> ANNOUNCER_SCREEN["🎙 ДИКТОР"]

    subgraph "Экран стартёра"
        START_SCREEN --> ST_QUEUE["Очередь на старт"]
        START_SCREEN --> ST_COUNTDOWN["Обратный отсчёт"]
        START_SCREEN --> ST_STATUS["Статус: кто ушёл / DNS"]
    end

    subgraph "Экран финиша"
        FINISH_SCREEN --> FN_LIST["Список финишировавших ↕"]
        FINISH_SCREEN --> FN_BUTTON["🔴 ОТСЕЧКА (внизу)"]
        FN_LIST --> FN_MODAL["Модалка: плитки BIB"]
        FN_LIST --> FN_SWIPE["Свайп: удалить метку"]
        FN_LIST --> FN_LONG["Long press: редактировать"]
    end
    
    subgraph "Экран маршала"
        MARSHAL_SCREEN --> MS_TILES["Плитки BIB (3 колонки)"]
        MS_TILES --> MS_TAP["Тап = отметка прохождения"]
        MS_TILES --> MS_PENALTY["Фиксация нарушения"]
        MS_TILES --> MS_DNF["Запрос DNF"]
    end
    
    subgraph "Экран ветеринара"
        VET_SCREEN --> VT_LIST["Список собак на проверку"]
        VET_SCREEN --> VT_SCAN["📷 Скан чипа"]
        VT_LIST --> VT_CHECK["✅ Допуск / ❌ Отказ"]
    end
    
    subgraph "Экран диктора"
        ANNOUNCER_SCREEN --> AN_TOP["🏆 ТОП лидеров"]
        ANNOUNCER_SCREEN --> AN_LAST["Последний финиш"]
        ANNOUNCER_SCREEN --> AN_PROGRESS["На трассе: N чел"]
        ANNOUNCER_SCREEN --> AN_PREDICT["⏱ Прогноз прибытия"]
        AN_TOP --> AN_CARD["Карточка атлета (тап)"]
    end
```

---

### 2.6 Результаты и протоколы

```mermaid
graph TD
    RESULTS["📊 Результаты"]
    
    RESULTS --> RES_LIVE["🔴 Live (обновляется)"]
    RESULTS --> RES_PROVISIONAL["⏳ Provisional"]
    RESULTS --> RES_VERIFIED["✅ Verified"]
    RESULTS --> RES_OFFICIAL["🏁 Official"]
    
    RES_OFFICIAL --> EXPORT_PDF["📄 Экспорт PDF"]
    RES_OFFICIAL --> EXPORT_CSV["📊 Экспорт Excel/CSV"]
    RES_OFFICIAL --> DIPLOMAS["🏆 Генерация дипломов"]
    RES_OFFICIAL --> WEB_PUBLISH["🌐 Публикация на Web"]
    
    RESULTS --> PROTESTS["⚖️ Протесты"]
    PROTESTS --> PROTEST_NEW["Подача протеста"]
    PROTESTS --> PROTEST_REVIEW["Рассмотрение"]
    PROTESTS --> PROTEST_VERDICT["Вердикт + наказание"]
    
    RESULTS --> CONFLICTS["⚠️ Конфликты данных"]
    CONFLICTS --> CONFLICT_RESOLVE["Ручное разрешение"]
```

---

### 2.7 Уведомления и сообщения (P2P)

```mermaid
graph LR
    NOTIF["📢 Уведомления"]
    NOTIF --> QUICK["⚡ Быстрые команды"]
    QUICK --> Q1["Задержка старта"]
    QUICK --> Q2["Поиск атлета"]
    QUICK --> Q3["Изменение трассы"]
    NOTIF --> FREE["✏️ Произвольное сообщение"]
    NOTIF --> TARGET["🎯 Кому: всем / по роли"]
```

---

## 3. Переходы между ролями

```mermaid
graph LR
    ADMIN["👑 Админ"] -->|видит всё| ALL["Все экраны"]
    JUDGE["⏱ Судья"] --> FINISH_SCREEN["Финиш"]
    JUDGE --> START_SCREEN["Старт"]
    JUDGE --> RESULTS["Результаты"]
    STARTER["🟢 Стартёр"] --> START_SCREEN
    STARTER -->|после отправки всех| FINISH_SCREEN
    MARSHAL["🚩 Маршал"] --> MARSHAL_SCREEN["Маршал"]
    VET["🩺 Ветеринар"] --> VET_SCREEN["Ветконтроль"]
    ANNOUNCER["🎙 Диктор"] --> ANNOUNCER_SCREEN["Live-монитор"]
    
    style ADMIN fill:#FFD700
    style JUDGE fill:#4CAF50
    style STARTER fill:#8BC34A
    style MARSHAL fill:#FF9800
    style VET fill:#E91E63
    style ANNOUNCER fill:#2196F3
```

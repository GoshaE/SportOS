# Архитектура SportOS

Визуальный обзор системы для быстрого понимания.

## Общая диаграмма

```mermaid
graph TB
    subgraph "Flutter App"
        direction TB
        UI["🖥 Presentation<br/>Screens, Widgets, Shells"]
        Domain["🧠 Domain<br/>Entities, Interfaces, Providers"]
        Data["💾 Data<br/>Repositories, DTOs, Drift DB"]
    end

    subgraph "External"
        Supa["☁️ Supabase<br/>Auth, Postgres, Realtime, Storage"]
        HW["📡 Hardware<br/>NFC, GPS, BLE, Camera"]
    end

    UI -->|"ref.watch(provider)"| Domain
    Domain -->|"IRepository interface"| Data
    Data -->|"Drift (SQLite)"| LocalDB["📦 Local DB"]
    Data -->|"Dio (HTTP)"| Supa
    Data -->|"Platform Channels"| HW
    Supa -->|"Realtime WS"| Data

    style UI fill:#818cf8,color:#fff
    style Domain fill:#f59e0b,color:#fff
    style Data fill:#10b981,color:#fff
```

## Поток данных: от нажатия до БД

```mermaid
sequenceDiagram
    participant U as 👤 Пользователь
    participant S as 🖥 Screen
    participant P as 🧠 Provider (Riverpod)
    participant R as 📦 Repository
    participant D as 💾 Drift (SQLite)
    participant A as ☁️ Supabase

    U->>S: Нажимает "Финиш" (BIB 42)
    S->>P: ref.read(timingNotifier).addFinish(42)
    P->>R: repo.saveFinishTime(bib: 42, time: now)
    R->>D: INSERT INTO timing_records
    D-->>P: Stream обновляется
    P-->>S: AsyncValue.data → UI обновлён
    
    Note over R,A: Фоново (когда есть сеть)
    R->>A: dio.post('/timing', body: record)
    A-->>R: 200 OK (синхронизировано)
```

## Двухрежимная навигация

```mermaid
graph LR
    subgraph "Participant Shell (MainShell)"
        H["🏠 Хаб"]
        M["📋 Мои"]
        N["🔔 Уведомления"]
        P["👤 Профиль"]
    end

    subgraph "Ops Shell (OpsRootShell)"
        D["📊 Дашборд"]
        C["✅ Чек-ин"]
        T["⏱ Тайминг"]
        R["🏆 Результаты"]
    end

    H -->|"Мероприятие → Управление → Ops"| D
    D -->|"Выйти (оранж. баннер)"| H

    style H fill:#6366f1,color:#fff
    style D fill:#ea580c,color:#fff
```

## Offline-first: поток синхронизации

```mermaid
graph TD
    Write["✍️ Запись данных"] --> Local["💾 Drift (SQLite)"]
    Local --> Queue["📤 Sync Queue"]
    Queue -->|"Есть сеть?"| Check{🌐}
    Check -->|"Да"| Push["☁️ Supabase Upsert"]
    Check -->|"Нет"| Wait["⏳ Ждём сеть"]
    Wait --> Check
    Push --> Done["✅ Sync OK"]
    Push -->|"Конфликт"| Resolve["🔀 Last-Write-Wins"]
    Resolve --> Done
```

## Слои и их ответственности

| Слой | Что содержит | Знает о | НЕ знает о |
|---|---|---|---|
| **Presentation** | Screen, View, Widget | Domain (providers, entities) | Data (Drift, Dio) |
| **Domain** | Entity, Interface, Provider | Только свои абстракции | Реализация (откуда данные) |
| **Data** | Repository, DTO, Drift Tables | Domain (entity для маппинга) | UI (как отображать) |
| **Core** | Theme, Widgets, Utils | Ничего специфичного | Фичи |

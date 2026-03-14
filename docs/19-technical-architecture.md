# 19. Техническая Архитектура SportOS — Полный Blueprint

> Бэкенд на **Rust (Axum)**, фронтенд на **Flutter**, архитектура **Offline-First** с гибридной синхронизацией. Один Rust-codebase → два бинарника (Cloud + Desktop Hub).

---

## Физическая Топология (3 Тира)

```
                    ┌──────────────────────────────┐
                    │     ☁️  TIER 1: CLOUD         │
                    │  Rust Axum Server (VPS/Cloud) │
                    │  PostgreSQL  ·  S3 Storage    │
                    │  WebSocket Hub  ·  REST API   │
                    └──────────┬───────────────────┘
                               │ LTE / 4G / Wi-Fi
                               │ (wss:// + mTLS)
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
┌──────▼──────┐  Wi-Fi LAN  ┌──▼───────────────┐       │
│📱 Телефон   │◄───────────►│💻 TIER 2: HUB    │       │
│  Судья 1    │  (ws://)    │ Rust Axum Desktop│       │
│  Flutter    │             │ SQLite embedded  │       │
│  Isar DB    │             │ + Wi-Fi Router   │       │
└─────────────┘             └──────────────────┘       │
┌─────────────┐                                        │
│📱 Телефон   │  ................................  LTE  │
│  Судья 2    │◄───────────────────────────────────────┘
│  Flutter    │   (Прямое подключение к Облаку,
│  Isar DB    │    если Wi-Fi Hub недоступен)
└─────────────┘
```

---

## 1. Бэкенд (Rust)

### 1.1 Фреймворк: Axum
- На базе Tokio runtime. Лучшая интеграция с экосистемой Tokio/Tower.
- Поддержка WebSocket + REST в одном сервере.
- Эффективнее по памяти на WebSocket-соединениях (~259MB на 50K).

### 1.2 Один Codebase — Два Бинарника

| Бинарник | Среда | БД | Назначение |
|---|---|---|---|
| `sportos-cloud` | VPS / Cloud (Linux) | PostgreSQL | Глобальный сервер, Live-результаты, API |
| `sportos-hub` | Ноутбук (macOS/Windows/Linux) | SQLite (embedded) | Локальный сервер на гонке |

```
sportos/
├── crates/
│   ├── sportos-core/       # Shared: модели, CRDT, Crypto, Audit Log
│   ├── sportos-cloud/      # Binary: Cloud Server (Axum + PostgreSQL)
│   └── sportos-hub/        # Binary: Desktop Hub (Axum + SQLite)
├── Cargo.toml              # Workspace
└── migrations/
```

### 1.3 Ключевые Rust Crates

| Crate | Назначение |
|---|---|
| `axum` | HTTP/WebSocket фреймворк |
| `tokio` | Async runtime |
| `sqlx` | Async SQL-драйвер (PostgreSQL + SQLite, единый API, compile-time SQL) |
| `serde` / `serde_json` | Сериализация |
| `ed25519-dalek` | Ed25519 подписи отсечек |
| `sha2` | SHA-256 хэш-цепочки (Audit Log) |
| `ring` / `rustls` | TLS, mTLS |
| `tower` | Middleware (auth, rate-limit) |
| `tracing` | Structured logging |
| `mdns-sd` | mDNS Service Discovery |

---

## 2. Фронтенд (Flutter)

### 2.1 Ключевые решения

| Слой | Технология | Обоснование |
|---|---|---|
| **State** | Riverpod 3.0 | Offline persistence, type-safe, mutations API |
| **Local DB** | Isar | <1мс запись, reactive queries, NoSQL |
| **Navigation** | go_router | Deep links, Role-based guards |
| **Models** | freezed + json_serializable | Иммутабельные, type-safe |
| **Transport** | web_socket_channel | все платформы |
| **Discovery** | multicast_dns | Поиск Hub в LAN |
| **Background** | flutter_background_service | Foreground Service для Sync |

### 2.2 Структура проекта

```
lib/
├── app/              # router.dart, theme.dart
├── core/
│   ├── db/           # Isar Database
│   ├── sync/         # Store & Forward, WebSocket, mDNS
│   ├── crypto/       # Ed25519, SHA-256 Hash Chain
│   └── time/         # PTP Handshake
├── features/         # auth, timing, marshal, results, hub_dashboard...
├── models/           # freezed + json_serializable
├── providers/        # Riverpod Providers
└── ui/
    ├── atoms/        # 24 атомарных виджета
    ├── molecules/    # 18 молекул
    └── organisms/    # 12 организмов
```

---

## 3. Базы Данных — Трёхуровневая Стратегия

| Тир | БД | Язык | Назначение |
|---|---|---|---|
| 📱 Телефон | **Isar** | Dart | Мгновенная запись отсечек, Reactive UI |
| 💻 Hub | **SQLite** | Rust (sqlx) | Агрегация данных, работа без интернета |
| ☁️ Cloud | **PostgreSQL** | Rust (sqlx) | Долговременное хранилище, масштабирование |

---

## 4. Wire Protocol

```json
{
  "type": "TIME_RECORD",
  "version": 3,
  "device_id": "iphone-14-abc123",
  "public_key": "ed25519:...",
  "timestamp": "2026-03-10T13:15:42.123Z",
  "payload": {
    "id": "uuid-v7",
    "event_id": "evt-456",
    "bib": 42,
    "checkpoint": "finish",
    "raw_device_time": 1741612542123,
    "applied_offset": -234,
    "drift_correction": 0
  },
  "prev_hash": "sha256:a1b2c3...",
  "signature": "ed25519:d4e5f6...",
  "hash": "sha256:g7h8i9..."
}
```

---

## 5. Связанные документы

- [05-p2p-sync.md](05-p2p-sync.md) — Гибридная синхронизация
- [07-roles-and-security.md](07-roles-and-security.md) — Криптография и Zero Trust
- [20-flutter-frontend.md](20-flutter-frontend.md) — Каталог виджетов и роутинг

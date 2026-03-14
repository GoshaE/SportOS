# 🏛 TimeUP Flutter Architecture: "Titan Core"

## 1. The Stack
We are building a **Offline-First**, **Real-Time** application.

*   **Framework**: Flutter (Dart).
*   **Backend (The Brain)**: Supabase.
    *   *Database*: PostgreSQL.
    *   *Auth*: Phone/Email.
    *   *Realtime*: Websockets for live results.
*   **Local Database (The Cache)**: **Isar** or **PowerSync**.
    *   *Reason*: We need SQL-like queries locally (Find athlete by BIB) and extreme speed.
*   **State Management**: **Riverpod**.
    *   *Reason*: Type-safe, testable, strictly separates UI from Logic.

## 2. Core Concepts

### A. The "Trinity" Data Model
Data moves in a strict circle:
1.  **Config (Studio)**: Defines the Rules (Intervals, Categories).
2.  **Actions (Ops)**: Raw Inputs (Button Presses, RFID reads).
3.  **State (Core)**: The result of applying Actions to Config.
    *   *Example*: Config(Sprint 10s) + Action(Start @ 10:00:00) = State(Running).

### B. Offline Sync Protocol ("Titan Sync")
The app must work 100% offline.
1.  **Write**: Actions are written to Local DB (`ActionQueue`).
2.  **Optimistic UI**: UI updates immediately.
3.  **Background Sync**: A worker pushes `ActionQueue` to Supabase when online.
4.  **Conflict Resolution**: Server timestamp wins, but "Judge Manual Override" has higher authority than "RFID Chip".

### C. The "Logic Engine" (Dart Isolate)
Calculations shouldn't block the UI while scrolling a list of 1000 athletes.
*   Complex math (Gaps, Ranks, Handicap) runs in a separate **Isolate** (Thread).
*   Input: `List<Action>`, `List<Athlete>`.
*   Output: `List<ResultRow>`.

## 3. Module Structure (Folder Layout)
```yaml
lib/
  src/
    core/             # Shared logic
      logic/          # The Trinity Math (Pure Dart)
      models/         # Freezed Data Models
      storage/        # Local Database Service
    features/
      auth/           # Login
      hub/            # Main Dashboard
      studio/         # Config Editors
      ops/            # Timing Interfaces
      public/         # Results & Lists
    app.dart          # Root Widget
```

## 4. Key Technical Decisions

### 100% Shared Logic
The Admin Panel (Web) and Mobile App (iOS/Android) share the **exact same** business logic code.
*   If we change how "Handicap" is calculated, it updates everywhere.

### The "Admin" is just a Role
There is no separate "Admin App".
*   If user.role == 'admin' -> Show "Edit" buttons.
*   If user.role == 'guest' -> Read-only.
This simplifies deployment significantly. One binary for everyone.

## 5. First Steps
1.  **Initialize Supabase Project**: Set up Tables (Org, Event, Race, Athlete, Action).
2.  **Scaffold Flutter App**: Setup Riverpod + GoRouter.
3.  **Port The Logic**: Translate the TypeScript `RaceEngine` to Dart.

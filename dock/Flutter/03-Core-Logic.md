# 🧠 Core Logic & Calculations (The Trinity)

This document defines the mathematical rules that the Flutter Engine must implement.

## 1. The Universal Time Standard
*   **Time Base**: All timestamps are stored as **Unix Milliseconds (Int64)**.
*   **Zero Hour**: Each Race has a `zero_time` (T0). All race times are strictly relative to this or absolute Day Time depending on the mode.
    *   *Interval Start*: Result = (Finish - Start) - Penalty.
    *   *Mass Start*: Result = (Finish - T0).

## 2. Race Modes

### A. Interval Start (Раздельный старт)
*   **Concept**: Athletes start one by one at fixed intervals (e.g., 30s).
*   **Parameters**:
    *   `interval_seconds`: (e.g., 30).
    *   `first_bib_start_time`: Absolute Day Time.
*   **Calculation**:
    *   `PlannedStartTime(BIB)` = `first_bib_start_time` + ((BIB - FirstBIB) * `interval_seconds`).
    *   `NetTime` = `FinishTime` - `ActualStartTime`.
    *   *Note*: If `ActualStartTime` is missing, use `PlannedStartTime` (default).

### B. Mass Start / Scratch (Масс-старт)
*   **Concept**: Everyone starts at the same time (Gun Time).
*   **Parameters**:
    *   `gun_time`: Absolute timestamp of the shot.
*   **Calculation**:
    *   `NetTime` = `FinishTime` - `gun_time`.

### C. Handicap (Гандикап / Персьют)
*   **Concept**: Leader starts at 0:00, others follow based on lag from previous stage.
*   **Parameters**:
    *   `prev_stage_id`: Source of lags.
*   **Calculation**:
    *   `StartLag` = `PrevStageTime` - `LeaderTime`.
    *   `NetTime` = `FinishTime` - `ActualStartTime`.
    *   `VirtualResult` = `NetTime` + `StartLag`.

## 3. Ranking Logic (Sorting)
How do we determine the winner?
1.  **Status Check**:
    *   DSQ (Disqualified) -> Bottom.
    *   DNF (Did Not Finish) -> Above DSQ.
    *   DNS (Did Not Start) -> Above DNF.
    *   OK (Finished) -> Sorted by Time.
2.  **Time Sort**: Ascending (Lowest time wins).
3.  **Tie Breaker**: Precision usually defines it. If equal -> Shared Rank.

## 4. Derived Metrics (Gaps)
*   **Gap to Leader**: `MyTime` - `LeaderTime`.
*   **Gap to Prev**: `MyTime` - `PrevRankTime`.
*   **Speed (km/h)**: (`DistanceKM` / `TotalHours`).
*   **Pace (min/km)**: (`TotalMinutes` / `DistanceKM`).

## 5. Validation Rules (Auto-Flags)
The system should automatically "Flag" suspicious results:
*   **Too Fast**: If Speed > World Record (config limit).
*   **Too Slow**: If Status is OK but time > Cutoff.
*   **Missed Checkpoint**: If Checkpoint B exists but Checkpoint A is missing.

## 6. Dart Implementation Requirements
*   Use `BigInt` or `int` (milliseconds) for all math. **Never use Double** for money or time accumulation to avoid floating point drift.
*   All logic must be Pure Functions: `f(Config, Inputs) -> Results`. No side effects.

# ⚙️ The Trinity Protocol: How it Works
**"Settings define the Rules. Actions define the Reality. Results are the Truth."**

This document describes the *exact* mechanical relationship between Configuration, Timing Actions, and the Final Results. This is the **Core Logic** of the application.

## 1. The Trinity Model
The entire system is built on three pillars.

```mermaid
graph TD
    Config[1. Settings (Static Rules)] --> Engine
    Actions[2. Ops Actions (Dynamic Inputs)] --> Engine
    Engine((3. Logic Engine)) --> Results[4. Results (State)]
    
    subgraph "Studio Mode"
    Config
    end
    
    subgraph "Ops Mode"
    Actions
    end
    
    subgraph "Public Mode"
    Results
    end
```

---

## 2. Settings (The Rules)
Before a race starts, the **Settings** define *how* time is calculated. Changing these settings retroactively *re-calculates* all results.

### Key Parameters:
1.  **Race Type**:
    *   `Mass Start`: Everyone has the same `ZeroTime`.
    *   `Interval Start`: Each athlete has a personal `TargetStartTime`.
2.  **Interval Rules** (Only for Interval Start):
    *   `Interval`: Time between starts (e.g., 30s).
    *   `Wave Size`: How many people start at once (e.g., 1).
3.  **Laps Configuration**:
    *   `Lap Count`: How many interactions required to finish (e.g., 3 laps = 2 checks + 1 finish).
    *   `Min Lap Time`: Safety buffer to prevent double-reads (e.g., 20s).

---

## 3. Ops Modules (The Inputs)

### A. The Start Module
How the race begins depends entirely on the **Race Type** setting.

#### Scenario 1: Mass Start (Gun Start)
*   **Judge Action**: Presses "GUN START" button.
*   **System Record**: Creates a `RaceStartAction` with `timestamp`.
*   **Effect**: 
    *   Sets `ZeroTime` for **ALL** athletes in this race.
    *   `Status` changes from `Ready` to `Running`.

#### Scenario 2: Interval Start (The Gate)
*   **Judge Action**: 
    *   Usually **Passive**. The judge creates a `RaceStartAction` just to leverage the clock synchronization.
    *   Usually **Active Exclusion**: Judge marks an athlete as `DNS` (Did Not Start).
*   **Effect**:
    *   System calculates `TargetStartTime` for BIB 101 based on `Settings.FirstStart` + `(Index * Settings.Interval)`.
    *   Athlete is "Running" automatically once their target time passes (unless marked DNS).

### B. The Finish Module
The Finish line collects raw timestamps.

*   **Input**: `Timestamp` + `BIB` (optional at first).
*   **Unknown Finish**: If a timestamp is recorded without a BIB (e.g., manual tap), it creates an `UnknownRead`.
*   **Identification**: When `UnknownRead` is assigned a BIB (Op enters number), it becomes a `FinishAction`.
*   **Logic**:
    1.  Look up Athlete by BIB.
    2.  Check `CurrentLap`.
    3.  If `CurrentLap < Settings.TotalLaps`, record as **Lap Split**.
    4.  If `CurrentLap == Settings.TotalLaps`, record as **Finish Time**.

---

## 4. The Calculation Engine (The Brain)
This is the function that runs everytime an action happens.

`calculateResults(Settings, List<Action>) -> List<ResultRow>`

### Step-by-Step Logic:

1.  **Initialize**: diverse list of all registered athletes.
2.  **Apply Start**:
    *   If **Mass Start**: `StartTime` = `RaceStartAction.timestamp`.
    *   If **Interval**: `StartTime` = `Settings.FirstStart + (Order * Interval)`.
3.  **Apply Finish**:
    *   Find the `FinishAction` for this BIB.
    *   `GrossTime` = `FinishAction.timestamp` - `StartTime`.
    *   If `GrossTime < 0`, flag as Error (Started after Finish?).
4.  **Determine Status**:
    *   If NO Start Action & Time passed -> `DNS`.
    *   If Start BUT NO Finish -> `DNF` (or `Running`).
    *   If Start & Finish -> `OK`.
5.  **Calculate Ranks**:
    *   Sort `OK` athletes by `GrossTime`.
    *   Assign ranks (1, 2, 3...).
6.  **Calculate Gaps**:
    *   `Gap` = `MyTime` - `WinnerTime`.

---

## 5. Critical Links (Why Relation Matters)

| Change in Settings... | Effect on Results... |
| :--- | :--- |
| Change **Group** from "Mass" to "Interval" | All "Running" times suddenly change because personal start times act as the new zero. |
| Change **Interval** from 30s to 60s | Athlete #2's start time shifts by +30s. Their Net Result improves by 30s instantly. |
| Change **Laps** from 1 to 2 | Existing "Finish" records might degrade to "Lap 1" splits. Athletes revert from "Finished" to "Running". |

## 6. Summary for Developers
*   **Start** is not just a button; it's a Time Reference Generator.
*   **Finish** is a Timestamp collector.
*   **Results** are a *view* derived from combining Settings + Start + Finish.
*   **Never** store "Final Rank" in the database. Compute it on the fly.

# 🗺 Flutter App Navigation & UX Map

## 📱 Philosophy: "One App, Two Modes"
The TimeUP Flutter application acts as a shapeshifter. Depending on the user's role and context, it transforms:
1.  **Public Mode (Spectator/Athlete):** Read-only, focus on Results & Live Data.
2.  **Studio Mode (Organizer):** Configuration, Setup, Protocol Management.
3.  **Ops Mode (Timer/Judge):** High-performance transactional interface (Start/Finish/Checks).

## 🧭 Sitemap Structure

### 1. Root Layer (The Gateway)
*   **`/` (Splash)**: Biometric Auth / Auto-login.
*   **`/auth`**: Phone Login / Role Selection.
*   **`/hub` (Main Home)**: The central dashboard.

### 2. The Hub (`/hub`)
The starting point for everyone.
*   **Tabs:**
    *   **Events**: List of available events (My Events + Public Featured).
    *   **Profile**: User settings, Licenses, App Settings (Dark Mode, Offline Mode).

### 3. Event Dashboard (`/event/:id`)
When opening an event, the UI adapts to permissions.

#### Public View (Guest)
*   **Hero**: Event Info, Status, Weather.
*   **Big Buttons**:
    *   `[Start List]` -> Searchable List of Athletes.
    *   `[Live Results]` -> Auto-refreshing Leaderboard.
    *   `[Info]` -> PDF Regulations / Maps.

#### Organizer View (Admin)
Includes all Public View elements + **"Manage"** Floating Action Button (FAB) or dedicated tab.
*   **Manage Tabs:**
    *   **Races**: List of Stages (Sprint, Mass Start).
    *   **Athletes**: Add/Import/Edit Database.
    *   **Access**: Invite Judges/Volunteers via QR/Link.
    *   **Settings**: Event-wide rules.

### 4. Race Context (`/race/:id`)
Drilling down into a specific race (e.g., "Men's Sprint").

*   **Public**:
    *   Detailed Leaderboard.
    *   Checkpoints Analysis (Gap charts).

*   **Studio (Config)**:
    *   **Settings**: Interval rules, Start Time, Categories.
    *   **Start List Builder**: Assign BIBs, seeding.

*   **Ops (The Action Zone)**:
    *   *Accessible via "Launch Ops" button.*
    *   **Start Gate**: Interval Countdown, Mass Start Gun.
    *   **Finish Line**: Tap-to-finish, RFID status.
    *   **Course Marshall**: Checkpoint recording.

## 🔗 User Flows

### Flow A: Creating a New Race (Organizer)
1.  Open App -> **Hub**.
2.  Tap `[+] Create Event`.
3.  Fill Basic Info (Name, Date). -> **Event Dashboard**.
4.  Tap `[+] New Race`.
5.  Select Template: **"Internal Start"** (Biathlon style).
6.  *System auto-configures defaults (30s interval).*
7.  **Ready to Time.**

### Flow B: Timing a Race (Judge)
1.  Open App -> Select Event.
2.  Tap **"Launch Ops"**.
3.  Select Role: **"Finish Judge"**.
4.  Screen sets to **Landscape Mode** (optional), Wakelock ON.
5.  Interface shows "Big Red Button" or keypad for BIB entry.
6.  Judge taps BIB `12` + `[Enter]`.
7.  Data syncs to Cloud -> Updates Public View instantly.

## 📱 Navigation UI Patterns (Flutter)
*   **Mobile**: Bottom Navigation Bar (Hub), Slivers (Scrollable Headers), FAB (Primary Actions).
*   **Tablet/Desktop**: Adaptive Navigation Rail (Side Menu), Master-Detail Views (List on left, Details on right).
*   **Gestures**: Swipe Back (iOS style), Pull-to-Refresh (Sync).

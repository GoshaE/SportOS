# 💽 Data Schema (Supabase / SQL)

To replace our MST/JSON tree, we need a relational schema.

## 1. High-Level ERD
`Organization` -> `Event` -> `Race` -> `Registration` -> `Result`

## 2. Tables

### `profiles` (Users)
Public user data (linked to `auth.users`).
*   `id` (UUID, PK)
*   `username` (Text)
*   `full_name` (Text)
*   `avatar_url` (Text)
*   `role` (Enum: admin, organizer, user)

### `organizations`
*   `id` (UUID, PK)
*   `name` (Text)
*   `owner_id` (UUID, FK -> profiles.id)

### `events`
A multiday competition (e.g., "World Cup 2026").
*   `id` (UUID, PK)
*   `org_id` (UUID, FK)
*   `name` (Text)
*   `slug` (Text, Unique) – for sharing `timeup.io/e/my-event`
*   `date_start` (Timestamptz)
*   `location` (JSONB) – {lat, lng, city}
*   `is_public` (Boolean)

### `races`
A specific stage (e.g., "Men 10k Sprint").
*   `id` (UUID, PK)
*   `event_id` (UUID, FK)
*   `name` (Text)
*   `start_type` (Enum: mass, interval, pursuit)
*   `start_time` (Timestamptz) – Planned start
*   `config` (JSONB) – {interval_seconds, laps, distance_m}

### `athletes` (Global Directory)
Reusable athlete profiles (optional, for history).
*   `id` (UUID, PK)
*   `first_name` (Text)
*   `last_name` (Text)
*   `birth_year` (Int)
*   `gender` (Enum: M, F)
*   `club` (Text)

### `registrations` (Event Entries)
Link between Athlete and Race.
*   `id` (UUID, PK)
*   `race_id` (UUID, FK)
*   `athlete_id` (UUID, FK, nullable if one-off)
*   `bib` (Int)
*   `category` (Text) – e.g., "M21"
*   `status` (Enum: active, dns, dsq)

### `actions` (The Ledger)
The immutable log of timing events.
*   `id` (UUID, PK)
*   `race_id` (UUID, FK)
*   `device_id` (Text) – Who recorded it?
*   `timestamp` (BigInt) – Unix millis
*   `type` (Enum: start, finish, split, manual_override)
*   `bib` (Int, Nullable)
*   `value` (JSONB) – Extra metadata

## 3. Realtime Policies
*   **Public**: SELECT on `events`, `races`, `registrations`.
*   **Organizers**: INSERT/UPDATE on their own `events`.
*   **Ops Judges**: INSERT on `actions` for assigned races.

## 4. Offline Sync Strategy
*   `actions` table is the critical sync point.
*   The App writes actions to local SQLite.
*   Sync Worker pushes local actions to Supabase `actions` table.
*   Postgres Triggers (or Dart Logic) calculate the final `NetTime` based on the stream of `actions`.

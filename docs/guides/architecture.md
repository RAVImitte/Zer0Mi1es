# Architecture & Technical Guide - Zero Miles

## 1. High-Level Architecture
Zero Miles is built on a modern mobile stack, utilizing a decoupled frontend and backend.
- **Client (Frontend):** Flutter (Dart) for cross-platform (iOS and Android) support.
- **Backend as a Service (BaaS):** Supabase, providing PostgreSQL database, Auth, Storage, and Edge Functions.
- **Real-time Engine:** Supabase Realtime for instant push of connection signals (Moods, Love Drops) and live database updates.

## 2. Frontend Structure (Flutter)
The app is organized using a feature-first architecture, ensuring separation of concerns and modularity.

### 2.1. Directory Structure (`appcode/lib`)
- **`app/`**: Contains the root application widget (`app.dart`).
- **`core/`**: Shared utilities, theme configurations (`app_colors.dart`, `app_theme.dart`), and global routing (`router.dart`).
- **`features/`**: The core business logic, divided by domain:
  - `auth/`: Authentication flow.
  - `avatar/`: Couple-scene state and the layered person puppet (`couple_scene_view_model.dart`, `layered_person_avatar.dart`). `PersonPainter` is only used to snapshot the Android home-screen widget.
  - `couple/`: Secure pairing and token generation.
  - `home/`: Dashboard — dual presence, talk banner, connection actions, Android widget sync.
  - `connection/`: Love drops, moods, and talk/sleep signals (Supabase + RLS).
  - `daily_question/`: Daily prompts and answer-to-unlock.
  - `daily_photo/` & `outfit/`: Image capture/upload and the blur fairness rule.
  - `voice_drop/`: Short voice notes.
  - `canvas/`: Shared doodle canvas.
  - `notifications/`: Inbound FCM.

There is **no** `AvatarViewModel` / `watchPartnerEvents` event bus. Home presence is `coupleSceneProvider` fed by `partnerStatusProvider` (moods, sleep, talk) and `loveDropsProvider` (flights).

### 2.2. State Management (Riverpod)
- **Framework:** `flutter_riverpod` combined with `riverpod_annotation` where generated.
- **Pattern:** Feature providers (`StreamProvider`, `NotifierProvider`). UI watches `AsyncValue` and scene state. Dual-avatar motion is `CoupleSceneViewModel`, not a single-avatar FSM.

### 2.3. Navigation (GoRouter)
- **Framework:** `go_router` for declarative routing.
- **Guards:** The router implements a redirect logic (e.g., in `router_notifier.dart`) that checks the authentication state and couple pairing state, ensuring users cannot access the main app without being authenticated and securely paired.

## 3. Backend Architecture (Supabase)
The database relies heavily on PostgreSQL features to maintain the strict privacy required by the app.

### 3.1. Database Schema Highlights
- **`profiles`:** User information (ID, display name, timezone, FCM token).
- **`couples`:** Maps two user IDs together. Pairing tokens and role (bear / bunny seat).
- **`moods`:** Latest mood per user in a couple. Labels: Happy, Excited, Tired, Sad, Angry, Devastated (legacy Overwhelmed maps to Angry in the client).
- **`love_drops`:** Gesture rows (type + optional note).
- **`connection_signals`:** Talk / sleep pings with status and expiry.
- **`daily_connections` / `daily_answers`:** Daily question and the answer-to-unlock rule.
- **`photos` / `outfits`:** Media metadata/URLs and the blur fairness rule.

### 3.2. Row Level Security (RLS)
- **Strict Privacy:** Every table is secured with RLS policies. A user can only `SELECT`, `INSERT`, `UPDATE`, or `DELETE` rows if their `auth.uid()` matches the user ID on the row, OR if the row belongs to their explicitly linked partner (verified via a join on the `couples` table).

### 3.3. Real-time & Edge Functions
- **Triggers:** PostgreSQL triggers handle background operations (like updating last-seen timestamps or triggering notifications).
- **Cron Jobs / PG_Cron:** Automates daily roll-over (e.g., generating the new daily question at midnight).

## 4. Notifications (Firebase Cloud Messaging)
- While Supabase is the primary backend, FCM handles delivering native push notifications (iOS APNs, Android FCM).
- Notifications are triggered for:
  - Partner answers a question.
  - Partner uploads a photo.
  - Partner sends a Love Drop or talk request (text / call / video).
- The Android home-screen widget (`home_widget` + `PartnerWidgetProvider`) is a **snapshot** of partner name, mood, scene, and avatar. It must not render talk or kisses. Sleep comes from `partnerStatusProvider`, not a leftover animation cache.

## 5. Deployment & CI/CD
- **Flutter:** Built into `.apk`/`.aab` for Android and `.ipa` for iOS. **V2 app version is `2.0.0+2`** (`appcode/pubspec.yaml`).
- **Supabase:** Managed via Supabase CLI migrations (`backend/supabase/migrations/`) ensuring the schema and RLS policies are version-controlled and reproducible.

## 6. V2 architecture (2026-09-05 – 2026-09-06)

Shipped in the last 72 hours. Product requirements: PRD §6.

- **Couple scene** (`coupleSceneProvider`) drives both Home seats. Do not reintroduce `AvatarViewModel` or `watchPartnerEvents`.
- **Layered puppet** is the in-app avatar. **`PersonPainter` is only for the Android widget snapshot.**
- **Talk** state lives in `partnerStatusProvider` + `talk_banner.dart` with reply-based expiry (`talk_expiry.dart`).
- **Widget sync** (`home_widget_sync.dart`) reads partner name / mood / scene / sleep / outfit — never talk or kisses.
- **Voice** (`voice_drop/`) and **canvas** (persisted strokes) are Home features, not V1 tabs.
- **Presence lighting** is `partnerSceneProvider` (dawn / day / dusk / night).

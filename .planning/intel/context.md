# Context

Running notes keyed by topic, extracted from classified DOCs. Each block is attributed to its source.

## Docs layout and ingest paths
- source: docs/README.md

This folder is the only living documentation for the app. Git root: `Zer0Mi1es/` (branch `main`). Do not keep copies in sibling worktrees or in `D:\Chadukunta\zeromiles\docs\`. App version: **2.0.0+2**.

Layout: `docs/prd/` product requirements (GSD ingest); `docs/adr/` architecture decisions, locked (GSD ingest); `docs/specs/` as-built feature contracts (GSD ingest); `docs/guides/` narrative architecture + UI; `docs/gsd/` how to run GSD on this repo; `docs/releases/` shipped milestone notes (V2, …); `docs/archive/v1/` frozen V1 PDF/DOCX — do not ingest; `docs/archive/legacy-guides/` superseded markdown — do not ingest.

Precedence if they disagree: **ADR > SPEC > PRD > guide**.

GSD ingest: `/gsd-ingest-docs` from this git root. It picks up `docs/prd/`, `docs/adr/`, `docs/specs/` only. Skip `archive/` and `gsd/`.

## Legacy guides superseded
- source: docs/archive/legacy-guides/README.md

Superseded by `docs/prd/PRD-zero-miles.md` and `docs/adr/`. Kept for history. **Do not ingest.**

## V1 frozen packs
- source: docs/archive/v1/README.md

Original V1 PDF/DOCX. Historical only. They describe pets, a single-avatar FSM, and phone auth that the code does not have. **Do not ingest.**

## Architecture stack and folders
- source: docs/guides/architecture.md

Zero Miles is built on a modern mobile stack, utilizing a decoupled frontend and backend.
- Client (Frontend): Flutter (Dart) for cross-platform (iOS and Android) support.
- Backend as a Service (BaaS): Supabase, providing PostgreSQL database, Auth, Storage, and Edge Functions.
- Real-time Engine: Supabase Realtime for instant push of connection signals (Moods, Love Drops) and live database updates.

Frontend (`appcode/lib`): `app/` root widget; `core/` theme (`app_colors.dart`, `app_theme.dart`) and routing (`router.dart`); `features/` by domain: `auth/`, `avatar/` (couple-scene state and layered person puppet; `PersonPainter` only for Android widget snapshot), `couple/`, `home/`, `connection/`, `daily_question/`, `daily_photo/` & `outfit/`, `voice_drop/`, `canvas/`, `notifications/`.

There is **no** `AvatarViewModel` / `watchPartnerEvents` event bus. Home presence is `coupleSceneProvider` fed by `partnerStatusProvider` (moods, sleep, talk) and `loveDropsProvider` (flights).

State: `flutter_riverpod` combined with `riverpod_annotation` where generated. Dual-avatar motion is `CoupleSceneViewModel`, not a single-avatar FSM.

Navigation: `go_router`. The guide states the router checks authentication state and couple pairing state, ensuring users cannot access the main app without being authenticated and securely paired. (Locked ADR-0007 overrides the pairing-gate clause: Home is not blocked on pairing.)

Schema highlights named in this guide: `profiles`, `couples`, `moods` (Happy, Excited, Tired, Sad, Angry, Devastated; legacy Overwhelmed maps to Angry in the client), `love_drops`, `connection_signals`, `daily_connections` / `daily_answers`, `photos` / `outfits`. (SPEC-daily-rituals names `daily_photos` / `daily_outfits`; SPEC wins.)

Every table is secured with RLS. FCM handles native push (iOS APNs, Android FCM) for partner answers, photo uploads, Love Drops, and talk requests. Android home-screen widget (`home_widget` + `PartnerWidgetProvider`) is a snapshot of partner name, mood, scene, and avatar. It must not render talk or kisses. Sleep comes from `partnerStatusProvider`, not a leftover animation cache.

V2 app version is `2.0.0+2` (`appcode/pubspec.yaml`). Supabase managed via CLI migrations (`backend/supabase/migrations/`).

V2 architecture (2026-09-05 – 2026-09-06): Couple scene (`coupleSceneProvider`) drives both Home seats. Do not reintroduce `AvatarViewModel` or `watchPartnerEvents`. Layered puppet is the in-app avatar. `PersonPainter` is only for the Android widget snapshot. Talk state lives in `partnerStatusProvider` + `talk_banner.dart` with reply-based expiry (`talk_expiry.dart`). Widget sync (`home_widget_sync.dart`) reads partner name / mood / scene / sleep / outfit — never talk or kisses. Voice (`voice_drop/`) and canvas (persisted strokes) are Home features, not V1 tabs. Presence lighting is `partnerSceneProvider` (dawn / day / dusk / night).

## UI / UX tokens and Home UX
- source: docs/guides/ui-ux.md

Zero Miles is designed to be a **private sanctuary**. Dark Mode First. Minimalist & Focused.

Background: Slate 900 `#0F172A`. Surface: Slate 800 `#1E293B`. Primary: Indigo `#6366F1`. Secondary: Pink `#EC4899`. Accent: Purple `#8B5CF6`. Primary Text: Slate 50 `#F8FAFC`. Secondary Text: Slate 400 `#94A3B8`.

Primary Font: Inter. Headings (H1/H2) Bold; Body Regular; Captions small, secondary color.

Give to Get: Daily Questions and Photo Sharing require the user to input their side before viewing their partner's side. Show a blurred or locked state with a clear call-to-action (e.g., "Answer to unlock your partner's response").

V1 Love Drops: Haptic feedback and a toast when sending a kiss, hug, or sorry.

V1 Navigation: Home is the dashboard. Daily question / photo / outfit are reachable from Home. Settings from the gear.

V2 Home (shipped 2026-09-05 – 2026-09-06): Both avatars stay on Home, large, with mood poses (Angry stomps with 💢; sleep shows Zzz). Love Drops: haptic + toast, and an emoji that flies from the sender’s seat to the receiver’s. Talk banner: one compact row above the couple scene. Never wrap chips over the avatars. Incoming: “{name} wants to call” + Okay + ⋯. Sender: “Waiting for {name}”, then their reply. Mood sheet: 2-column tiles (Happy, Excited, Tired, Sad, Angry, Devastated). No bottom tab bar. Canvas and voice are Home actions. Sanctuary lighting follows time of day.

Buttons: Rounded corners (e.g., `BorderRadius.circular(12)`), filled with Primary or Secondary. Cards use Surface `#1E293B`. Avatars (V2): two layered person puppets side by side (You | Partner). Unpaired empty seat is a “Pair” affordance, not a second dummy body.

Accessibility: high contrast; touch targets minimum 48x48 logical pixels.

## V2 shipped release
- source: docs/releases/V2.md

Version: `2.0.0+2`. Window: 2026-09-05 – 2026-09-06 (last 72 hours). Branch: `main` (PRs #7–#10, plus local merge cleanup).

This is the shipped V2 slice. V1 remains pairing, daily question, photo/OOTD, basic moods/love drops, and pings.

Shipped:
- Couple scene: both layered person puppets on Home; love-drop flight; persistent sleep
- Talk banner: one-line request + Okay + ⋯; sender waiting/reply; 8h pending; reply expiry 15m / 1h / 2h / tonight→6am
- Moods: 2-column sheet; Angry replaces Overwhelmed (legacy rows still map)
- Android widget: name, mood, scene, avatar snapshot — no talk, no kisses
- Voice + canvas: voice drops; shared mural persists offline
- Sanctuary Home: dawn / day / dusk / night wash
- Platform: Android/iOS-only tree; push JWT fix; `AvatarViewModel` removed

Commits (newest first): Merge PR #10 `feature` (widget + Angry); Merge PR #9 `UI-experiment` (dual avatars + compact talk); `52cf395` Replace Overwhelmed with Angry and restyle the mood picker; `abed603` Show both avatars on Home and compact the talk request; `3f83dc0` Add an Android home-screen widget for partner presence; Merge PR #8 / #7; `42403fa` Keep talk replies from bouncing and update the sender card immediately; `94d515c` Tune talk-reply banner expiry; `2e9e3be` Expire talk banners from the reply that was chosen; `9601bb5` Fix Home icon clipping, sleep persistence, and talk-ack ownership; `8405973` Tidy Home layout and fix talk-ack targeting; `a63f449` Replace the old avatar painter with a layered person puppet; `ea863d7` Restore push notifications after JWT-required function deploy; `9e33ba1` Persist canvas strokes so the mural survives offline; `200851a` Fix talk acknowledgements and stop Home from dropping partner state; `773138e` Add sanctuary UI, presence lighting, talk ack, voice drops, and live canvas; `5de4f7e` Restructure the Flutter app for Android/iOS.

Local on `main` (if not yet pushed): compile fix after the UI-experiment + feature merge, and removal of `AvatarViewModel` / `watchPartnerEvents`.

Not V2 (later): iOS home-screen widget; shared calendar / countdowns; shared playlists.

## GSD operator playbook
- source: docs/gsd/GSD.md

How to use GSD (Git. Ship. Done.) on this app. Product truth is **`main`** (`D:\Chadukunta\zeromiles\Zer0Mi1es`). GSD is already installed on this machine (standard profile, Grok). **Start Grok inside the git worktree you want to change.** Default to **`main`**. Dual avatars, compact talk banner, Angry mood, and the Android widget are already on `main`.

From WSL: `cd /mnt/d/Chadukunta/zeromiles/Zer0Mi1es` then `grok`. Git root is the worktree folder, not `appcode\`. GSD must run at `Zer0Mi1es*` so `.planning/` sits next to `appcode/` and `backend/`.

Zero Miles is a **brownfield** Flutter + Supabase couple app. Pairing, dual-avatar Home, moods (including Angry), love-drop flights, compact talk banner, daily question/photo/OOTD, voice drops, canvas, push, and the Android presence widget already exist on `main`.

Do **not** ingest `docs/archive/` (V1 PDFs, legacy guides). Ingest **prd + adr + specs** only. `docs/gsd/GSD.md` is operator docs. If ingest offers to treat it as a SPEC, skip it.

Onboard notes for already done:
- V1 done: auth, couple pairing + RLS, daily question, daily photo, OOTD, basic moods/love drops, pings, push
- V2 done (2026-09-05 – 2026-09-06): couple scene, layered puppets, compact talk banner, Angry mood, Android widget, voice drops, canvas, sanctuary lighting
- Not done / later: iOS widget, shared calendar — do **not** re-plan pairing or V2 Home
- There is **no** `AvatarViewModel` / `watchPartnerEvents`. Presence is `coupleSceneProvider` + `layered_person_avatar.dart`. `PersonPainter` is widget-snapshot only.

CONTEXT.md behavior locks from this playbook: Both avatars stay on Home at all times, big, with live mood animations. Talk request is one line: “{name} wants to call” + Okay + overflow. Okay / In a bit / Not now expire at 15m / 1h / 2h. Overwhelmed is gone; Angry has a stomp/scowl. Features are couple-private; RLS is non-negotiable. Android first; keep iOS from regressing.

Two-phone verification is non-negotiable for Home, moods, love drops, talk/call, pairing, or push. Minimum scripts: A sets mood Angry → B’s avatar stomps (💢) and the Android widget updates; A sends a love drop → it flies across the couple scene on B; A does not get a ghost echo; A taps call → B sees “{name} wants to call” one line; B taps Okay → A’s card becomes “{name} said okay” without flashing “Waiting…”; unanswered ping expires after 8 hours; replies Okay 15m, In a bit 1h, Not now 2h, Tonight until 6am; pairing still locks a third user out.

Point GSD at: `appcode/lib/features/avatar/presentation/couple_scene_view_model.dart`; `appcode/lib/features/avatar/presentation/widgets/layered_person_avatar.dart`; `appcode/lib/features/home/presentation/widgets/talk_banner.dart`; `partner_presence.dart` / `partner_status_provider.dart`; `appcode/lib/features/home/data/home_widget_sync.dart` + `person_painter.dart` (widget only); `backend/supabase/migrations/`; `AGENTS.md` → `npx supabase`, project `vkcoeudqeegnftkytiqd`.

WSL note: this WSL user has Windows `node.exe` / `npm` on PATH, but **no Linux `node` binary** until installed. `/gsd-new-project` is the wrong fix for Zero Miles. Use `/gsd-onboard`.

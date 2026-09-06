# Zero Miles

## What This Is

Zero Miles is a two-person Flutter app (Android + iOS) for long-distance partners. It is a private sanctuary: no feed, no friends list, no social sharing. After pairing, every feature is couple-scoped — daily question, photo, and outfit; live mood, sleep, love drops, and talk pings on a dual-puppet Home; short voice notes and a shared canvas; an Android home-screen snapshot of partner presence.

V1 and V2 already ship on `main` (`2.0.0+2`). This GSD milestone does not rebuild those surfaces. It makes partner-visible status the same on Home, the Android widget, and the backend, with no collisions or data loss.

## Core Value

Partner-visible status (mood, presence/sleep, pairing, daily unlock, talk banner, love drops, widget) stays consistent across Home, Android widget, and backend — no collisions, no dropped writes, no ghost echoes.

## Business Context

- **Customer**: Long-distance partners (exactly two people per couple)
- **Revenue model**: None — private couple product, not a social network
- **Success metric**: Status is consistently reflected on Home, widget, and backend with no collisions or data loss
- **Strategy notes**: Canonical product truth is `docs/prd/PRD-zero-miles.md`; locked ADRs in `docs/adr/`; as-built contracts in `docs/specs/`

## Requirements

### Validated

Shipped on `main` (V1 before 2026-09-05; V2 2026-09-05 – 2026-09-06). Locked as product capabilities — this milestone hardens consistency, it does not re-plan them as greenfield.

- ✓ **REQ-auth-v1** — Email/password sign-up and sign-in, profile name, timezone sync — V1
- ✓ **REQ-couple-pairing** — 6-character hashed pairing token, bear/bunny seats, two users max — V1
- ✓ **REQ-daily-question** — Daily question with answer-to-unlock — V1
- ✓ **REQ-daily-photo-outfit** — Daily photo + OOTD with photo-lock RLS — V1
- ✓ **REQ-moods** — Moods on Home (V2: Angry replaces Overwhelmed) — V1/V2
- ✓ **REQ-love-drops-v1** — Kiss / Hug / Sorry (V2: flights between seats) — V1/V2
- ✓ **REQ-talk-requests** — Talk/sleep signals (V2: compact banner + reply expiry) — V1/V2
- ✓ **REQ-home-couple-scene** — Dual layered puppets, persistent sleep, sanctuary lighting — V2
- ✓ **REQ-home-hub-no-tabs** — Home is the hub; no bottom tab bar — V2
- ✓ **REQ-android-widget** — Android presence snapshot (name/mood/scene/sleep/outfit; never talk or kisses) — V2
- ✓ **REQ-voice-canvas** — Voice drops (≤15s, 24h) and persisted canvas strokes — V2
- ✓ **REQ-secrets-not-in-git** — dart-define / `.env` only; no service-role in the client — V1
- ✓ **REQ-private-sanctuary** — Couple-private RLS; no feed, friends list, or social sharing — V1

### Active

Brownfield consistency — verify and fix so Validated behavior stays true on two phones without collisions or data loss.

- [ ] Partner-visible status matches across Home, Android widget, and backend (mood, sleep, pairing, daily unlock, talk banner, love drops)
- [ ] Two-phone UAT of the couple loop (Angry stomp + widget, love-drop flight with no ghost echo, one-line talk ack without Waiting bounce, third-user pairing lock)
- [ ] Daily give-to-get stays airtight (question answer and photo metadata unreadable until I contribute; outfit colors reach Home and widget)
- [ ] Voice and canvas persist without silent loss (15s/24h voice; canvas strokes survive restart and offline)

### Out of Scope

- **REQ-auth-v2** (phone/email auth from archive PRD) — superseded archive; canonical PRD + SPEC-auth-pairing are email + password only; phone OTP is not in `AuthScreen`
- **REQ-love-drops-v2** (Kiss / Hug / Heart / Sorry from archive PRD) — superseded archive; SPEC-home-presence is Kiss / Hug / Sorry only; no Heart drop
- **REQ-daily-question-history-legacy** — archive-only; no acceptance criteria; canonical PRD does not define history
- **REQ-photo-reactions-legacy** — archive-only; no acceptance criteria; canonical PRD does not define photo reactions
- **REQ-unpairing-account-deletion-legacy** — archive-only; no acceptance criteria; server delete-account path exists for teardown but is not a product surface in this milestone
- iOS home-screen widget — later; `iOSName` is reserved, not a V2 product (ADR-0008, ADR-0009)
- Shared calendar / countdowns — PRD later
- Shared playlists — PRD later
- Phone-number auth — code is email + password
- Bottom tab bar, pets, walk FSM, public social features — deleted or never in scope
- `AvatarViewModel` / `watchPartnerEvents` / in-app `PersonPainter` — removed; do not reintroduce
- Windows / Web / desktop as product targets — Android + iOS only
- E2E encryption beyond TLS + RLS; PSTN/cellular calling; interactive widget buttons that send talk

## Context

Brownfield Flutter + Supabase couple app. Git root is `Zer0Mi1es/` (this worktree, branch `main`), not `appcode/`. App version `2.0.0+2`. Backend: Supabase project `vkcoeudqeegnftkytiqd`, CLI via `npx supabase`. Docs live in `docs/` (PRD, ADR, SPEC). Precedence if they disagree: **ADR > SPEC > PRD > guide**. Do not ingest `docs/archive/` or treat `docs/gsd/GSD.md` as a SPEC.

**V1 shipped:** auth, couple pairing + RLS, daily question, daily photo, OOTD, basic moods/love drops, pings, push.

**V2 shipped (2026-09-05 – 2026-09-06):** couple scene, layered puppets, compact talk banner, Angry mood, Android widget, voice drops, canvas, sanctuary lighting. See `docs/releases/V2.md`.

Presence is `coupleSceneProvider` fed by `partnerStatusProvider` (mood, sleep, talk) and `loveDropsProvider` (flights). In-app avatars are `LayeredPersonAvatar`. `PersonPainter` is the Android widget snapshot only. Talk lives in `talk_banner.dart` + `talk_expiry.dart`. Widget sync is `home_widget_sync.dart`.

Two-phone verification is non-negotiable for Home, moods, love drops, talk, pairing, push, or widget. A green `flutter analyze` is not UAT.

Known gap: the daily-question client submits `guess`, but in-repo migrations do not `ADD COLUMN guess` — treat as a schema gap vs client; unlock remains answer-based.

## Constraints

- **Tech stack**: Flutter (`appcode/`) + Riverpod + GoRouter + Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) + FCM push — ADR-0001; do not add a second routing library, a second state library, or a custom HTTP API
- **Platform**: Android + iOS only — ADR-0009; `syncHomeWidget` no-ops on web
- **Layout**: Feature-first under `appcode/lib/features/{name}/` with `data/`, `domain/`, `presentation/` — ADR-0003; Home composes feature widgets and does not own mood/talk SQL
- **Privacy**: Every couple-owned table has RLS; writes require `user_id` / `sender_id` = `auth.uid()`; pairing tokens stored hashed; photo lock is RLS not only UI — ADR-0002
- **Home**: Hub with no `BottomNavigationBar`; Home is not blocked on pairing; unpaired opposite seat is Pair — ADR-0007
- **Widget**: Snapshot of name/mood/scene/sleep/outfit only; never talk or love-drop flights — ADR-0008
- **Moods**: Sheet is Happy, Excited, Tired, Sad, Angry, Devastated; Overwhelmed maps to Angry on read — ADR-0010
- **Secrets**: URL/anon key via dart-define / `.env`; `.env` gitignored; no service-role in the Flutter binary
- **Verification**: Two devices, watch the *other* phone; scripts in `docs/gsd/GSD.md` §8
- **Ops**: `npx supabase` for db; project `vkcoeudqeegnftkytiqd`

## Key Decisions

ADR-locked. Do not reopen.

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter + Supabase + Riverpod + GoRouter; FCM push; `home_widget` on Android (ADR-0001) | One mobile codebase, no custom HTTP API | ✓ Good — shipped `2.0.0+2` |
| Couple-private Postgres RLS; hashed 6-char pairing tokens; couple row only on join (ADR-0002) | Two-person sanctuary; raw code is ephemeral | ✓ Good |
| Feature-first Flutter folders (ADR-0003) | Home composes features; no global widgets dump | ✓ Good |
| `coupleSceneProvider` + `LayeredPersonAvatar`; no `AvatarViewModel` / `watchPartnerEvents` (ADR-0004) | Dual-seat presence, not a single-avatar FSM | ✓ Good |
| Puppets in-app; `PersonPainter` only for the widget snapshot (ADR-0005) | Widget stays a simple 2D snapshot | ✓ Good |
| One-line talk banner + reply-based expiry (ADR-0006) | Chips wrapping over avatars were the bug | ✓ Good |
| Home is the hub; no bottom tabs; unpaired Home stays reachable (ADR-0007) | Pairing gate in architecture.md lost to this ADR | ✓ Good |
| Android widget is presence-only — never talk or kisses (ADR-0008) | Widget is a glance, not a second Home | ✓ Good |
| Android and iOS only (ADR-0009) | Web/desktop are not product targets | ✓ Good |
| Angry replaces Overwhelmed; old rows still map (ADR-0010) | Stomp + 💢; no Overwhelmed on the sheet | ✓ Good |

---
*Last updated: 2026-09-06 after `/gsd-new-project` from ingest*

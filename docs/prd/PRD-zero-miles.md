---
type: PRD
status: Accepted
version: 2.0.0
date: 2026-09-06
---

# PRD — Zero Miles

## Product

Zero Miles is a **two-person** mobile app for long-distance partners. It is a private sanctuary: no feed, no friends list, no social sharing. After pairing, every feature is couple-scoped.

**Mission:** Stay intimately connected through daily rituals and real-time presence, no matter the distance.

**Audience:** Couples in long-distance relationships, or any pair who wants a closed loop outside noisy chat apps.

**Platform:** Flutter Android + iOS. App version **2.0.0+2**. Backend: Supabase (Postgres + Auth + Storage + Realtime + Edge Functions). Push: FCM via `push-notification`.

**Cross-refs:** [ADR-0001](../adr/0001-flutter-supabase-stack.md), [ADR-0002](../adr/0002-couple-private-rls.md), [V2](../releases/V2.md)

## User stories

1. As a partner, I want to sign up with email and password, set my name, and sync timezone so the other person sees me as me.
2. As a partner, I want to create or join a couple with a 6-character code so the app becomes a space for only us two.
3. As a partner, I want a daily question we both answer, and I must answer before I see theirs.
4. As a partner, I want to share a daily photo and outfit colors, and I must upload mine before I see theirs.
5. As a partner, I want to send a kiss, hug, or sorry and see it land on their Home.
6. As a partner, I want to set my mood so they see it on their Home and (on Android) their widget.
7. As a partner, I want to ping them to talk (text / call / video) and see a compact reply on Home.
8. As a partner, I want to send a short voice note and doodle on a shared canvas.
9. As a partner on Android, I want a home-screen widget that shows their name, mood, and scene — never a talk request or a kiss.

## V1 (core)

Shipped before 2026-09-05.

- Email/password auth and profile name
- Couple pairing (6-char token, 24h, two seats: bear / bunny)
- Daily question with answer-to-unlock
- Daily photo + OOTD with photo lock
- Moods, love drops, talk/sleep signals, push
- RLS: data visible only inside the couple

## V2 (shipped 2026-09-05 – 2026-09-06)

See [V2](../releases/V2.md) and [SPEC-home-presence](../specs/SPEC-home-presence.md).

- Both layered person puppets always on Home (couple scene)
- Love drops fly between seats; sleep persists
- Compact talk banner + reply expiry
- Angry mood (Overwhelmed maps to Angry)
- Android presence widget (no talk, no kisses)
- Voice drops (≤15s, 24h) and persisted canvas strokes
- Sanctuary lighting (dawn / day / dusk / night)
- No `AvatarViewModel` / `watchPartnerEvents`

## Acceptance criteria

Two-phone UAT copies these items 1:1 (still unchecked) in [PRODUCTION.md](../releases/PRODUCTION.md).

- [ ] Unauthenticated users cannot reach Home; they land on auth.
- [ ] A third account cannot join an already-paired couple.
- [ ] Daily question: partner answers stay hidden until I submit mine.
- [ ] Daily photo: partner photo metadata is unreadable until I upload mine (RLS).
- [ ] Home shows two avatars when paired; unpaired empty seat is Pair, not a dummy body.
- [ ] Incoming talk is one line with Okay + overflow; it never wraps over the avatars.
- [ ] Android widget updates name/mood/scene/sleep/outfit and never renders talk or kisses.
- [ ] Mood sheet offers Happy, Excited, Tired, Sad, Angry, Devastated.

## Out of scope (later)

- iOS home-screen widget
- Shared calendar / countdowns
- Shared playlists
- Phone-number auth (code is email + password)
- Bottom tab bar, pets, public social features

## Constraints

- Two users per couple. No groups.
- Home is the hub (no bottom navigation). See [ADR-0007](../adr/0007-home-hub-no-tabs.md).
- Secrets stay in dart-defines / `.env`, never in git.

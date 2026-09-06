# Requirements

Extracted from classified PRDs. Canonical source is `docs/prd/PRD-zero-miles.md`. Competing variants from `docs/archive/legacy-guides/prd_guide.md` are preserved under separate IDs and listed in INGEST-CONFLICTS.md WARNINGS.

## REQ-auth-v1
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to sign up with email and password, set my name, and sync timezone so the other person sees me as me. Phone-number auth is out of scope (code is email + password).
- acceptance: Unauthenticated users cannot reach Home; they land on auth.
- scope: authentication, profile, timezone

## REQ-auth-v2
- source: docs/archive/legacy-guides/prd_guide.md
- description: Phone/Email Auth: Secure sign-up/login. Profile Management: Basic details, timezone, and connection status.
- acceptance: absent
- scope: authentication, profile, timezone

## REQ-couple-pairing
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to create or join a couple with a 6-character code so the app becomes a space for only us two. Two users per couple. No groups.
- acceptance: A third account cannot join an already-paired couple.
- scope: couple pairing

## REQ-daily-question
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want a daily question we both answer, and I must answer before I see theirs.
- acceptance: Daily question: partner answers stay hidden until I submit mine.
- scope: daily question

## REQ-daily-question-history-legacy
- source: docs/archive/legacy-guides/prd_guide.md
- description: Users can view a history of past questions and answers.
- acceptance: absent
- scope: daily question history

## REQ-daily-photo-outfit
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to share a daily photo and outfit colors, and I must upload mine before I see theirs.
- acceptance: Daily photo: partner photo metadata is unreadable until I upload mine (RLS).
- scope: daily photo, OOTD

## REQ-photo-reactions-legacy
- source: docs/archive/legacy-guides/prd_guide.md
- description: Ability to react to the partner's photos.
- acceptance: absent
- scope: daily photo reactions

## REQ-love-drops-v1
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to send a kiss, hug, or sorry and see it land on their Home. V2: Love drops fly between seats; sleep persists.
- acceptance: absent
- scope: love drops

## REQ-love-drops-v2
- source: docs/archive/legacy-guides/prd_guide.md
- description: Love Drops: Kiss 💋, Hug 🤗, Heart 💖, Sorry 🥺 — haptic + toast.
- acceptance: absent
- scope: love drops

## REQ-moods
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to set my mood so they see it on their Home and (on Android) their widget. V2: Angry mood (Overwhelmed maps to Angry).
- acceptance: Mood sheet offers Happy, Excited, Tired, Sad, Angry, Devastated.
- scope: moods

## REQ-talk-requests
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to ping them to talk (text / call / video) and see a compact reply on Home.
- acceptance: Incoming talk is one line with Okay + overflow; it never wraps over the avatars.
- scope: talk requests, Home

## REQ-voice-canvas
- source: docs/prd/PRD-zero-miles.md
- description: As a partner, I want to send a short voice note and doodle on a shared canvas. V2: Voice drops (≤15s, 24h) and persisted canvas strokes.
- acceptance: absent
- scope: voice drops, shared canvas

## REQ-android-widget
- source: docs/prd/PRD-zero-miles.md
- description: As a partner on Android, I want a home-screen widget that shows their name, mood, and scene — never a talk request or a kiss.
- acceptance: Android widget updates name/mood/scene/sleep/outfit and never renders talk or kisses.
- scope: Android widget

## REQ-home-couple-scene
- source: docs/prd/PRD-zero-miles.md
- description: Both layered person puppets always on Home (couple scene). No `AvatarViewModel` / `watchPartnerEvents`. Sanctuary lighting (dawn / day / dusk / night).
- acceptance: Home shows two avatars when paired; unpaired empty seat is Pair, not a dummy body.
- scope: Home, couple scene

## REQ-home-hub-no-tabs
- source: docs/prd/PRD-zero-miles.md
- description: Home is the hub (no bottom navigation). Bottom tab bar is out of scope.
- acceptance: absent
- scope: Home, navigation

## REQ-secrets-not-in-git
- source: docs/prd/PRD-zero-miles.md
- description: Secrets stay in dart-defines / `.env`, never in git.
- acceptance: absent
- scope: secrets

## REQ-unpairing-account-deletion-legacy
- source: docs/archive/legacy-guides/prd_guide.md
- description: Ability to sever the connection or delete the account securely.
- acceptance: absent
- scope: unpairing, account deletion

## REQ-private-sanctuary
- source: docs/prd/PRD-zero-miles.md
- description: Zero Miles is a two-person mobile app for long-distance partners. It is a private sanctuary: no feed, no friends list, no social sharing. After pairing, every feature is couple-scoped. Out of scope later: iOS home-screen widget, shared calendar / countdowns, shared playlists, phone-number auth, bottom tab bar, pets, public social features.
- acceptance: absent
- scope: Zero Miles, product

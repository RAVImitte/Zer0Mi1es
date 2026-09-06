# Decisions

Extracted from classified ADRs. All ten ADRs in the ingest set have `locked: true` and source status Accepted. No LOCKED-vs-LOCKED contradiction on the same scope.

## ADR-0001: Use Flutter, Supabase, Riverpod, and GoRouter
- source: docs/adr/0001-flutter-supabase-stack.md
- status: locked (Accepted)
- decision: Client is Flutter (`appcode/`), Android + iOS only, version `2.0.0+2`. State is `flutter_riverpod` + `riverpod_annotation` where generated. Navigation is `go_router` with redirects on session and `registration_status`. Backend is Supabase Postgres, Auth, Storage, Realtime, Edge Functions (`backend/supabase/`). Push is Firebase Cloud Messaging + `push-notification` Edge Function (`PushDispatcher`). Widget is `home_widget` on Android (`PartnerWidgetProvider`). Do not add a second routing library, a second state library, or a custom HTTP API alongside Supabase.
- scope: Flutter, Supabase, Riverpod, GoRouter, Firebase Cloud Messaging, home_widget

## ADR-0002: Couple-private data with Postgres RLS
- source: docs/adr/0002-couple-private-rls.md
- status: locked (Accepted)
- decision: Every couple-owned table enables RLS. Typical policy: `couple_id IN (SELECT id FROM couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())`. Writes further require `user_id` / `sender_id` = `auth.uid()`. Pairing RPCs: `create_couple_with_token` stores a hashed token only (no couple row); `join_couple_with_token` creates the couple with creator = bear, joiner = bunny, and marks the token used. Raw token is 6 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I/O/0/1), SHA-256 hashed, 24h TTL. Creating a new code deletes the user’s unused tokens. A user may belong to at most one couple. Self-join is rejected. A used token cannot admit a third person. Storage buckets for photos and voice are private; object paths are scoped to couple id + user id. Photo lock is enforced in RLS (partner row unreadable until the reader has a row for that date), not only in UI.
- scope: Postgres RLS, couples, pairing tokens, storage buckets, photo lock

## ADR-0003: Feature-first Flutter layout
- source: docs/adr/0003-feature-first-layout.md
- status: locked (Accepted)
- decision: Organize under `appcode/lib/features/{name}/` with `data/`, `domain/`, and `presentation/` inside each feature. Shared code lives in `appcode/lib/core/` (theme, routing, supabase providers, talk expiry). Current features: `auth`, `avatar`, `canvas`, `connection`, `couple`, `daily_photo`, `daily_question`, `home`, `notifications`, `outfit`, `voice_drop`. New screens belong in an existing feature or a new feature folder — not a global `widgets/` dump. Home composes feature widgets; it does not own mood/talk SQL.
- scope: Flutter layout, features, appcode/lib/features, appcode/lib/core

## ADR-0004: Couple scene instead of a single-avatar FSM
- source: docs/adr/0004-couple-scene-presence.md
- status: locked (Accepted)
- decision: Presence is `coupleSceneProvider` (`CoupleSceneViewModel`). Inputs: `partnerStatusProvider` (mood, sleep, talk) and `loveDropsProvider` (flights). In-app drawing is `LayeredPersonAvatar` (puppet poses). Home and daily-question chips use it directly. Do not reintroduce `AvatarViewModel`, `AvatarEvent`, or `watchPartnerEvents`. Animation states in use: idle, sleeping, mood*, giving, receiving, leanIn, sorry. Pet/walk/talk FSM states are gone. Widget sleep reads `partnerStatus.partnerAsleep`, not an animation cache. Love-drop flights are scene state (`CoupleDrop`), not a global event bus.
- scope: coupleSceneProvider, CoupleSceneViewModel, LayeredPersonAvatar, partnerStatusProvider, loveDropsProvider

## ADR-0005: Layered puppet in-app, PersonPainter only for the widget
- source: docs/adr/0005-puppet-vs-widget-painter.md
- status: locked (Accepted)
- decision: In-app avatars use `LayeredPersonAvatar` + `PuppetPose` (ticker, blink, mood poses including Angry stomp + 💢). Android widget snapshot uses `PersonPainter` in `person_painter.dart`, rendered through `HomeWidget.renderFlutterWidget`. `DynamicPersonAvatar` wrapper is deleted. Do not drive Home with `PersonPainter`. Do not run `flutter_animate` on the couple scene. Widget painter may stay a simpler 2D snapshot; it does not need puppet fidelity.
- scope: LayeredPersonAvatar, PuppetPose, PersonPainter, Android widget, DynamicPersonAvatar

## ADR-0006: Compact talk banner and reply-based expiry
- source: docs/adr/0006-talk-banner-expiry.md
- status: locked (Accepted)
- decision: One Home row: “{name} wants to call|text|video chat” + Okay + ⋯. Overflow: In a bit, Tonight, Not now (`talk_banner.dart`). Sender: “Waiting for {name}”, then “{name} said okay” (dismissible). Only the newest live ping is shown. Dismissed ids stay hidden locally. Pending max age: 8 hours. Reply expiry (`talk_expiry.dart`): Okay 15m, In a bit 1h, Not now 2h, Tonight until 6am in the recipient IANA timezone. Ack writes `acknowledgeSignal` with status `yes` / `soon` / `tonight` / `not_now`. Do not put four equal chips on Home again.
- scope: talk banner, talk requests, reply expiry, Home, acknowledgeSignal

## ADR-0007: Home is the hub (no bottom tabs)
- source: docs/adr/0007-home-hub-no-tabs.md
- status: locked (Accepted)
- decision: Routes: `/` Home, `/couple`, `/daily_question`, `/outfit`, `/daily_photo`, `/canvas`, plus auth/profile/splash. Daily rituals open from Home’s daily-status row. Settings is a sheet. Voice and canvas are Home actions. Router redirects: no session → auth; `registration_status = signed_up` → profile setup. Home is not blocked on pairing. Unpaired Home shows a Pair seat; Kiss/Talk/etc. snackbar “Pair with your partner first”. Partner screen is Settings → Partner. Do not add a `BottomNavigationBar`. New surfaces hang off Home or a GoRoute from Home.
- scope: Home, bottom navigation, routes, pairing, Settings

## ADR-0008: Android widget is a presence snapshot, never talk or kisses
- source: docs/adr/0008-android-widget-no-talk.md
- status: locked (Accepted)
- decision: `home_widget_sync.dart` may save partner first name, mood line, scene label (dawn/day/dusk/night), sleeping flag, and outfit colors into `PersonPainter`. It must not snapshot talk banners or love-drop flights. Provider: `com.example.zer0mi1es.PartnerWidgetProvider`. iOS widget is out of scope (later). Listeners: partner name, mood, sleep, scene, outfit. No listen on talk or love drops for widget updates.
- scope: Android widget, home_widget_sync.dart, PartnerWidgetProvider, talk banners, love-drop flights

## ADR-0009: Android and iOS only
- source: docs/adr/0009-android-ios-only.md
- status: locked (Accepted)
- decision: Ship Android and iOS from `appcode/`. `syncHomeWidget` returns immediately on web. Do not add Windows/Web/desktop as product targets. CI and local run instructions are `flutter run` on a device/emulator, not Chrome.
- scope: Android, iOS, appcode/, syncHomeWidget, Flutter

## ADR-0010: Angry replaces Overwhelmed
- source: docs/adr/0010-angry-replaces-overwhelmed.md
- status: locked (Accepted)
- decision: Sheet labels (2-column): Happy, Excited, Tired, Sad, Angry, Devastated. `AnimationState.moodAngry` / puppet pose + 💢 overlay. Persist `Angry` in `moods.mood`. Read path: `'Angry' || 'Overwhelmed'` still maps to Angry so old rows do not go idle. Do not add Overwhelmed back to the sheet. Do not resurrect `moodOverwhelmed`.
- scope: mood sheet, AnimationState.moodAngry, moods.mood, Overwhelmed

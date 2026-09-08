---
status: Accepted
---

# ADR-0001 Use Flutter, Supabase, Riverpod, and GoRouter

## Context

Zero Miles is a two-person mobile product. It needs one codebase for Android and iOS, realtime couple data, and auth without running a custom API server.

## Decision

- **Client:** Flutter (`appcode/`), Android + iOS only. Version `3.0.0+3`.
- **State:** `flutter_riverpod` + `riverpod_annotation` where generated.
- **Navigation:** `go_router` with redirects on session and `registration_status`.
- **Backend:** Supabase Postgres, Auth, Storage, Realtime, Edge Functions (`backend/supabase/`).
- **Push:** Firebase Cloud Messaging + `push-notification` Edge Function (`PushDispatcher`).
- **Widget:** `home_widget` on Android (`PartnerWidgetProvider`).

Do not add a second routing library, a second state library, or a custom HTTP API alongside Supabase.

## Consequences

- Schema and RLS live in numbered SQL migrations; apply with `npx supabase` (see `AGENTS.md`, project `vkcoeudqeegnftkytiqd`).
- Web is not a target. Widget code must no-op on web/iOS where unsupported.

**Cross-refs:** [PRD](../prd/PRD-zero-miles.md), [ADR-0009](0009-android-ios-only.md)

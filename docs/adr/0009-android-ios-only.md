---
status: Accepted
---

# ADR-0009 Android and iOS only

## Context

`5de4f7e` restructured the client so it is not a multi-platform dump. Widget and FCM paths are mobile.

## Decision

Ship Android and iOS from `appcode/`. `syncHomeWidget` returns immediately on web. Do not add Windows/Web/desktop as product targets.

## Consequences

CI and local run instructions are `flutter run` on a device/emulator, not Chrome.

**Cross-refs:** [ADR-0001](0001-flutter-supabase-stack.md)

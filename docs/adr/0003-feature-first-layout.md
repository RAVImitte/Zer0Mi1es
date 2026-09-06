---
status: Accepted
---

# ADR-0003 Feature-first Flutter layout

## Context

The app has many domains (auth, couple, home, daily rituals, presence). A layer-first `data/` `domain/` `presentation/` tree at repo root mixed them.

## Decision

Organize under `appcode/lib/features/{name}/` with `data/`, `domain/`, `presentation/` **inside each feature**. Shared code lives in `appcode/lib/core/` (theme, routing, supabase providers, talk expiry).

Current features: `auth`, `avatar`, `canvas`, `connection`, `couple`, `daily_photo`, `daily_question`, `home`, `notifications`, `outfit`, `voice_drop`.

## Consequences

- New screens belong in an existing feature or a new feature folder — not a global `widgets/` dump.
- Home composes feature widgets; it does not own mood/talk SQL.

**Cross-refs:** [ADR-0001](0001-flutter-supabase-stack.md)

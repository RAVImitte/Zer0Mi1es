---
status: Accepted
---

# ADR-0007 Home is the hub (no bottom tabs)

## Context

Early UI notes described a bottom nav (Home / Question / Gallery / Settings). The shipped app does not have one.

## Decision

- Routes: `/` Home, `/couple`, `/daily_question`, `/outfit`, `/daily_photo`, `/canvas`, plus auth/profile/splash.
- Daily rituals open from Home’s daily-status row. Settings is a sheet. Voice and canvas are Home actions.
- Router redirects: no session → auth; `registration_status = signed_up` → profile setup. **Home is not blocked on pairing.** Unpaired Home shows a Pair seat; Kiss/Talk/etc. snackbar “Pair with your partner first”. Partner screen is Settings → Partner.

## Consequences

- Do not add a `BottomNavigationBar`. New surfaces hang off Home or a GoRoute from Home.

**Cross-refs:** [PRD](../prd/PRD-zero-miles.md)

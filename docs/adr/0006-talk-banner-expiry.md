---
status: Accepted
---

# ADR-0006 Compact talk banner and reply-based expiry

## Context

Talk requests used wrapping chips that covered the couple scene. Sender cards bounced (“Waiting…” after a reply). Pending pings never died.

## Decision

- One Home row: “{name} wants to call|text|video chat” + **Okay** + ⋯.
- Overflow: In a bit, Tonight, Not now (`talk_banner.dart`).
- Sender: “Waiting for {name}”, then “{name} said okay” (dismissible).
- Only the newest live ping is shown. Dismissed ids stay hidden locally.
- Pending max age: **8 hours**.
- Reply expiry (`talk_expiry.dart`): Okay **15m**, In a bit **1h**, Not now **2h**, Tonight until **6am** in the recipient IANA timezone.

## Consequences

- Ack writes `acknowledgeSignal` with status `yes` / `soon` / `tonight` / `not_now`.
- Do not put four equal chips on Home again.

**Cross-refs:** [SPEC-talk-requests](../specs/SPEC-talk-requests.md)

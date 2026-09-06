---
status: Accepted
---

# ADR-0004 Couple scene instead of a single-avatar FSM

## Context

V1 used `AvatarViewModel` + `watchPartnerEvents` to drive one partner circle. V2 Home shows **both** people. Merging the old FSM with the new puppet produced compile errors (`moodOverwhelmed`, StatelessWidget + State).

## Decision

- Presence is `coupleSceneProvider` (`CoupleSceneViewModel`).
- Inputs: `partnerStatusProvider` (mood, sleep, talk) and `loveDropsProvider` (flights).
- In-app drawing is `LayeredPersonAvatar` (puppet poses). Home and daily-question chips use it directly.
- **Do not reintroduce** `AvatarViewModel`, `AvatarEvent`, or `watchPartnerEvents`.
- Animation states in use: idle, sleeping, mood*, giving, receiving, leanIn, sorry. Pet/walk/talk FSM states are gone.

## Consequences

- Widget sleep reads `partnerStatus.partnerAsleep`, not an animation cache.
- Love-drop flights are scene state (`CoupleDrop`), not a global event bus.

**Cross-refs:** [ADR-0005](0005-puppet-vs-widget-painter.md), [SPEC-home-presence](../specs/SPEC-home-presence.md)

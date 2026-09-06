---
status: Accepted
---

# ADR-0010 Angry replaces Overwhelmed

## Context

The mood sheet had Overwhelmed. Product wanted Angry with a distinct stomp/scowl.

## Decision

- Sheet labels (2-column): Happy, Excited, Tired, Sad, **Angry**, Devastated.
- `AnimationState.moodAngry` / puppet pose + 💢 overlay.
- Persist `Angry` in `moods.mood`.
- Read path: `'Angry' || 'Overwhelmed'` still maps to Angry so old rows do not go idle.

## Consequences

Do not add Overwhelmed back to the sheet. Do not resurrect `moodOverwhelmed`.

**Cross-refs:** [SPEC-home-presence](../specs/SPEC-home-presence.md)

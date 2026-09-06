---
status: Accepted
---

# ADR-0005 Layered puppet in-app, PersonPainter only for the widget

## Context

The old `PersonPainter` + `flutter_animate` avatar and the layered puppet both existed after the UI-experiment + feature merge.

## Decision

- **In-app:** `LayeredPersonAvatar` + `PuppetPose` (ticker, blink, mood poses including Angry stomp + 💢).
- **Android widget snapshot:** `PersonPainter` in `person_painter.dart`, rendered through `HomeWidget.renderFlutterWidget`.
- `DynamicPersonAvatar` wrapper is deleted.

## Consequences

- Do not drive Home with `PersonPainter`. Do not run `flutter_animate` on the couple scene.
- Widget painter may stay a simpler 2D snapshot; it does not need puppet fidelity.

**Cross-refs:** [ADR-0008](0008-android-widget-no-talk.md)

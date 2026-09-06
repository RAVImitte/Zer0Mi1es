---
status: Accepted
---

# ADR-0008 Android widget is a presence snapshot, never talk or kisses

## Context

A home-screen widget should answer “how are they?” without leaking a call request or a flying kiss onto the launcher.

## Decision

`home_widget_sync.dart` may save:

- partner first name
- mood line
- scene label (dawn/day/dusk/night)
- sleeping flag
- outfit colors into `PersonPainter`

It must **not** snapshot talk banners or love-drop flights.

Provider: `com.example.zer0mi1es.PartnerWidgetProvider`. iOS widget is out of scope (later).

## Consequences

Listeners: partner name, mood, sleep, scene, outfit. No listen on talk or love drops for widget updates.

**Cross-refs:** [SPEC-android-widget](../specs/SPEC-android-widget.md)

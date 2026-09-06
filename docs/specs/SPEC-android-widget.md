# SPEC — Android partner presence widget

**Created:** 2026-09-06  
**Status:** As-built V2  
**ADRs:** [0008](../adr/0008-android-widget-no-talk.md), [0005](../adr/0005-puppet-vs-widget-painter.md), [0009](../adr/0009-android-ios-only.md)

## Goal

An Android home-screen widget shows partner name, mood, scene, sleep, and a painted avatar. It never shows talk or kisses.

## Background

`home_widget_sync.dart`, `PersonPainter`, `PartnerWidgetProvider` (`app.zeromiles.PartnerWidgetProvider`). `syncHomeWidget` no-ops on web and non-Android/iOS.

## Requirements

1. **Fields**: `widget_name`, `widget_mood`, `widget_scene`, rendered avatar key `widget_avatar`.
   - Acceptance: Mood line uses Happy/Sad/Heavy/Angry/Excited/Tired mapping; Overwhelmed → Angry

2. **Sleep**: `partnerAsleep` from `partnerStatusProvider`.
   - Acceptance: Widget painter `isSleeping` true when partner is asleep — not from deleted animation cache

3. **Outfit**: Partner top/bottom colors when a couple id exists.
   - Acceptance: Missing outfit falls back to indigo wash

4. **Forbidden**: No talk banner, no love-drop flight, no kiss emoji on the widget.
   - Acceptance: Listeners do not include talk or love-drop streams

5. **Lifecycle**: Bind listeners on Home; debounce 350ms; cancel on pause.
   - Acceptance: Backgrounding still attempts a last snapshot

## Boundaries

**In scope:** Android snapshot widget.

**Out of scope:** iOS widget (`iOSName` is reserved but not a V2 product). Interactive widget buttons that send talk.

## Acceptance Criteria

- [ ] Adding the widget shows partner first name and mood after Home has synced
- [ ] Sending a kiss does not change widget art to a flying drop
- [ ] An incoming call request does not appear on the widget

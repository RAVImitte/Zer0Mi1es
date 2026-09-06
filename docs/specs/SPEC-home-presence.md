# SPEC — Home couple scene, moods, love drops, sleep

**Created:** 2026-09-06  
**Status:** As-built V2  
**ADRs:** [0004](../adr/0004-couple-scene-presence.md), [0005](../adr/0005-puppet-vs-widget-painter.md), [0010](../adr/0010-angry-replaces-overwhelmed.md)

## Goal

Paired Home always shows both layered puppets with live mood, sleep, and love-drop flights.

## Background

`PartnerPresence` + `CoupleSceneViewModel` + `LayeredPersonAvatar`. Connection actions: Kiss, Hug, Sorry, Mood, Talk, Sleep/Wake, Voice, Canvas.

## Requirements

1. **Two seats**: Left = not bunny, right = bunny. Labels You vs partner first/full name. Unpaired opposite seat is Pair.
   - Acceptance: Two `LayeredPersonAvatar`s when paired; one Pair affordance when not

2. **Moods**: Sheet is 2×3: Happy, Excited, Tired, Sad, Angry, Devastated. Writes `moods.mood`.
   - Acceptance: Angry plays stomp + 💢. Stored Overwhelmed still animates as Angry

3. **Love drops**: Kiss / Hug / Sorry (long-press note + emoji). `playDrop` on the couple scene; hug = both leanIn; sorry = sender sorry pose; else giving/receiving + flying emoji for 2.5s.
   - Acceptance: Sender sees toast; receiver sees flight; no `AvatarViewModel`

4. **Sleep**: Good Night / Good Morning signals. Optimistic `setMyAsleep`. Caption “Sleeping”.
   - Acceptance: Sleep survives app restart via `partnerStatus` (not animation cache)

5. **Lighting**: `partnerSceneProvider` dawn/day/dusk/night wash on Home.
   - Acceptance: Background follows local time-of-day helper

6. **Drawing**: In-app avatars are puppets only.
   - Acceptance: No `PersonPainter` on Home; no `DynamicPersonAvatar`

## Boundaries

**In scope:** Couple scene, moods, drops, sleep, sanctuary wash.

**Out of scope:** Talk banner (see [SPEC-talk-requests](SPEC-talk-requests.md)). Widget painter (see [SPEC-android-widget](SPEC-android-widget.md)). Pets / walk FSM — deleted.

## Acceptance Criteria

- [ ] Both avatars visible on a paired Home
- [ ] Mood sheet has Angry, not Overwhelmed
- [ ] Kiss/Hug/Sorry fly or lean without covering talk as chips
- [ ] Sleep pose + Zzz; wake restores mood/idle
- [ ] `grep AvatarViewModel appcode/lib` is empty

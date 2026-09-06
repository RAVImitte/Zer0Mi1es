# Roadmap: Zero Miles

## Overview

Zero Miles already ships V1 and V2 on `main` (`2.0.0+2`). This milestone does not rebuild auth, pairing, Home, rituals, widget, voice, or canvas. It hardens partner-visible status — mood, presence/sleep, pairing, daily unlock, talk banner, love drops, and the Android widget — so Home, widget, and backend never collide or drop data. Work follows the couple loop: lock identity, keep the Home scene honest, make live signals collision-free, keep daily give-to-get airtight, then make the widget and persisted media match without loss.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Couple Identity & Private Sanctuary** - Partners sign in as themselves, pair as exactly two, and never leak couple data or secrets
- [ ] **Phase 2: Home Hub Couple Scene** - Home is the only hub; both seats stay live puppets with time-of-day lighting and persistent sleep
- [ ] **Phase 3: Live Signals Without Collisions** - Mood, love drops, and talk banners stay in sync on both phones with no ghost echoes or lost acks
- [ ] **Phase 4: Daily Rituals Without Leaks** - Question, photo, and outfit stay give-to-get; partner content is unreadable until I contribute
- [ ] **Phase 5: Widget & Media Without Data Loss** - Android widget mirrors presence (never talk/kisses); voice and canvas survive without silent loss

## Phase Details

### Phase 1: Couple Identity & Private Sanctuary
**Goal**: Partners can sign in as themselves, bind as exactly two people, and never leak couple data or secrets
**Depends on**: Nothing (first phase)
**Requirements**: REQ-auth-v1, REQ-couple-pairing, REQ-private-sanctuary, REQ-secrets-not-in-git
**Success Criteria** (what must be TRUE):
  1. Unauthenticated user cannot reach Home; they land on auth, can sign up/in with email and password, set a name, and then reach Home (not stuck on profile setup); local IANA timezone syncs so Tonight expiry can use it
  2. Partner A mints a 6-character code; partner B joins as bunny; a third account cannot join; self-join and invalid/expired/used codes fail; minting a code does not create a couple row
  3. Unpaired Home stays usable with a Pair seat (not a dummy body); already-paired user cannot mint another code; Kiss/Talk from unpaired Home tells them to pair first
  4. A third signed-in user querying by guessed `couple_id` gets zero rows; the Flutter app has no service-role key; `.env` is gitignored; no public feed, friends list, or social sharing exists
**Plans**: TBD
**UI hint**: yes

### Phase 2: Home Hub Couple Scene
**Goal**: Both partners always see a two-seat Home hub (no tabs) with live puppets, sanctuary lighting, and sleep that survives restart
**Depends on**: Phase 1
**Requirements**: REQ-home-couple-scene, REQ-home-hub-no-tabs
**Success Criteria** (what must be TRUE):
  1. Paired Home shows two layered puppets (bear left / bunny right) labeled You vs partner name; unpaired opposite seat is Pair, not a dummy body
  2. Daily question, photo, outfit, voice, canvas, and settings open from Home; no bottom tab bar exists
  3. Home background follows local dawn / day / dusk / night; Good Night shows sleep pose + Zzz after app restart; Good Morning restores mood/idle
  4. Home seats stay on screen with live poses after navigating away and back; presence is not dropped and Home is not drawn with the widget painter
**Plans**: TBD
**UI hint**: yes

### Phase 3: Live Signals Without Collisions
**Goal**: Mood, love drops, and talk banners stay consistent for both partners with no ghost echoes, lost acks, or overlapping UI
**Depends on**: Phase 2
**Requirements**: REQ-moods, REQ-love-drops-v1, REQ-talk-requests
**Success Criteria** (what must be TRUE):
  1. A sets Angry → B’s Home avatar stomps with 💢; mood sheet is Happy, Excited, Tired, Sad, Angry, Devastated (no Overwhelmed); a stored Overwhelmed row still shows as Angry
  2. A sends kiss, hug, or sorry → it flies or leans on B’s Home; A sees a toast and does not get a ghost echo; hugs lean both seats; drops never cover talk as chips
  3. A taps call (or text / video) → B sees one line “{name} wants to call” + Okay + ⋯ that never wraps over the avatars; B taps Okay → A’s card becomes “{name} said okay” without flashing Waiting
  4. Only the newest live talk is shown; pending older than 8 hours disappears; replies expire Okay 15m / In a bit 1h / Not now 2h / Tonight until 6am in the recipient’s IANA timezone; dismissed pings stay hidden
**Plans**: TBD
**UI hint**: yes

### Phase 4: Daily Rituals Without Leaks
**Goal**: Daily question, photo, and outfit stay give-to-get: partner content is unreadable until I contribute, and outfit colors reach both seats without dropped saves
**Depends on**: Phase 2
**Requirements**: REQ-daily-question, REQ-daily-photo-outfit
**Success Criteria** (what must be TRUE):
  1. Partner’s daily-question answer stays hidden until I submit mine; Home daily-status icon opens the question; reveal still requires both answers even if the client sends a guess
  2. Partner photo metadata is unreadable until I upload mine (policy, not just a blur); uploading mine unlocks theirs
  3. Outfit top and bottom colors tint both Home puppets after save and are not lost on restart
  4. A third account cannot read another couple’s daily question, photo, or outfit rows
**Plans**: TBD
**UI hint**: yes

### Phase 5: Widget & Media Without Data Loss
**Goal**: Android widget mirrors partner presence (never talk or kisses), and voice/canvas persist without silent loss
**Depends on**: Phase 3, Phase 4
**Requirements**: REQ-android-widget, REQ-voice-canvas
**Success Criteria** (what must be TRUE):
  1. After Home has synced, the Android widget shows partner first name, mood line, scene, sleep, and outfit colors (indigo wash if outfit is missing); Overwhelmed maps to Angry; sleep is not read from a deleted animation cache
  2. Sending a kiss does not change widget art to a flying drop; an incoming talk request does not appear on the widget; widget listeners do not include talk or love-drop streams
  3. Partner can record a 1–15s voice note from Home; the other hears it on a Home chip; longer than 15s cannot be stored; after 24h it is not readable
  4. Shared canvas strokes remain after both apps restart and after a partner was offline; the mural is not lost
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Couple Identity & Private Sanctuary | 0/? | Not started | - |
| 2. Home Hub Couple Scene | 0/? | Not started | - |
| 3. Live Signals Without Collisions | 0/? | Not started | - |
| 4. Daily Rituals Without Leaks | 0/? | Not started | - |
| 5. Widget & Media Without Data Loss | 0/? | Not started | - |

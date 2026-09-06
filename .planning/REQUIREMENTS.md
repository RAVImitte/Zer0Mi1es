# Requirements: Zero Miles

**Defined:** 2026-09-06
**Core Value:** Partner-visible status stays consistent across Home, Android widget, and backend — no collisions, no dropped writes, no ghost echoes.

Canonical v1 IDs come from `docs/prd/PRD-zero-miles.md`. Features already ship on `main`; v1 checkboxes close when the mapped hardening phase proves them on two phones without collisions or data loss.

## v1 Requirements

Requirements for this consistency milestone. Each maps to exactly one roadmap phase.

### Authentication

- [ ] **REQ-auth-v1**: Partner can sign up and sign in with email and password, set a display name, and sync local IANA timezone. Unauthenticated users cannot reach Home (they land on auth). Empty email/password does not submit. After sign-up, `registration_status = signed_up` goes to profile setup until a name is stored; named users are not stuck there. Phone OTP is out of scope.

### Pairing & Sanctuary

- [ ] **REQ-couple-pairing**: Partner can create or join a couple with a 6-character code (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, 24h, hashed at rest). Creator is bear, joiner is bunny. Two users per couple; no groups. Invalid / expired / used token fails. Self-join fails. A third account cannot join an already-paired couple. Minting a code does not create a couple row; Home stays usable unpaired (Pair seat).
- [ ] **REQ-private-sanctuary**: After pairing, every feature is couple-scoped. No feed, no friends list, no social sharing. A third signed-in user querying by guessed `couple_id` gets zero rows. Writes cannot spoof a partner mood row.
- [ ] **REQ-secrets-not-in-git**: Supabase URL and anon key come from dart-defines / `.env` (gitignored). The Flutter app never embeds a service-role key. Push invoke uses the user JWT.

### Home

- [ ] **REQ-home-couple-scene**: Paired Home always shows two layered person puppets (left = not bunny, right = bunny) with You vs partner name, live mood poses, sanctuary lighting (dawn / day / dusk / night), and sleep that survives app restart via `partnerStatus`. Unpaired empty seat is Pair, not a dummy body. In-app drawing is puppets only (no `AvatarViewModel`, no Home `PersonPainter`).
- [ ] **REQ-home-hub-no-tabs**: Home is the hub. Daily question / photo / outfit, voice, canvas, and settings open from Home. No bottom tab bar. Unpaired Home is reachable; Kiss/Talk/etc. snackbar “Pair with your partner first”.

### Live presence

- [ ] **REQ-moods**: Partner can set mood from a 2×3 sheet: Happy, Excited, Tired, Sad, Angry, Devastated. Angry plays stomp + 💢. Stored Overwhelmed still animates as Angry. Partner sees the mood on Home and (on Android) the widget.
- [ ] **REQ-love-drops-v1**: Partner can send kiss, hug, or sorry (optional long-press note + emoji) and see it land on the other Home. Hug = both lean in; sorry = sender sorry pose; else giving/receiving + flying emoji. Sender sees a toast; receiver sees the flight; sender does not get a ghost echo. Drops never cover talk as chips. No Heart drop.
- [ ] **REQ-talk-requests**: Partner can ping text / call / video and see a compact Home reply. Incoming is one line `{name} wants to text|call|video chat` + Okay + ⋯ and never wraps over the avatars. Sender sees `Waiting for {name}`, then the named reply, without flashing Waiting. Only the newest live ping is shown. Pending older than 8 hours is hidden. Replies expire Okay 15m / In a bit 1h / Not now 2h / Tonight until 6am in the recipient IANA timezone. The app signals intent only — it does not place a PSTN call.

### Daily rituals

- [ ] **REQ-daily-question**: Partners get one daily question. Partner answer text stays hidden until I submit mine (`has_user_answered` RLS). Unlock is answer-based, not guess-based (client may still send `guess`; schema gap must not leak or drop answers). Home daily-status icon routes to `/daily_question`.
- [ ] **REQ-daily-photo-outfit**: Partners share a daily photo and outfit colors. Partner photo metadata is unreadable until I upload mine (RLS, not only a blur overlay). Outfit top/bottom colors tint both Home puppets after save and feed the Android widget (indigo wash if missing). Home daily-status icons route to `/daily_photo` and `/outfit`.

### Widget & media

- [ ] **REQ-android-widget**: On Android, a home-screen widget shows partner first name, mood, scene, sleep, and outfit avatar snapshot after Home has synced. It never renders a talk request or a kiss/love-drop flight. Sleep comes from `partnerStatus`, not animation cache. Listeners do not include talk or love-drop streams. iOS widget is out of scope.
- [ ] **REQ-voice-canvas**: From Home, partner can send a voice note (1–15000 ms, private `voice` bucket, 24h expiry) and doodle on a shared canvas whose `strokes` jsonb survive restart and offline. Voice longer than 15s cannot be stored. Voice older than 24h is not readable. Partner hears inbound unexpired clips on a Home chip.

## v2 Requirements

Deferred later by the canonical PRD. Tracked here so they are not silently reintroduced as v1.

- iOS home-screen widget (`iOSName` reserved; not a V2 product)
- Shared calendar / countdowns
- Shared playlists

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| REQ-auth-v2 (phone/email auth) | Superseded archive PRD (`docs/archive/legacy-guides/prd_guide.md`); canonical PRD + SPEC-auth-pairing exclude phone OTP |
| REQ-love-drops-v2 (Heart 💖 drop) | Superseded archive PRD; SPEC-home-presence lists Kiss / Hug / Sorry only |
| REQ-daily-question-history-legacy | Archive-only; no acceptance criteria; canonical PRD does not define history |
| REQ-photo-reactions-legacy | Archive-only; no acceptance criteria; canonical PRD does not define photo reactions |
| REQ-unpairing-account-deletion-legacy | Archive-only; no acceptance criteria; delete-account SQL is teardown, not this milestone’s product surface |
| Phone-number auth | Canonical PRD: code is email + password |
| Bottom tab bar | ADR-0007; Home is the hub |
| Pets / walk / talk FSM / `AvatarViewModel` | Deleted in V2; presence is the couple scene |
| Public feed, friends list, social sharing | Product is a two-person sanctuary |
| Interactive widget buttons that send talk | ADR-0008; widget is a snapshot |
| Windows / Web / desktop targets | ADR-0009; Android + iOS only |
| E2E encryption beyond TLS + RLS | SPEC-security out of scope |
| PSTN / cellular calling | Talk is an intent signal only |
| Voice transcription, infinite voice gallery, canvas vector export | SPEC-voice-canvas out of scope |
| Public gallery / multi-day social photo grid | SPEC-daily-rituals out of scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-auth-v1 | Phase 1 | Pending |
| REQ-couple-pairing | Phase 1 | Pending |
| REQ-private-sanctuary | Phase 1 | Pending |
| REQ-secrets-not-in-git | Phase 1 | Pending |
| REQ-home-couple-scene | Phase 2 | Pending |
| REQ-home-hub-no-tabs | Phase 2 | Pending |
| REQ-moods | Phase 3 | Pending |
| REQ-love-drops-v1 | Phase 3 | Pending |
| REQ-talk-requests | Phase 3 | Pending |
| REQ-daily-question | Phase 4 | Pending |
| REQ-daily-photo-outfit | Phase 4 | Pending |
| REQ-android-widget | Phase 5 | Pending |
| REQ-voice-canvas | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-06*
*Last updated: 2026-09-06 after roadmap creation*

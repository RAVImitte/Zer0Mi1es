# Constraints

Extracted from classified SPECs. Types are api-contract | schema | nfr | protocol.

## Email auth
- source: docs/specs/SPEC-auth-pairing.md
- type: api-contract
- content: Sign up and sign in with email + password (`AuthScreen`). Empty email/password does not submit; `AuthException` surfaces in UI. Phone OTP is not in `AuthScreen` and is out of scope. No session → only `/auth` (and splash while loading).

## Profile setup redirect
- source: docs/specs/SPEC-auth-pairing.md
- type: api-contract
- content: After sign-up, `registration_status = signed_up` redirects to `/profile-setup` until a name is stored. Named users are not stuck on profile setup; splash/auth bounce to Home.

## Timezone sync
- source: docs/specs/SPEC-auth-pairing.md
- type: protocol
- content: After Home loads, local IANA timezone is synced to the profile (`FlutterTimezone` + `syncTimezone`). Talk “Tonight” expiry can use that IANA name.

## Create pairing code
- source: docs/specs/SPEC-auth-pairing.md
- type: schema
- content: `create_couple_with_token` inserts a hashed token only (no couple row). Alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, 6 chars, 24h. Unused prior tokens for that user are deleted. Already-paired user cannot mint a code. Home stays usable unpaired (Pair seat). Couple row appears only after a successful join, not when minting a code.

## Join pairing code
- source: docs/specs/SPEC-auth-pairing.md
- type: schema
- content: Joiner enters 6 characters. `join_couple_with_token` creates `couples` with creator = bear, joiner = bunny, marks token used, seeds first daily question. Invalid / expired / used token fails. Self-join fails. Third user fails. 6-character join field; wrong length shows snackbar. Couple is two people max; token is single-use.

## Bear and bunny seats
- source: docs/specs/SPEC-auth-pairing.md
- type: protocol
- content: Left Home seat is not bunny; bunny is the right seat (`CoupleRole.bear` / `bunny`). Both partners see You vs partner name on the correct seat. Unpaired Home offers Pair instead of a second dummy avatar. Router does not lock Home until paired (ADR-0007).

## Delete account path
- source: docs/specs/SPEC-auth-pairing.md
- type: api-contract
- content: Migration `18_delete_account.sql` exists for teardown. Account deletion is a supported server path, not only a local sign-out.

## RLS membership
- source: docs/specs/SPEC-security.md
- type: nfr
- content: SELECT on couple tables requires `auth.uid()` in `bear_id` or `bunny_id`. A third signed-in user querying by guessed `couple_id` gets zero rows. RLS on `love_drops`, `moods`, `connection_signals`, `daily_*`, `voice_drops`, `canvases`, `pairing_tokens`. Third account cannot SELECT the couple’s moods/photos. Third account cannot join a full couple.

## Write ownership
- source: docs/specs/SPEC-security.md
- type: nfr
- content: INSERT/UPDATE require `user_id` or `sender_id` = `auth.uid()`. Cannot spoof a partner mood row.

## Photo lock RLS
- source: docs/specs/SPEC-security.md
- type: nfr
- content: Partner photo row unreadable until the reader has uploaded that date. Policy, not only a blur overlay.

## Hashed pairing tokens
- source: docs/specs/SPEC-security.md
- type: nfr
- content: Pairing tokens stored hashed; raw 6-char code is ephemeral. DB leak of `token_hash` is not the join code.

## No service-role in client
- source: docs/specs/SPEC-security.md
- type: nfr
- content: Supabase URL/anon key via dart-define / `.env`; `.env` gitignored. No service-role key in the Flutter app. Flutter binary does not embed a service role key.

## JWT push invoke
- source: docs/specs/SPEC-security.md
- type: nfr
- content: `functions.invoke('push-notification')` with user JWT. No animation-cache side channel (`partnerAnimationTable` removed). Push still delivers; no SharedPreferences animation table writes. E2E encryption beyond TLS + RLS is out of scope.

## Two Home seats
- source: docs/specs/SPEC-home-presence.md
- type: api-contract
- content: Left = not bunny, right = bunny. Labels You vs partner first/full name. Unpaired opposite seat is Pair. Two `LayeredPersonAvatar`s when paired; one Pair affordance when not. Both avatars visible on a paired Home.

## Mood sheet and Angry
- source: docs/specs/SPEC-home-presence.md
- type: protocol
- content: Sheet is 2×3: Happy, Excited, Tired, Sad, Angry, Devastated. Writes `moods.mood`. Angry plays stomp + 💢. Stored Overwhelmed still animates as Angry. Mood sheet has Angry, not Overwhelmed.

## Love-drop flights
- source: docs/specs/SPEC-home-presence.md
- type: protocol
- content: Kiss / Hug / Sorry (long-press note + emoji). `playDrop` on the couple scene; hug = both leanIn; sorry = sender sorry pose; else giving/receiving + flying emoji for 2.5s. Sender sees toast; receiver sees flight; no `AvatarViewModel`. Kiss/Hug/Sorry fly or lean without covering talk as chips. Pets / walk FSM deleted.

## Sleep persistence
- source: docs/specs/SPEC-home-presence.md
- type: protocol
- content: Good Night / Good Morning signals. Optimistic `setMyAsleep`. Caption “Sleeping”. Sleep survives app restart via `partnerStatus` (not animation cache). Sleep pose + Zzz; wake restores mood/idle.

## Sanctuary lighting
- source: docs/specs/SPEC-home-presence.md
- type: protocol
- content: `partnerSceneProvider` dawn/day/dusk/night wash on Home. Background follows local time-of-day helper.

## In-app drawing is puppets only
- source: docs/specs/SPEC-home-presence.md
- type: api-contract
- content: In-app avatars are puppets only. No `PersonPainter` on Home; no `DynamicPersonAvatar`. `grep AvatarViewModel appcode/lib` is empty.

## Talk send
- source: docs/specs/SPEC-talk-requests.md
- type: protocol
- content: Talk sheet: Text → `text`, Call → `call`, Video → `video_call`. Partner gets a pending signal + push. The app signals intent only; it does not place a PSTN/cellular call. Widget must not show talk (ADR-0008).

## Talk incoming copy
- source: docs/specs/SPEC-talk-requests.md
- type: protocol
- content: `{name} wants to text|call|video chat` + Okay + ⋯. Single row; Okay is `yes`; ⋯ opens In a bit / Tonight / Not now. Incoming banner is one line with Okay + overflow.

## Talk sender copy
- source: docs/specs/SPEC-talk-requests.md
- type: protocol
- content: Pending → `Waiting for {name}` (dismissible). After reply → `{name} said okay` / `will be there in a bit` / `said tonight` / `can’t right now`. Sender card updates without flashing Waiting after a live ack.

## Talk newest-only
- source: docs/specs/SPEC-talk-requests.md
- type: protocol
- content: Only the current live talk from `partnerStatus.talk` is shown. Local dismiss set hides it. Old pending pings are not resurrected as Waiting.

## Talk expiry
- source: docs/specs/SPEC-talk-requests.md
- type: protocol
- content: Pending older than 8 hours hidden. Replies: yes 15m, soon 1h, not_now 2h, tonight until 6am local IANA. `talkReplyExpiry` matches those durations. Tonight uses 6am in profile timezone when available.

## Android widget fields
- source: docs/specs/SPEC-android-widget.md
- type: api-contract
- content: Fields: `widget_name`, `widget_mood`, `widget_scene`, rendered avatar key `widget_avatar`. Mood line uses Happy/Sad/Heavy/Angry/Excited/Tired mapping; Overwhelmed → Angry. Adding the widget shows partner first name and mood after Home has synced.

## Android widget sleep
- source: docs/specs/SPEC-android-widget.md
- type: api-contract
- content: `partnerAsleep` from `partnerStatusProvider`. Widget painter `isSleeping` true when partner is asleep — not from deleted animation cache.

## Android widget outfit
- source: docs/specs/SPEC-android-widget.md
- type: api-contract
- content: Partner top/bottom colors when a couple id exists. Missing outfit falls back to indigo wash.

## Android widget forbidden content
- source: docs/specs/SPEC-android-widget.md
- type: api-contract
- content: No talk banner, no love-drop flight, no kiss emoji on the widget. Listeners do not include talk or love-drop streams. Sending a kiss does not change widget art to a flying drop. An incoming call request does not appear on the widget. iOS widget (`iOSName` is reserved but not a V2 product). Interactive widget buttons that send talk are out of scope.

## Android widget lifecycle
- source: docs/specs/SPEC-android-widget.md
- type: api-contract
- content: Bind listeners on Home; debounce 350ms; cancel on pause. Backgrounding still attempts a last snapshot. `syncHomeWidget` no-ops on web and non-Android/iOS.

## Daily question row
- source: docs/specs/SPEC-daily-rituals.md
- type: schema
- content: `generate_daily_questions()` (cron) inserts today’s `daily_connections` if missing. Even `days_elapsed` → bear is `creator_id`, else bunny. Join seeds the first question with the token creator as creator. Statuses: waitingForCron, readyToAnswer, waitingForPartner, revealed. Partner answer text is not shown until both have answered (`has_user_answered` RLS). Cannot read partner question answer before submitting mine.

## Daily guess schema gap
- source: docs/specs/SPEC-daily-rituals.md
- type: schema
- content: App submits `guess` on answers. In-repo migrations do not ADD COLUMN `guess` — treat as a schema gap vs client; reveal still requires both answers. Unlock is answer-based, not guess-based.

## Daily photo lock
- source: docs/specs/SPEC-daily-rituals.md
- type: schema
- content: `daily_photos` RLS: cannot SELECT partner’s row for `date` unless the reader has a row for that couple+date. UI blur/lock matches RLS; uploading mine unlocks theirs. Cannot read partner photo metadata before uploading mine (policy, not just UI).

## Daily outfit colors
- source: docs/specs/SPEC-daily-rituals.md
- type: schema
- content: `daily_outfits` top_color / bottom_color tint the puppets via `myOutfitProvider` / `partnerOutfitProvider`. Home avatars pick up colors after save; widget uses partner outfit. Outfit colors show on both Home puppets.

## Daily ritual entry from Home
- source: docs/specs/SPEC-daily-rituals.md
- type: api-contract
- content: Home daily-status icons route to `/daily_question`, `/daily_photo`, `/outfit`. No bottom tab required. Public gallery and multi-day grid social feed are out of scope.

## Voice record
- source: docs/specs/SPEC-voice-canvas.md
- type: schema
- content: Home Voice action opens `showVoiceRecordSheet`. Duration `duration_ms` 1–15000. Storage `{coupleId}/{uid}/{id}.m4a` in private `voice` bucket. Default `expires_at` = now()+24h. Insert rejected if duration > 15s. SELECT only while `expires_at > now()`. Voice longer than 15s cannot be stored. Voice older than 24h is not readable. Voice transcription and infinite gallery of old voice notes are out of scope.

## Voice play
- source: docs/specs/SPEC-voice-canvas.md
- type: api-contract
- content: `VoicePlayChip` on Home for inbound unexpired partner rows (signed URL ~1h). Partner hears the clip; expired rows disappear from RLS.

## Persisted canvas strokes
- source: docs/specs/SPEC-voice-canvas.md
- type: schema
- content: `/canvas` from Home. Source of truth is `canvases.strokes` jsonb + Realtime (`27_canvas_strokes.sql`). `storage_path` / `canvas` bucket are vestigial — the app does not upload a PNG. Partner opening canvas after being offline still sees saved strokes. Canvas strokes remain after both apps restart. Vector export is out of scope.

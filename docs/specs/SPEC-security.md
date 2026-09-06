# SPEC — Security and privacy

**Created:** 2026-09-06  
**Status:** As-built  
**ADRs:** [0002](../adr/0002-couple-private-rls.md)

## Goal

All couple data is readable only by the two paired users. No social graph.

## Background

RLS on `love_drops`, `moods`, `connection_signals`, `daily_*`, `voice_drops`, `canvases`, `pairing_tokens`. Storage policies on photo and voice buckets. Push Edge Function is invoked by the authenticated client (`PushDispatcher`) with table+record; JWT required after `ea863d7`.

## Requirements

1. **RLS membership**: SELECT on couple tables requires `auth.uid()` in `bear_id` or `bunny_id`.
   - Acceptance: A third signed-in user querying by guessed `couple_id` gets zero rows

2. **Write ownership**: INSERT/UPDATE require `user_id` or `sender_id` = `auth.uid()`.
   - Acceptance: Cannot spoof a partner mood row

3. **Photo lock**: Partner photo row unreadable until the reader has uploaded that date.
   - Acceptance: Policy, not only a blur overlay

4. **Tokens**: Pairing tokens stored hashed; raw 6-char code is ephemeral.
   - Acceptance: DB leak of `token_hash` is not the join code

5. **Secrets**: Supabase URL/anon key via dart-define / `.env`; `.env` gitignored.
   - Acceptance: No service-role key in the Flutter app

6. **Push**: `functions.invoke('push-notification')` with user JWT. No animation-cache side channel (`partnerAnimationTable` removed).
   - Acceptance: Push still delivers; no SharedPreferences animation table writes

## Boundaries

**In scope:** RLS, hashed tokens, private storage, JWT push, no social sharing.

**Out of scope:** E2E encryption beyond TLS + RLS. Moderation tooling.

## Acceptance Criteria

- [ ] Third account cannot join a full couple
- [ ] Third account cannot SELECT the couple’s moods/photos
- [ ] Flutter binary does not embed a service role key

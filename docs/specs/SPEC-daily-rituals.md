# SPEC — Daily question, photo, and outfit

**Created:** 2026-09-06  
**Status:** As-built V1 (still current)  
**ADRs:** [0002](../adr/0002-couple-private-rls.md), [0007](../adr/0007-home-hub-no-tabs.md)

## Goal

Each day the couple shares one question, one photo, and outfit colors, with give-to-get unlock.

## Background

`daily_question/`, `daily_photo/`, `outfit/`. Home `DailyStatus` is the entry. Migrations `06_daily_questions.sql`, `07_cron_daily_state.sql`, `10_phase6_outfits_photos.sql`, plus later RLS/logic fixes.

## Requirements

1. **Question row**: `generate_daily_questions()` (cron) inserts today’s `daily_connections` if missing. Even `days_elapsed` → bear is `creator_id`, else bunny. Join seeds the first question with the **token creator** as creator. Statuses: waitingForCron, readyToAnswer, waitingForPartner, revealed.
   - Acceptance: Partner answer text is not shown until both have answered (`has_user_answered` RLS)

2. **Guess**: App submits `guess` on answers. **In-repo migrations do not ADD COLUMN `guess`** — treat as a schema gap vs client; reveal still requires both answers.
   - Acceptance: Unlock is answer-based, not guess-based

3. **Photo lock**: `daily_photos` RLS: cannot SELECT partner’s row for `date` unless the reader has a row for that couple+date.
   - Acceptance: UI blur/lock matches RLS; uploading mine unlocks theirs

4. **Outfit**: `daily_outfits` top_color / bottom_color tint the puppets via `myOutfitProvider` / `partnerOutfitProvider`.
   - Acceptance: Home avatars pick up colors after save; widget uses partner outfit

5. **Entry**: Home daily-status icons route to `/daily_question`, `/daily_photo`, `/outfit`.
   - Acceptance: No bottom tab required

## Boundaries

**In scope:** Daily question, photo, OOTD colors, photo lock.

**Out of scope:** Public gallery, multi-day grid social feed.

## Acceptance Criteria

- [ ] Cannot read partner question answer before submitting mine
- [ ] Cannot read partner photo metadata before uploading mine (policy, not just UI)
- [ ] Outfit colors show on both Home puppets

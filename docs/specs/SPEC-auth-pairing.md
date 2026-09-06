# SPEC — Auth, profile, and couple pairing

**Created:** 2026-09-06  
**Status:** As-built on `main` (`2.0.0+2`)  
**ADRs:** [0001](../adr/0001-flutter-supabase-stack.md), [0002](../adr/0002-couple-private-rls.md)

## Goal

A user can create an account with email/password, set a display name, and bind to exactly one partner via a 6-character pairing code.

## Background

Code: `features/auth`, `features/couple`, migrations `01_auth_profiles.sql`, `02_couple_pairing.sql`, `18_delete_account.sql`, `19_add_registration_status.sql`. Router does **not** lock Home until paired; Home shows a Pair seat (`ADR-0007`).

## Requirements

1. **Email auth**: Sign up and sign in with email + password (`AuthScreen`).
   - Current: implemented
   - Target: same
   - Acceptance: Empty email/password does not submit; `AuthException` surfaces in UI

2. **Profile setup**: After sign-up, `registration_status = signed_up` redirects to `/profile-setup` until a name is stored.
   - Acceptance: Named users are not stuck on profile setup; splash/auth bounce to Home

3. **Timezone**: After Home loads, local IANA timezone is synced to the profile (`FlutterTimezone` + `syncTimezone`).
   - Acceptance: Talk “Tonight” expiry can use that IANA name

4. **Create code**: `create_couple_with_token` inserts a hashed token only (no couple row). Alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, 6 chars, 24h. Unused prior tokens for that user are deleted.
   - Acceptance: Already-paired user cannot mint a code. Home stays usable unpaired (Pair seat).

5. **Join code**: Joiner enters 6 characters. `join_couple_with_token` creates `couples` with **creator = bear**, **joiner = bunny**, marks token used, seeds first daily question.
   - Acceptance: Invalid / expired / used token fails. Self-join fails. Third user fails.

6. **Seats**: Left Home seat is not bunny; bunny is the right seat (`CoupleRole.bear` / `bunny`).
   - Acceptance: Both partners see You vs partner name on the correct seat

7. **Delete account**: Migration `18_delete_account.sql` exists for teardown.
   - Acceptance: Account deletion is a supported server path, not only a local sign-out

## Boundaries

**In scope:** Email auth, name, timezone, 6-char pairing, bear/bunny, delete account.

**Out of scope:** Phone OTP (not in `AuthScreen`) — not implemented. Forcing `/couple` before Home — router does not do this.

## Acceptance Criteria

- [ ] No session → only `/auth` (and splash while loading)
- [ ] `signed_up` → `/profile-setup`
- [ ] 6-character join field; wrong length shows snackbar
- [ ] Couple is two people max; token is single-use
- [ ] Unpaired Home offers Pair instead of a second dummy avatar
- [ ] Couple row appears only after a successful join, not when minting a code

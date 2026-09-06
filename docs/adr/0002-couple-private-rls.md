---
status: Accepted
---

# ADR-0002 Couple-private data with Postgres RLS

## Context

The product is a closed loop of two people. A third user must not read photos, moods, talk pings, or canvas strokes.

## Decision

- Every couple-owned table enables RLS.
- Typical policy: `couple_id IN (SELECT id FROM couples WHERE bear_id = auth.uid() OR bunny_id = auth.uid())`.
- Writes further require `user_id` / `sender_id` = `auth.uid()`.
- Pairing RPCs (`20_fix_pending_couples.sql`): `create_couple_with_token` stores a hashed token only (no couple row). `join_couple_with_token` creates the couple: **creator = bear**, **joiner = bunny**, marks the token used.
- Raw token is 6 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I/O/0/1), SHA-256 hashed, 24h TTL. Creating a new code deletes the user’s unused tokens.
- A user may belong to at most one couple. Self-join is rejected. A used token cannot admit a third person.
- Storage buckets for photos and voice are private; object paths are scoped to couple id + user id.

## Consequences

- Client repositories never bypass RLS with a service role.
- Recursion bugs in couple-membership subqueries were fixed in later migrations (`08_fix_rls_recursion.sql`, photo/outfit follow-ups). New policies must avoid recursive `couples` selects that re-enter the same policies.
- Photo lock is enforced in RLS (partner row unreadable until the reader has a row for that date), not only in UI.

**Cross-refs:** [SPEC-auth-pairing](../specs/SPEC-auth-pairing.md), [SPEC-security](../specs/SPEC-security.md)

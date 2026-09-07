# Zero Miles privacy policy

**Last updated:** 2026-09-07  
**Product:** Zero Miles, a two-person couple app for Android and iOS  
**Contact:** support@zeromiles.app

This policy describes what Zero Miles stores and who can see it. A public HTTPS copy of this document must be hosted before a Play production-track listing. This repository does not publish that URL.

## Who it is for

Zero Miles is a closed loop for two paired partners. There is no social graph, public profile, friends list, feed, or discovery. A third account cannot join a full couple and cannot read that couple’s rows.

## What we collect

| Data | Why | Where |
|---|---|---|
| Email and password | Account sign-in | Supabase Auth (password hashed by the provider) |
| Display name, timezone | Show you as you; talk “Tonight” expiry | `profiles` |
| FCM token | Deliver push to this device | `profiles.fcm_token` |
| Pairing codes | Bind exactly two people | Hashed tokens, 24-hour TTL |
| Photos | Daily photo ritual | Private storage, couple-scoped |
| Voice notes | Short voice drops (≤15s) | Private storage; table rows hidden after 24 hours |
| Moods, daily answers, outfits, canvas strokes, talk/sleep pings, love drops | Couple features | Postgres, couple-scoped via RLS |

We do not collect a contacts list, location history, or advertising identifiers for ads.

## Who can see it

Couple content is readable only by the two paired users. Postgres **row-level security (RLS)** requires `auth.uid()` to be `bear_id` or `bunny_id` on the couple (or the row owner on write). Photo metadata for a date stays unreadable to a partner until that partner has uploaded their own photo for the same date.

We do **not** sell personal data or couple content. We do **not** run analytics on couple content (no content-scanning analytics SDK).

Data is processed by infrastructure we use to run the app:

- **Supabase** — auth, database, storage, realtime, Edge Functions
- **Firebase Cloud Messaging** — push delivery (Android FCM / iOS APNs)

Those processors see what they need to provide the service (for example, FCM sees a device token and a notification payload). They are not a social audience.

## Retention

- **Voice notes:** After 24 hours, voice drop **table rows** are hidden by RLS. Storage blobs in the `voice` bucket have no expiry check; a couple member who knows the object path can still read the file until an operator purge (follow-up).
- **Pairing tokens:** 24 hours; only a hash is stored. The raw 6-character code is ephemeral.
- **Account, profile, photos, moods, daily answers, and other couple rows:** until you delete the account (or the couple is removed as part of that deletion).
- **FCM token:** until the token rotates or the account is deleted.
- **On-device Android widget:** a local snapshot of partner name, mood, scene, and avatar. It does not render talk requests or kisses. Sign-out and account deletion do not currently clear that snapshot (follow-up).

## Security

Traffic to our backends uses **TLS in transit**. The Flutter app ships with the Supabase anon key only (via build dart-defines), never a service-role key. Storage buckets for photos and voice are private. This is not end-to-end encryption beyond TLS + RLS.

## Crash reports

When crash reports are collected, they must strip names, emails, photo URLs, and similar identifiers. Crash reports are for fixing the app, not for reading couple content.

## Your choices

- **Sign out:** Settings → Sign out. The couple stays intact.
- **Delete account:** Settings → Delete account, then type `DELETE`. This deletes your auth account and the couple row (Postgres cascade on couple tables). Storage objects in `photos` / `voice` / `canvas` become unreachable via RLS but are not purged by this RPC; blob purge is follow-up work.
- **Push:** the OS permission sheet controls notification delivery. A token may still sit on the profile until it is replaced or the account is deleted.

## Children

Zero Miles is not directed at children. Typical store age rating for this kind of two-person app with user photos and voice is **12+**.

## Changes

We will update the date at the top when this policy changes. The in-app Privacy screen summarizes the same facts.

## Contact

Email **support@zeromiles.app**. The mailbox is operated by the Zero Miles operator; it is not an automated inbox guaranteed by this repository.

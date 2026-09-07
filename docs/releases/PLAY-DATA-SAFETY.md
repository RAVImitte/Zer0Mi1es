# Play Console — Data safety answers

Operator cheat-sheet for the Google Play **App content → Data safety** form. Source policy: [docs/legal/privacy.md](../legal/privacy.md). Support copy: [docs/legal/support.md](../legal/support.md).

**Do not submit this listing to the production track until `privacy.md` is hosted at an https URL you control.** This repository does not claim that URL is live. Paste the live https URL into Play’s privacy-policy field only after the page is actually served.

## Overview

| Form question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Privacy policy URL | Operator-hosted **https** copy of `docs/legal/privacy.md`. Not in this repo. |
| Is all collected user data encrypted in transit? | **Yes** (TLS to Supabase and FCM) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in-app **Settings → Delete account** (type `DELETE`). Also email support@zeromiles.app |
| Independent security review | No |

## Sold / ads / analytics

| Question | Answer |
|---|---|
| Data sold (or used in a “sold” way)? | **No** |
| Used for advertising or marketing? | **No** |
| Analytics of couple content (photos, voice, answers, moods)? | **No** — no content-analytics SDK |
| Crash reports | When collected, **strip names, emails, and photo URLs** |

## Who data is shared with

Declare **collection**. For Play “sharing,” treat:

- **Paired partner** — the other user in the couple sees couple content in the app (that is the product).
- **Infrastructure** — Supabase (auth, database, storage, realtime, functions) and Firebase Cloud Messaging (push). These are service providers processing data to run the app, not a social audience.

Do **not** list advertisers, data brokers, or social networks. There is no social graph.

## Data types to declare

Mark **collected**. Purposes are **App functionality** and **Account management** unless noted. Optional means the feature can be skipped; the account itself still requires email.

| Play type | Collected | Shared (Play meaning) | Required? | Notes |
|---|---|---|---|---|
| Personal info → Name | Yes | Yes — paired partner sees display name | Yes (after profile setup) | `profiles.display_name` |
| Personal info → Email address | Yes | No (not shown to the partner) | Yes | Supabase Auth |
| Personal info → User IDs | Yes | Couple membership only | Yes | Auth uid / couple seats |
| Photos and videos → Photos | Yes | Yes — paired partner | Optional feature | Daily photos; private bucket; photo-lock RLS |
| Audio files | Yes | Yes — paired partner | Optional feature | Voice drops ≤15s, **24h retention** |
| Messages → Other in-app messages | Yes | Yes — paired partner | Optional feature | Daily answers, love-drop notes, talk pings |
| App info → Crash logs | Yes, if Crashlytics (or similar) is on | No | Optional | PII stripped: no names, emails, photo URLs |
| Device or other IDs | Yes | No | Optional (push) | FCM token on `profiles` |

Also stored but covered by the rows above or by “App functionality”: moods, outfits, canvas strokes, timezone, hashed pairing tokens (24h).

Not collected: approximate or precise location as a product feature, contacts, SMS, calendar, financial info, health, advertising ID for ads.

## Deletion and account

- In-app: **Settings → Delete account → type DELETE**.
- Server: `delete_my_account` removes the couple (cascade of shared rows) and the `auth.users` row.
- Sign out is **not** deletion.

## Age rating

Typical IARC/Play outcome for a two-person app with user-generated photos, short voice, and in-app messages, **not** directed at children: **12+**. Confirm in the IARC questionnaire (user-generated content: yes; users can communicate: yes; not a kids app). Do not select “Designed for children.”

## Before production track (operator)

1. Host `docs/legal/privacy.md` at a stable **https** URL.
2. Put that URL in Play Data safety **and** the store listing privacy-policy field.
3. Create the `support@zeromiles.app` mailbox (see support.md).
4. Re-read this file if you add analytics, ads, or a new data type.

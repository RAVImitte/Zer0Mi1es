# Production release — Zero Miles 2.0.1+3

Operator runbook for the first Play upload. **Do not check boxes in git.** Code cannot close the operator gates below.

## Product

| | |
|---|---|
| App | Zero Miles **2.0.1+3** (`appcode/pubspec.yaml`). Never reuse `+2`. |
| applicationId | `app.zeromiles` |
| Display name | Zero Miles |
| First store | Android Play **internal testing** (not the production track) |

Backend project: `vkcoeudqeegnftkytiqd`.

## Build

Prerequisites **before** this command (operator gates 1–2): Firebase rebind for `app.zeromiles` + replace `google-services.json` ([FIREBASE-REBIND.md](FIREBASE-REBIND.md)), and `appcode/android/key.properties` ([SIGNING.md](SIGNING.md)). `assembleRelease` fails until rebind (checked-in `google-services.json` is still `com.example.zer0mi1es`). Missing `key.properties` fails release packaging (`package*Release*`, `sign*ReleaseBundle`, `bundle*Release`). Do not upload a debug-signed artifact.

From `appcode/`:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

| Artifact | Path |
|---|---|
| AAB | `appcode/build/app/outputs/bundle/release/app-release.aab` |
| Dart symbols | `appcode/build/symbols` |
| R8 / ProGuard mapping | `appcode/build/app/outputs/mapping/release/` |

Zip `appcode/build/symbols` plus the R8 mapping. Archive that zip **next to the AAB** (same release folder). You need both to symbolize Dart and Java/Kotlin crashes.

## Play tracks

`internal` → `closed` → `production`.

Staged rollout **20% → 100%**. Rollback = keep the previous AAB and halt the new rollout; do not overwrite the last good artifact.

Internal testing: **2 accounts (the real couple)** for **≥ 3 days** before promoting to production.

## Cron

On project `vkcoeudqeegnftkytiqd`, verify `generate_daily_questions` is scheduled (pg_cron). Function lives in `backend/supabase/migrations/07_cron_daily_state.sql`. Dashboard SQL editor as postgres is not a substitute for the hosted job actually firing.

## Operator gates (code cannot close)

- [ ] Firebase Android app `app.zeromiles` + replace `google-services.json` ([FIREBASE-REBIND.md](FIREBASE-REBIND.md))
- [ ] Upload keystore + Play App Signing ([SIGNING.md](SIGNING.md))
- [ ] `cd backend/supabase && npx supabase functions deploy push-notification --project-ref vkcoeudqeegnftkytiqd` so hosted `verify_jwt=true`. Nested layout: config is `supabase/config.toml`; function source is `functions/push-notification/` (sibling of the nested `supabase/` dir, not inside it).
- [ ] Add `zeromiles://login-callback` to hosted Auth redirect allow-list
- [ ] Host `privacy.md` at an https URL; fill Play Data safety ([PLAY-DATA-SAFETY.md](PLAY-DATA-SAFETY.md))
- [ ] Mailbox support@zeromiles.app
- [ ] Two-phone UAT

## UAT (PRD acceptance, 1:1)

Copy of [PRD acceptance](../prd/PRD-zero-miles.md). Two phones, the real couple. Leave all `[ ]`.

- [ ] Unauthenticated users cannot reach Home; they land on auth
- [ ] A third account cannot join an already-paired couple
- [ ] Daily question: partner answers stay hidden until I submit mine
- [ ] Daily photo: partner photo metadata is unreadable until I upload mine (RLS)
- [ ] Home shows two avatars when paired; unpaired empty seat is Pair, not a dummy body
- [ ] Incoming talk is one line with Okay + overflow; it never wraps over the avatars
- [ ] Android widget updates name/mood/scene/sleep/outfit and never renders talk or kisses
- [ ] Mood sheet offers Happy, Excited, Tired, Sad, Angry, Devastated

## Production gates

Also `[ ]` until a human operator proves them.

- [ ] Signed AAB (not debug) installs from Play internal
- [ ] Push JWT: unauthenticated invoke rejected
- [ ] App does not start against placeholder.supabase.co
- [ ] Delete account works; can recreate
- [ ] Widget has no talk/kisses
- [ ] Third account zero rows ([RLS-PROOF.md](RLS-PROOF.md))
- [ ] Debug “Send test crash” appears in Crashlytics — the tile exists only on a debug install after rebind; the Play internal AAB will not show it
- [ ] Kiss push received
- [ ] Forgot password email + in-app set-new-password via `zeromiles://login-callback`
- [ ] 24h soak: sleep, widget, push, daily cron question, photo lock

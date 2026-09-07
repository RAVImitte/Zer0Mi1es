# Production-readiness change sheet

**Program:** execute-plan `45a44eb4`  
**Landed on:** `production-release`  
**Date:** 2026-09-07  
**Version:** `2.0.0+2` → **`2.0.1+3`**  
**Application ID:** `com.example.zer0mi1es` → **`app.zeromiles`** (permanent)  
**Display name:** `zer0mi1es` / `Zer0mi1es` → **Zero Miles**  
**Not in this land:** UI-experiment merge, iOS App Store pipeline, Play Console listing live fill.

Spreadsheet copy: [CHANGE-SHEET.csv](CHANGE-SHEET.csv)

Operator runbook (UAT still `[ ]`): [PRODUCTION.md](PRODUCTION.md)

---

## PRs (stack order)

| PR | Workstream | What it closed |
|---|---|---|
| 1 | Security | Push JWT required; fail-closed env; forgot-password + deep link; session recovery; Android backup off |
| 2 | Identity | `app.zeromiles`, Kotlin package move, widget rebind, display name Zero Miles, CAMERA, Firebase rebind runbook |
| 3 | Signing | Upload-key signingConfig, R8 minify/shrink, unsigned AAB blocked, SIGNING.md |
| 4 | Observability | Crashlytics + FlutterError/zone hooks; snackbars; debug test-crash tiles |
| 5 | Quality | GitHub Actions analyze+test; router/talk/scene/widget/token contract tests |
| 6 | Legal | Privacy policy, support, Play Data safety copy, in-app Privacy + mailto |
| 7 | Release ops | Version `2.0.1+3`, PRODUCTION.md UAT mapped 1:1 to PRD |

---

## Item sheet

| # | Area | Item | Before | After | Files |
|---|---|---|---|---|---|
| 1 | Identity | Android applicationId / namespace | `com.example.zer0mi1es` | `app.zeromiles` | `appcode/android/app/build.gradle.kts` |
| 2 | Identity | Kotlin package | `com.example.zer0mi1es` | `app.zeromiles` | `MainActivity.kt`, `PartnerWidgetProvider.kt` (moved) |
| 3 | Identity | Widget provider + iOS app group | `com.example.zer0mi1es.PartnerWidgetProvider`, `group.com.example.zer0mi1es` | `app.zeromiles.PartnerWidgetProvider`, `group.app.zeromiles` | `home_widget_sync.dart`, ADR-0008, SPEC-android-widget |
| 4 | Identity | Display name | `zer0mi1es` / `Zer0mi1es` | **Zero Miles** | AndroidManifest `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, `MaterialApp` title |
| 5 | Identity | minSdk | Flutter default | `24` explicit | `build.gradle.kts` |
| 6 | Identity | CAMERA | Missing (camera path used) | `CAMERA` added (daily photo uses `ImageSource.camera`) | `AndroidManifest.xml` |
| 7 | Identity | Firebase Android client | `package_name` `com.example.zer0mi1es` | **Unchanged on purpose** — assemble fail-closes until operator rebind | `google-services.json`, `docs/releases/FIREBASE-REBIND.md` |
| 8 | Identity | iOS bundle id | `com.example.zer0mi1es` | **Unchanged** (App Store is track 2) | `project.pbxproj` |
| 9 | Security | Push JWT | `verify_jwt = false` | `verify_jwt = true` | `backend/supabase/supabase/config.toml` |
| 10 | Security | Push function auth | Open to guessed payloads; CORS `*` | 401 without Bearer; sender/user_id must equal JWT `sub`; couple membership 403; unknown tables 400; no CORS `*` | `backend/supabase/functions/push-notification/index.ts` |
| 11 | Security | Push logs | FCM token prefixes, full payloads | Table name / generic errors only | same function |
| 12 | Security | Client push | `functions.invoke` with user JWT | Unchanged (still user JWT, no service role in the app) | `push_dispatcher.dart` |
| 13 | Security | Supabase dart-defines | Defaulted to `placeholder.supabase.co` | Empty if missing; boot fatal screen; no `Supabase.initialize` | `env.dart`, `bootstrap.dart`, `app.dart`, `test/env_test.dart` |
| 14 | Security | Android backup | Default allow | `android:allowBackup="false"` | `AndroidManifest.xml` |
| 15 | Auth | Forgot password | Missing on `main` | Login-mode “Forgot password?” + in-app set-new-password | `auth_repository`, `auth_view_model`, `auth_screen` |
| 16 | Auth | Recovery deep link | None | `zeromiles://login-callback` (Android intent-filter, iOS URL type, local `additional_redirect_urls`) | Manifest, Info.plist, `config.toml` |
| 17 | Auth | Expired refresh / 429 | Wedged session | Retryable network keeps session; non-retryable signs out without blocking `runApp`; 429 copy | `bootstrap.dart`, `auth_screen.dart` |
| 18 | Signing | Release keys | `signingConfig = debug` | `key.properties` → `signingConfigs.release`; missing file **fails** `bundleRelease` | `build.gradle.kts`, `key.properties.example`, `SIGNING.md` |
| 19 | Signing | Minify | Off | R8 minify + shrinkResources + `proguard-rules.pro` | `build.gradle.kts`, `proguard-rules.pro` |
| 20 | Observability | Crash net | `debugPrint` / empty `catch (_)` | Crashlytics; `FlutterError.onError`; `PlatformDispatcher.onError`; `runZonedGuarded` | `pubspec.yaml`, `bootstrap.dart`, Gradle Crashlytics plugin |
| 21 | Observability | User-visible errors | Silent catch on timezone, canvas, etc. | Snackbar + `recordError` with static reason (no PII) | home, canvas, couple, question, push |
| 22 | Observability | Push permission denied | `debugPrint` only | Home snackbar: notifications are off | `push_notification_service.dart`, `home_screen.dart` |
| 23 | Observability | Test crash | None | kDebugMode “Send test crash” (Dart throw) + “Send native test crash” | `settings_sheet.dart` |
| 24 | Quality | CI | No `.github/workflows` | `flutter analyze --no-fatal-infos` + `flutter test` on PR and push to `main` / `production-release` | `.github/workflows/ci.yml` |
| 25 | Quality | Tests | Palette assertion only | Env, router redirect, talk expiry/copy, scene hours, widget keys (no talk/kiss), pairing token, privacy screen | `appcode/test/*` |
| 26 | Legal | Privacy / support | None | Policy, support, Play Data safety copy; Settings Privacy + mailto `support@zeromiles.app` | `docs/legal/*`, `PLAY-DATA-SAFETY.md`, `privacy_screen.dart` |
| 27 | Legal | Account deletion | Already in Settings | Kept (type `DELETE`) | `settings_sheet.dart` |
| 28 | Release | Version | `2.0.0+2` | **`2.0.1+3`** | `appcode/pubspec.yaml`, `docs/README.md` |
| 29 | Release | Operator / UAT | None | PRODUCTION.md (build, tracks, operator gates, PRD-mapped UAT still `[ ]`) | `docs/releases/PRODUCTION.md` |

---

## Still operator / not in git

These are **not** claimed done. See PRODUCTION.md.

| Gate | Why code cannot close it |
|---|---|
| Firebase Android app `app.zeromiles` + new `google-services.json` | Console download; current JSON would mismatch `app.zeromiles` |
| Upload keystore + Play App Signing | Must not commit `.jks` / `key.properties` |
| `npx supabase functions deploy push-notification --project-ref vkcoeudqeegnftkytiqd` | Hosted `verify_jwt` still old until deploy (`cd backend/supabase`) |
| Hosted Auth allow-list `zeromiles://login-callback` | Dashboard |
| Host `privacy.md` at https; Play Data safety form | Play Console |
| Mailbox `support@zeromiles.app` | DNS / inbox |
| Two-phone UAT | PRD boxes stay `[ ]` until devices |
| iOS bundle id / App Store | Track 2 |

---

## Files touched (57)

Added: CI workflow, ProGuard rules, key.properties.example, auth_redirect, talk_copy, privacy screen, eight test files, legal docs, FIREBASE-REBIND / SIGNING / PLAY-DATA-SAFETY / PRODUCTION / RLS-PROOF.

Moved: Kotlin sources `com/example/zer0mi1es` → `app/zeromiles`.

Unchanged on purpose: `google-services.json` package name, iOS `PRODUCT_BUNDLE_IDENTIFIER`, UI-experiment, version `+2` not reused.

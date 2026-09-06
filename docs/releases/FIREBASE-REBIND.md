# Firebase rebind for Android `app.zeromiles`

Android `applicationId` is now `app.zeromiles`. The checked-in `google-services.json` still has `package_name` `com.example.zer0mi1es` so Gradle google-services fail-closes until an operator registers a real Android app.

Do **not** invent a `mobilesdk_app_id` or rewrite `firebase_options.dart` Android `appId` by hand.

## Project

- Firebase project: `zer0mi1es`
- Project number: `25186098269`

## Steps

1. In the Firebase console, open project `zer0mi1es` (number `25186098269`).
2. Add an Android app with package name `app.zeromiles`.
3. Download `google-services.json` and replace `appcode/android/app/google-services.json`.
4. Update `appcode/lib/firebase_options.dart` Android options (`appId`, `apiKey`, and any other Android fields) from the new file. Leave iOS options unchanged unless iOS is rebound separately.

## Until this is done

`assembleRelease` is expected to fail with no matching client for `app.zeromiles`.

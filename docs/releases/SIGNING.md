# Android release signing

Production Android builds must be signed with the **upload key**. They are never debug-signed.

`android/key.properties` is optional at Gradle configure time (`flutter test` / analyze still work). Release packaging does not: `package*Release*`, `sign*ReleaseBundle`, and `bundle*Release` throw a `GradleException` pointing here if the file is missing. Without that check, AGP 8/9 writes an unsigned `app-release.aab` and `flutter build appbundle --release` exits 0.

Never commit `*.jks` or `key.properties`.

## Generate the upload keystore

From `appcode/android/` (so `storeFile` in `key.properties` can stay a relative path):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Back up `upload-keystore.jks` and the passwords offline. Losing the upload key blocks Play uploads until a reset.

## Local `key.properties`

```bash
cp key.properties.example key.properties
```

Fill `storePassword` and `keyPassword`. Keep:

- `keyAlias=upload`
- `storeFile=upload-keystore.jks` (relative to `appcode/android/`, or an absolute path)

`key.properties` is gitignored (`**/android/key.properties`). `key.properties.example` is not.

## Play App Signing

New Play apps enroll in **Play App Signing**:

| Key | Who holds it | Role |
|---|---|---|
| **Upload key** | You (`upload-keystore.jks`) | Signs the AAB you upload to Play |
| **App signing key** | Google Play | Re-signs APKs/AABs delivered to devices |

The upload key is **not** the key users' devices see. If the upload key is lost or rotated, request an upload-key reset in Play Console; the app signing key stays with Google.

## Release build

From `appcode/`:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Dart obfuscation mapping: `build/symbols`

Archive `build/symbols` **next to the AAB** (same release folder / artifact store). You need those files to symbolize Dart stack traces. R8/ProGuard mapping is under `build/app/outputs/mapping/release/` — keep that too if you need Java/Kotlin deobfuscation.

Release is minified with R8 (`isMinifyEnabled` + `isShrinkResources`) and `app/proguard-rules.pro`.

## Do not

- Commit `upload-keystore.jks`, any `*.jks`, or `key.properties`
- Fall back to the debug keystore for Play uploads
- Ship a release without `--obfuscate --split-debug-info=...` and an archived symbols directory

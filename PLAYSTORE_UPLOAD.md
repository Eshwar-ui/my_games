# Play Store upload (Flutter / Android)

This repo is already a Flutter app. To upload to Google Play you mainly need:

1) a unique Android application id (package name)
2) release signing (upload key)
3) a signed `.aab` build

## 1) Set your Android application id

Edit:

- `android/app/build.gradle.kts`

Replace `applicationId = "com.example.my_games"` and `namespace = "com.example.my_games"` with your final id, for example:

```
com.yourcompany.mygames
```

Important: the **applicationId must never change** after the first Play Store upload.

If you change it, also move/rename:

- `android/app/src/main/kotlin/.../MainActivity.kt` package path (match the new id)

## 2) Create an upload keystore (one-time)

If you do **not** create a keystore + `android/key.properties`, this project will fall back to **debug signing** for release builds, which is not appropriate for a real Play Store release.

From the repo root:

```powershell
cd android
keytool -genkeypair -v `
  -keystore app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

Then:

- copy `android/key.properties.example` → `android/key.properties`
- fill in `storePassword` and `keyPassword`

Notes:
- Keep `upload-keystore.jks` and `key.properties` backed up (and private).
- The repo `.gitignore` excludes them.

## 3) Build a Play Store bundle (`.aab`)

From the repo root:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

Output:

- `build/app/outputs/bundle/release/app-release.aab`

## 4) Quick pre-upload checks

- Install a release APK locally (optional): `flutter build apk --release`
- Verify version: update `version:` in `pubspec.yaml` before every upload.

## 5) Play Console checklist (non-code)

- Store listing: app name, short/full description, screenshots (phone), feature graphic, and high-res icon.
- Content rating questionnaire and target audience.
- Ads: declare whether the app contains ads.
- Data safety: declare data collection/sharing (for this app it’s usually “no data collected” unless you add analytics/ads later).
- App signing: enable Play App Signing and keep your upload keystore backed up.

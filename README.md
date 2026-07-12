# Daily Meal Flutter

Production Flutter client for Daily Meal on Android and Web. It ports the
existing React Native user application and Admin Dashboard while reusing the
production Node.js API at `https://api.dailymeal.site`.

## Requirements

- Flutter stable with Dart `>=3.11.5`
- Android SDK/Java toolchain for Android builds
- Chrome for Web development

Check the local toolchain:

```powershell
flutter doctor -v
flutter pub get
flutter analyze --no-pub
flutter test
```

## Configuration

Configuration is compile-time and validated during startup. Do not commit
private credentials. The production public client identifiers are passed as
dart-defines:

```powershell
$defines = @(
  '--dart-define=API_BASE_URL=https://api.dailymeal.site',
  '--dart-define=FACEBOOK_APP_ID=3483710358450589',
  '--dart-define=GOOGLE_WEB_CLIENT_ID=20654020356-nsqam5ladrg7j5v6agefq8pucnrcqtn8.apps.googleusercontent.com'
)
flutter run -d chrome @defines
flutter run -d android @defines
```

Optional Web Push uses `WEB_PUSH_PUBLIC_KEY`. Obtain the current public VAPID
key from `GET /api/users/web-push/vapid-public-key`; never place a private VAPID
key in the client.

Android Facebook login also requires the Meta Client Token from **Meta App
Dashboard → Settings → Advanced**. Put it in ignored
`android/facebook.properties`:

```properties
appId=3483710358450589
clientToken=YOUR_META_CLIENT_TOKEN
```

For CI, use `FACEBOOK_APP_ID` and `FACEBOOK_CLIENT_TOKEN` environment
variables, or Gradle properties `facebookAppId` and `facebookClientToken`.
Debug builds use a visibly invalid placeholder when the token is absent so the
rest of the Flutter plugin registry and emulator smoke tests remain usable.
Release builds fail fast until a real Client Token is supplied.

## Release builds

Android release builds intentionally refuse to use the debug key. Create a
private keystore outside version control, then add `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/secure/daily-meal-upload.jks
```

`android/key.properties`, `android/facebook.properties` and `*.jks` are ignored
by Git. Back up the upload key securely; losing it can prevent future Play
Store updates.

```powershell
flutter build web --release @defines
flutter build apk --release @defines
# or for Play Store delivery
flutter build appbundle --release @defines
```

Artifacts are created under `build/web`, `build/app/outputs/flutter-apk`, and
`build/app/outputs/bundle`.

### Android App Links

The Android manifest accepts verified HTTPS links for
`https://dailymeal.site/users/*` and `https://dailymeal.site/posts/*`, matching
the profile/post URLs shared by the app. After creating the release keystore,
publish `https://dailymeal.site/.well-known/assetlinks.json` with package name
`com.dailymeal.daily_meal_app` and the SHA-256 fingerprint of the Play App
Signing certificate (plus the upload/debug certificate only for environments
that need them). Until that file is deployed, explicit/package-targeted intents
work but Android cannot auto-verify the public domain association.

## Architecture

The app uses contract-first vertical slices:

- `lib/app`: bootstrap, Material 3 theme and guarded routing
- `lib/core`: network, session storage, responsive layout, realtime and Web Push
- `lib/features`: auth, feed, posts, profiles, messaging, Premium, Admin and user utilities
- `test`: API contract, controller and responsive widget tests
- `docs/parity`: source inventory, API map, feature matrix and verification evidence

User and Admin bearer sessions are stored separately. A 401 clears the relevant
session boundary. Media URLs are normalized against the configured API origin.

## Platform notes

- Google and Facebook login require matching OAuth/Meta console configuration
  for the final Android package and deployed Web origin.
- The current backend sends Android push only through Expo push tokens. Native
  Flutter FCM delivery therefore requires a backend FCM contract and Firebase
  Android configuration; Web Push is implemented independently.
- The normal JavaScript Web release is supported. Flutter's optional Wasm dry
  run currently reports an upstream `socket_io_common` JS-interop warning.
- Support feedback and Premium family invite codes remain explicitly
  unavailable because the production backend exposes no such contracts.

## Evidence

See [feature-parity-matrix.md](docs/parity/feature-parity-matrix.md) and the
slice verification documents in `docs/parity` for current Android/Web evidence
and externally blocked live checks.

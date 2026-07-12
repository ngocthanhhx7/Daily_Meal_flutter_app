# Slice 2 Authentication and Onboarding Verification

Verification date: 2026-07-11

## Automated evidence

The following checks completed with exit code 0 using production dart-defines:

- `flutter test`: 76 tests passed.
- `flutter analyze`: no issues found.
- `flutter build web`: produced `build/web` and passed the Wasm dry run.
- `flutter build apk --debug`: produced `build/app/outputs/flutter-apk/app-debug.apk`.

Covered flows include email login/register, password reset OTP, phone OTP and
first-time password setup, user/admin session separation and restoration,
administrator login guards, two-step onboarding preferences, social credential
token exchange, and Google/Facebook social-button orchestration.

## Social authentication evidence boundary

Google uses `google_sign_in` 7.2.0. Android starts the native authenticate flow;
Web renders the mandatory Google Identity Services button and consumes its ID
token event. The Web client ID is present in `web/index.html` and is also passed
through production configuration.

Facebook uses `flutter_facebook_auth` 7.2.0. Web initializes the JavaScript SDK
with App ID `3483710358450589`; successful access tokens are exchanged at
`POST /api/auth/facebook`.

Live provider login is not yet claimed as verified. It still requires:

- Google OAuth authorized Web origins and Android package/SHA fingerprints in
  Google Cloud Console.
- A Meta Facebook Android Client Token plus matching package/key hashes in the
  Meta developer console.
- Manual login/cancel/error evidence against the configured production apps.

## Android build warning

The Kotlin daemon again reported an incremental-cache path-root mismatch between
the Pub cache on `C:` and the project on `D:` while compiling
`google_sign_in_android`. Gradle recovered and produced the APK with exit code 0.
This is an environment cache warning rather than a source compilation failure.

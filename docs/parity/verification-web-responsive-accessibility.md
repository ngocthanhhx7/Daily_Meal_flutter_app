# Web responsive and keyboard verification

Date: 2026-07-12

## Runtime walkthrough

The Flutter Web app was started against the production API configuration at
`http://127.0.0.1:8765/#/login` and inspected in the in-app Chromium runtime.

- Browser metadata resolved to title `Daily Meal`, the Daily Meal description,
  and `manifest.json`.
- The login screen rendered without horizontal or vertical overflow at
  390 x 844 (phone) and 768 x 1024 (tablet).
- Email/phone selection, email and password fields, primary login action,
  password recovery, Google, Facebook, registration and admin-login actions
  remained visible and retained their intended hierarchy at both sizes.
- The Google control is the native Google Identity Services button rather than
  a custom imitation.

## Automated keyboard evidence

`test/features/auth/presentation/login_screen_test.dart` verifies that pressing
Tab while the email editor is focused moves primary focus to the password
editor. This protects the most important form traversal independently of the
Flutter Web canvas/semantics implementation.

Command:

```powershell
flutter test test\features\auth\presentation\login_screen_test.dart
```

Result: 5 tests passed.

## Development-runtime observation

During a `flutter run` browser session, Google Identity Services logged that
`google.accounts.id.initialize()` had been called more than once. Source tracing
confirmed one provider per login-screen lifecycle and an application-level
initialization guard. The official `google_sign_in_web` implementation owns the
underlying GIS initialization; the warning can occur when Flutter hot-restarts
inside the same document. It was not accompanied by a console error or a failed
button render. No application workaround was added around the official SDK.

Live OAuth completion still requires an authorized production origin and real
Google/Meta test accounts, so it remains tracked separately in the parity
matrix.

## Fresh repository gates

All commands below were run after the QA evidence was added:

- `flutter test`: 160 tests passed.
- `flutter analyze --no-pub`: no issues found.
- `flutter build web --release` with the production API, Facebook app ID and
  Google Web client ID: built `build/web` successfully. Flutter's optional Wasm
  dry run still reports the upstream `socket_io_common` JS-interop lint; the
  requested JavaScript Web release build succeeds.
- `flutter build apk --debug` with the same production defines: built
  `build/app/outputs/flutter-apk/app-debug.apk` successfully.

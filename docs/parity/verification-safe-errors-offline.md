# Safe errors and offline recovery verification

Date: 2026-07-12

## Root cause and fix

`ApiExceptionMapper` existed but was not connected to the shared `ApiClient`.
Consequently, a transport `DioException` could reach a feature controller and
its technical `toString()` value could be rendered to the user.

The shared HTTP error interceptor now maps every Dio failure to an
`AppFailure`, preserving it as the Dio error cause. `userErrorMessage` unwraps
that failure and returns only the localized user message. All user-facing
controllers and local screen actions use this boundary, including Auth, Feed,
Comments, Search, Profile, Messaging, Notifications/Web Push, Post Editor,
Premium and every Admin controller.

Unknown non-HTTP errors use the generic localized failure message instead of
leaking implementation details.

## Deterministic evidence

- `user_error_message_test.dart` proves technical host details and Dio class
  names are not returned to the UI.
- `api_client_test.dart` proves connection and 401 responses carry the mapped
  network/unauthorized failure while the session-expiry callback still runs.
- `home_screen_test.dart` starts with a simulated offline response, asserts the
  localized safe message and absence of the internal hostname, taps `Thử lại`,
  then verifies the recovered feed.
- Analytics queue tests independently prove unsent telemetry remains queued
  while its transport is offline.

This evidence covers Android and Web because the mapping and controller layers
are shared Dart code and the recovery journey is a platform-independent widget
contract.

## Fresh gates

- `flutter test`: 164 tests passed.
- `flutter analyze --no-pub`: no issues found.
- Production-defined `flutter build web --release`: succeeded. The optional
  Wasm dry-run warning remains isolated to upstream `socket_io_common`; the
  requested JavaScript release artifact was built.
- Production-defined `flutter build apk --debug`: succeeded and produced
  `build/app/outputs/flutter-apk/app-debug.apk`.

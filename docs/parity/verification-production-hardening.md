# Production hardening evidence

## Branding and typography

- Daily Meal square logo resized into Android density launchers, splash logo,
  Web favicon, regular and maskable PWA icons.
- Android application label and Web title/manifest metadata use `Daily Meal`.
- Work Sans Regular/Medium/SemiBold/Bold is declared in `pubspec.yaml` and used
  by the Material 3 theme.
- Visual inspection confirms the generated 192px icon renders the branded
  green plate/leaf mark rather than Flutter's placeholder.

## Telemetry

- `DioAnalyticsSink` sends the server-required name, UTC time, session ID,
  source, platform, screen and sanitized properties envelope.
- Batches are split at the backend maximum of 100 events.
- App open and background lifecycle events flush through the production sink;
  failed sends retain the client queue for a later flush.

## Inclusive interaction

- Material tap target sizing is padded globally; custom feed actions enforce
  48dp minimum constraints and semantic labels.
- Focus and hover colors are defined for Web Material controls.
- Custom double-tap heart transitions become zero-duration when the platform
  requests reduced motion, with widget evidence.

## Build evidence

- `flutter analyze --no-pub`: no issues.
- `flutter test`: 157 passed.
- Branded Web release and Android debug APK builds: passed.
- Optional Wasm dry run retains the upstream `socket_io_common` warning; the
  supported JavaScript Web release succeeds.

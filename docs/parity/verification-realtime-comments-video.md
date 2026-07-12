# Verification — realtime comments and viewport video

## Comments

- Shared Socket.IO client decodes `comment:created` into the typed comment model.
- Comments controller connects, joins `post:<id>`, filters/deduplicates live
  payloads and leaves the room on disposal.
- REST-created comments and echoed socket comments converge by ID.

## Feed video

- Uses the official `visibility_detector` package (`0.4.0+2`).
- A video becomes active at 65% visible, pauses below the threshold, loops and
  starts muted, matching the React Native behavior.
- App background pauses playback; resume only restarts an active visible video.
- Tapping toggles mute rather than fighting the viewport playback state.

## Evidence

- Comment room lifecycle/dedup controller test.
- Pure autoplay threshold test and reduced-motion feed test.
- `flutter analyze --no-pub`: no issues.
- Full `flutter test`: 159 passed.
- Web release and Android debug APK builds: passed.

# Realtime post statistics verification

Date: 2026-07-12

## Source parity

React Native `HomeScreen.tsx` listens for `post:stats-updated` and merges the
server-provided likes, comments and saves into the matching feed post. The
server broadcasts this payload after interaction mutations.

Flutter now exposes a typed `PostStatsUpdate` stream from the shared
`RealtimeClient`. `SocketIoRealtimeClient` validates and decodes the exact
payload shape before publishing it. `FeedController` subscribes for its
lifetime, connects through the existing authenticated singleton client,
updates only the matching post and cancels the subscription on disposal.
Viewer-specific liked/saved state is preserved while aggregate server stats
are replaced.

## Deterministic evidence

- Decoder tests accept `{ postId, stats: { likes, comments, saves } }` and
  reject incomplete payloads.
- Feed controller tests prove a known post updates, viewer state remains
  intact, the shared client is connected once, and events after disposal no
  longer mutate state.
- Unknown post IDs are naturally ignored because no matching feed item exists.

Live two-session delivery remains part of the broader production Socket.IO
evidence gate; this checkpoint closes the previously missing Flutter consumer
and lifecycle contract.

## Fresh gates

- `flutter test`: 167 tests passed.
- `flutter analyze --no-pub`: no issues found.
- Production-defined Web release build: succeeded.
- Production-defined Android debug APK build: succeeded.
- Flutter's optional Wasm dry run continues to report only the upstream
  `socket_io_common` JS-interop lint; the requested JavaScript Web artifact is
  produced successfully.

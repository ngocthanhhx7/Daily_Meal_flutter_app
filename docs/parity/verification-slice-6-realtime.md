# Slice 6 Realtime Verification

Date: 2026-07-12

## Implemented

- Typed conversation/message models and exact REST endpoints.
- Shared Socket.IO 3.x client compatible with the production Socket.IO 4.x
  server, JWT handshake, websocket transport, room errors and bounded
  exponential reconnect (6 attempts, 1-10 second delay, 0.5 jitter).
- Inbox realtime upsert/sort and Chat REST/socket/send deduplication.
- Responsive Inbox and Chat routes, message creation from Public Profile and
  primary navigation.
- Notification REST CRUD, unread badge, realtime insertion, optimistic rollback
  and type-safe deep-link destinations.

## Deterministic evidence

- API tests assert exact methods, paths and trimmed payloads.
- Controller tests assert event filtering, ordering, deduplication, join/leave,
  mutation rollback and unread counts.
- Option-map tests assert the reconnect limits are actually passed to the
  Socket.IO package rather than relying on its infinite-attempt default.
- Socket adapter tests prove initial connect is not mistaken for recovery,
  repeated connect emits one recovery signal, and `auth:error` disposes the
  active socket as a terminal failure.
- Feed, Inbox and Notifications reload REST after recovery; Comments and Chat
  rejoin their rooms before reloading. Controller tests assert each behavior
  and disposal cancels feature subscriptions.
- Widget tests cover compact Inbox and Chat send journeys.
- Analyzer and both platform builds are run at the checkpoint.

## Evidence still required

Live two-session production Socket.IO delivery/reconnect and physical/browser
push permission/subscription evidence remain pending; these capabilities are
therefore kept `In progress` in the parity matrix.

Fresh gates after reconnect recovery and terminal-auth handling: 175 tests passed, analyzer
reported no issues, and production-defined Web release plus Android debug APK
builds both succeeded. The optional Wasm dry-run warning remains confined to
the upstream `socket_io_common` JS-interop adapter.

## Push contract finding

- Web Push now includes a dedicated service worker, VAPID readiness/permission
  bridge, subscription persistence, backend register/unregister lifecycle and
  deterministic controller/API tests.
- Read-only production probe on 2026-07-12 confirmed
  `/api/users/web-push/vapid-public-key` returns a configured 87-character
  public key; the key value itself is intentionally not recorded.
- Native `/api/users/push-token` is not Flutter-compatible today. Backend
  `sendPushNotification` only forwards values beginning with
  `ExponentPushToken[` to Expo's push API. A Flutter FCM token would be stored
  but never delivered. Android push therefore remains explicitly blocked until
  backend FCM delivery credentials/logic and the Flutter Firebase project
  configuration are supplied; the app does not submit a misleading token.

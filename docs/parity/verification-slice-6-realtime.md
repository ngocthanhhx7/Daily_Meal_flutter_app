# Slice 6 Realtime Verification

Date: 2026-07-12

## Implemented

- Typed conversation/message models and exact REST endpoints.
- Shared Socket.IO 3.x client compatible with the production Socket.IO 4.x
  server, JWT handshake, websocket transport, reconnect and room errors.
- Inbox realtime upsert/sort and Chat REST/socket/send deduplication.
- Responsive Inbox and Chat routes, message creation from Public Profile and
  primary navigation.
- Notification REST CRUD, unread badge, realtime insertion, optimistic rollback
  and type-safe deep-link destinations.

## Deterministic evidence

- API tests assert exact methods, paths and trimmed payloads.
- Controller tests assert event filtering, ordering, deduplication, join/leave,
  mutation rollback and unread counts.
- Widget tests cover compact Inbox and Chat send journeys.
- Analyzer and both platform builds are run at the checkpoint.

## Evidence still required

Live two-session production Socket.IO delivery/reconnect and physical/browser
push permission/subscription evidence remain pending; these capabilities are
therefore kept `In progress` in the parity matrix.

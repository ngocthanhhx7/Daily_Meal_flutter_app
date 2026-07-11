# Daily Meal Slice 6 — Realtime Messaging and Notifications Plan

## Locked contracts

- Inbox: `GET /api/messages/conversations`, realtime
  `conversation:updated` with ID upsert and descending `updatedAt` order.
- Conversation creation: `POST /api/messages/conversations` with
  `{recipientId}`.
- Chat: GET/POST `/api/messages/conversations/:id/messages`, body length
  1–2000, at most 100 server messages.
- Socket.IO authenticates with the user JWT in handshake `auth.token` and uses
  `join-conversation` / `leave-conversation`; chat consumes `message:created`.
- Notification center consumes REST list/read/delete mutations and realtime
  `notification:created` with ID deduplication.

## Execution

1. Add typed REST models/APIs and controller race/deduplication tests.
2. Add a shared JWT Socket.IO client for Android/Web with room lifecycle and
   error streams.
3. Build responsive Inbox/Chat and connect primary/profile navigation.
4. Build notification center, unread badge, optimistic actions and safe deep
   links.
5. Add Android push and Web Push subscription lifecycle, then run live
   production socket/push evidence separately from deterministic tests.

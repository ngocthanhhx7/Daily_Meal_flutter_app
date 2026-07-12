# Daily Meal Socket.IO Contract

## Connection

- Server implementation: `server/src/services/socket.ts:27-126`.
- Client reference: `client/src/context/SocketContext.tsx:24-50`.
- URL: same origin/base as REST API; when the REST base is relative on Web, the client resolves the current origin.
- Authentication: JWT access token in `socket.handshake.auth.token`.
- Missing token: server emits `auth:error` with `{ message: "Authentication required" }`, then disconnects (`socket.ts:35-39`).
- Invalid token/user: server emits `auth:error` with `{ message: "Invalid session" }`, then disconnects (`socket.ts:43-54`).
- On successful connection the server joins the private room `user:<userId>` (`socket.ts:56`).

## Client-to-Server Events

| Event | Payload | Authorization/behavior | Source |
|---|---|---|---|
| `join-post` | post ID string | Valid ObjectId required; joins `post:<postId>` | `server/src/services/socket.ts:58-67` |
| `leave-post` | post ID string | Leaves `post:<postId>` when ID is valid | `server/src/services/socket.ts:69-73` |
| `join-conversation` | conversation ID string | Valid ID and authenticated user must be a participant; joins `conversation:<id>` | `server/src/services/socket.ts:75-112` |
| `leave-conversation` | conversation ID string | Leaves `conversation:<id>` when ID is valid | `server/src/services/socket.ts:114-118` |

Invalid/unauthorized room requests emit `room:error` with `{ room, message }` (`server/src/services/socket.ts:16-19`). Flutter must surface diagnostics without exposing tokens and must not retry unauthorized joins indefinitely.

## Server-to-Client Events

| Event | Payload | Audience | Producer/source | Existing consumer |
|---|---|---|---|---|
| `post:stats-updated` | `{ postId, stats }` | global/affected clients | post like/save flows in `server/src/routes/posts.ts` | React Native `HomeScreen.tsx:246`; Flutter `RealtimeClient` → `FeedController` |
| `comment:created` | comment DTO | `post:<postId>` | comment creation in `server/src/routes/posts.ts` | `client/src/screens/CommentsScreen.tsx:261` |
| `message:created` | message DTO | `conversation:<id>` | message creation in `server/src/routes/messages.ts` | `client/src/screens/ChatScreen.tsx:77` |
| `conversation:updated` | conversation DTO scoped for recipient | each participant's `user:<id>` room | `server/src/routes/messages.ts:204` | `client/src/screens/InboxScreen.tsx:51` |
| `notification:created` | populated notification DTO | target `user:<id>` room | follows/posts/messages routes | `client/src/context/NotificationContext.tsx:442` |
| `auth:error` | `{ message }` | connecting socket | `server/src/services/socket.ts:37,53` | Socket session controller |
| `room:error` | `{ room, message }` | requesting socket | `server/src/services/socket.ts:18` | Feature controller/diagnostics |

## Lifecycle Rules for Flutter

- Exactly one managed socket per authenticated session.
- Disconnect and clear all listeners when token changes or user logs out.
- Use bounded exponential reconnect backoff: Flutter allows 6 attempts with a
  1 second initial delay, 10 second cap and 0.5 jitter. Never reconnect after
  explicit logout or terminal auth error.
- Join a post room only while its realtime comments surface is active.
- Join a conversation room only while that conversation is active; leave on route disposal/change.
- Register named handlers and remove the same handlers during disposal.
- Deduplicate messages/comments/notifications by server ID before inserting.
- Treat REST as recovery/source of truth after reconnect; refetch active inbox/conversation/notification state.
- Flutter emits a recovery signal only from the second successful socket
  connection onward. Active Feed, Inbox and Notifications refetch REST;
  Comments and Chat rejoin their scoped room before refetching REST.
- Do not optimistically echo realtime events twice when REST creation already returned the created DTO.

## Verification Cases

1. Missing/invalid token produces auth error and no reconnect loop.
2. User cannot join a conversation they do not participate in.
3. Opening/closing comments joins/leaves the correct post room.
4. Two sessions receive a new message once and inbox preview updates once.
5. Reconnect restores user room and refetches active feature state.
6. Logout removes listeners and prevents subsequent private events from reaching state.

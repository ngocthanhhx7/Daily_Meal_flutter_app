# Daily Meal REST API Contract

## Conventions

- Production origin: `https://api.dailymeal.site`
- Mount points: `server/src/app.ts:40-51`
- User auth: `Authorization: Bearer <JWT>` enforced by `requireAuth`.
- Admin auth: bearer admin JWT enforced by `requireAdmin` in `server/src/routes/admin.ts`.
- JSON requests use `Content-Type: application/json`; uploads use multipart form data.
- Client capability and response typing reference: `client/src/api/client.ts:198-663` and `client/src/types/api.ts`.
- Errors are normalized by `server/src/middleware/error.ts`; validation is primarily Zod-driven inside route modules.

The table records the stable capability surface. Exact DTO fields/enums must be generated from `client/src/types/api.ts` and server DTO functions during the implementing slice; no field may be invented.

## Authentication — `/api/auth`

| Method/path | Auth | Request | Success envelope | Source |
|---|---|---|---|---|
| POST `/register` | no | email, password, optional displayName | token, user | `routes/auth.ts:113`; client `api/client.ts:355` |
| POST `/login` | no | email, password | token, user | `routes/auth.ts:138`; client `api/client.ts:360` |
| POST `/password/forgot/request-otp` | no | email | message, optional devOtp | `routes/auth.ts:156`; client `api/client.ts:385` |
| POST `/password/forgot/verify-otp` | no | email, six-digit otp, newPassword | token, user, message | `routes/auth.ts:185`; client `api/client.ts:390` |
| POST `/phone/register` | no | phone, password, optional displayName | token, user | `routes/auth.ts:229`; client `api/client.ts:365` |
| POST `/phone/request-otp` | no | phone | message, requiresPasswordSetup, optional devOtp | `routes/auth.ts:254`; client `api/client.ts:375` |
| POST `/phone/verify-otp` | no | phone, otp, optional password/displayName | token, user | `routes/auth.ts:286`; client `api/client.ts:380` |
| POST `/phone/login` | no | phone, password | token, user | `routes/auth.ts:339`; client `api/client.ts:370` |
| POST `/facebook` | no | accessToken | token, user | `routes/auth.ts:357`; client `api/client.ts:395` |
| POST `/google` | no | idToken | token, user | `routes/auth.ts:426`; client `api/client.ts:400` |
| POST `/google/link` | user | idToken | user | `routes/auth.ts:464`; client `api/client.ts:405` |
| GET `/me` | user | none | user | `routes/auth.ts:508`; client `api/client.ts:411` |
| PATCH `/password` | user | currentPassword, newPassword | empty/success | `routes/auth.ts:522`; client `api/client.ts:436` |

Password/OTP length and normalization rules come from Zod schemas at `routes/auth.ts:15-56`. Flutter validation must mirror these without replacing server validation.

## Onboarding — `/api/onboarding`

| Method/path | Auth | Request | Success | Source |
|---|---|---|---|---|
| PATCH `/preferences` | user | interests, eatingStyles | preferences | `routes/onboarding.ts:14`; client `api/client.ts:412` |

## Users — `/api/users`

| Method/path | Auth | Purpose/result | Source |
|---|---|---|---|
| PATCH `/me` | user | update allowed profile/preferences fields; returns user | `routes/users.ts:232`; client `api/client.ts:421` |
| POST `/me/premium-trial` | user | claim trial; returns user | `routes/users.ts:256`; client `api/client.ts:661` |
| POST/DELETE `/push-token` | user | register/unregister Expo/device push token | `routes/users.ts:295,307`; client `api/client.ts:635-646` |
| GET `/web-push/vapid-public-key` | no | returns publicKey | `routes/users.ts:319`; client `api/client.ts:647` |
| POST/DELETE `/web-push-subscription` | user | register/unregister browser subscription | `routes/users.ts:323,350`; client `api/client.ts:649-660` |
| GET `/me/interactions/blocked` | user | blocked users | `routes/users.ts:362`; client `api/client.ts:444` |
| GET `/search` | user | query/personalized user search; returns users | `routes/users.ts:373`; client `api/client.ts:442` |
| GET `/:id` | user | public user DTO | `routes/users.ts:415`; client `api/client.ts:446` |
| GET `/:id/followers` | user | users | `routes/users.ts:431`; client `api/client.ts:447` |
| GET `/:id/following` | user | users | `routes/users.ts:450`; client `api/client.ts:449` |
| POST/DELETE `/:id/follow` | user | follow/unfollow; returns updated user state | `routes/users.ts:469,552`; client `api/client.ts:455-464` |
| GET `/:id/posts` | user | posts | `routes/users.ts:605`; client `api/client.ts:451` |
| GET `/:id/saved-posts` | user | posts | `routes/users.ts:628`; client `api/client.ts:453` |
| POST `/:id/interactions` | user | type restrict/block/report, optional note | `routes/users.ts:654`; client `api/client.ts:465` |
| DELETE `/:id/interactions/:type` | user | remove restrict/block/report | `routes/users.ts:684`; client `api/client.ts:471` |

## Posts — `/api/posts`

| Method/path | Auth | Purpose/result | Source |
|---|---|---|---|
| GET `/feed` | user | paged personalized posts; query page/limit | `routes/posts.ts:335`; client `api/client.ts:492` |
| GET `/summary` | user | paged posts by summary filter | `routes/posts.ts:369`; client `api/client.ts:499` |
| GET `/search` | user | post search and preference filters | `routes/posts.ts:416`; client `api/client.ts:509` |
| POST `/` | user | create post; returns post | `routes/posts.ts:488`; client `api/client.ts:511` |
| PATCH `/:id` | author | update post; returns post | `routes/posts.ts:552`; client `api/client.ts:517` |
| DELETE `/:id` | author | delete post | `routes/posts.ts:590`; client `api/client.ts:523` |
| POST `/:id/nutrition-insight` | user | AI suitability insight | `routes/posts.ts:616`; client `api/client.ts:538` |
| POST `/:id/like` | user | toggle like; returns liked/stats | `routes/posts.ts:649`; client `api/client.ts:528` |
| POST `/:id/save` | user | toggle save; returns saved/stats | `routes/posts.ts:728`; client `api/client.ts:533` |
| GET `/:id/comments` | user | comments | `routes/posts.ts:760`; client `api/client.ts:543` |
| POST `/:id/comments` | user | body text; returns comment | `routes/posts.ts:778`; client `api/client.ts:545` |

Post schemas, including images, video max duration, transforms, sticker placement and nutrition, are defined at `routes/posts.ts:20-105`. Preserve enum/range validation exactly.

## Messaging — `/api/messages`

| Method/path | Auth | Request/result | Source |
|---|---|---|---|
| GET `/conversations` | user | conversations | `routes/messages.ts:83`; client `api/client.ts:476` |
| POST `/conversations` | user | recipientId; returns conversation | `routes/messages.ts:103`; client `api/client.ts:478` |
| GET `/conversations/:id/messages` | participant | messages | `routes/messages.ts:139`; client `api/client.ts:484` |
| POST `/conversations/:id/messages` | participant | body; returns message | `routes/messages.ts:160`; client `api/client.ts:486` |

## Uploads, Stickers and Meals

| Method/path | Auth | Request/result | Source |
|---|---|---|---|
| POST `/api/uploads?category=...` | user | multipart field defined by upload middleware; returns upload | `routes/uploads.ts:10`; client `api/client.ts:558-605` |
| GET `/api/stickers` | user | stickers | `routes/stickers.ts:8`; client `api/client.ts:551` |
| POST `/api/stickers` | user | name, assetPath, key; returns sticker | `routes/stickers.ts:17`; client `api/client.ts:552` |
| POST `/api/meals/analyze` | user | uploadId and optional hints; returns meal | `routes/meals.ts:17`; client `api/client.ts:606` |
| GET `/api/meals` | user | meals | `routes/meals.ts:50`; client `api/client.ts:612` |
| GET `/api/meals/:id` | user | meal | `routes/meals.ts:59` |

## Notifications — `/api/notifications`

| Method/path | Auth | Result | Source |
|---|---|---|---|
| GET `/` | user | notifications | `routes/notifications.ts:9`; client `api/client.ts:613` |
| DELETE `/` | user | delete all | `routes/notifications.ts:25`; client `api/client.ts:630` |
| PATCH `/read-all` | user | mark all read | `routes/notifications.ts:35`; client `api/client.ts:620` |
| PATCH `/:id/read` | user | notification | `routes/notifications.ts:45`; client `api/client.ts:615` |
| DELETE `/:id` | user | delete one | `routes/notifications.ts:64`; client `api/client.ts:625` |

## Payments — `/api/payments`

| Method/path | Auth | Request/result | Source |
|---|---|---|---|
| GET `/premium/plans` | no | plans | `routes/payments.ts:50`; client `api/client.ts:427` |
| POST `/payos/create` | user | planId; returns checkout/payment data | `routes/payments.ts:54`; client `api/client.ts:428` |
| GET `/payos/:orderCode` | user | payment status | `routes/payments.ts:92`; client `api/client.ts:434` |
| POST `/payos/webhook` | PayOS | signed provider callback; not called by Flutter | `routes/payments.ts:112` |

## Analytics — `/api/ingest`

| Method/path | Auth | Request/result | Source |
|---|---|---|---|
| POST `/events` | optional bearer/context | telemetry event batch/single event | `routes/analytics.ts:401`; client `services/analytics.ts:471` |

Flutter must retain the privacy filtering/batching intent from `client/src/services/analytics.ts`.

## Admin — `/api/admin`

| Method/path | Auth | Purpose | Source |
|---|---|---|---|
| POST `/login` | no | admin token/admin identity | `routes/admin.ts:1048`; client `api/client.ts:202` |
| GET `/dashboard` | admin | KPI/dashboard by time range | `routes/admin.ts:1066`; client `api/client.ts:207` |
| GET `/analytics/summary` | admin | aggregate analytics | `routes/admin.ts:1080`; client `api/client.ts:217` |
| GET `/analytics/24h` | admin | bucketed 24h analytics | `routes/admin.ts:1089`; client `api/client.ts:227` |
| GET `/analytics/heatmap` | admin | time/metric heatmap | `routes/admin.ts:1099`; client `api/client.ts:237` |
| POST `/reports/ai` | admin | AI report for range | `routes/admin.ts:1109`; client `api/client.ts:247` |
| GET `/users` | admin | query/page/limit user list | `routes/admin.ts:1146`; client `api/client.ts:253` |
| GET `/users/insights` | admin | user insights by range | `routes/admin.ts:1178`; client `api/client.ts:261` |
| PATCH `/users/:id/premium` | admin | isPremium, optional note | `routes/admin.ts:1192`; client `api/client.ts:272` |
| GET `/users/:id` | admin | user detail | `routes/admin.ts:1219`; client `api/client.ts:271` |
| GET `/posts` | admin | filtered paged posts | `routes/admin.ts:1275`; client `api/client.ts:278` |
| GET `/posts/insights` | admin | post insights | `routes/admin.ts:1289`; client `api/client.ts:306` |
| PATCH `/posts/:id/moderation` | admin | visible/hidden/review and optional reason | `routes/admin.ts:1298`; client `api/client.ts:326` |
| GET `/reports` | admin | status/page/limit reports | `routes/admin.ts:1333`; client `api/client.ts:332` |
| PATCH `/reports/:id` | admin | open/resolved/dismissed and optional adminNote | `routes/admin.ts:1364`; client `api/client.ts:340` |
| GET `/payments` | admin | query/page/limit payments | `routes/admin.ts:1401`; client `api/client.ts:346` |

## Contract Test Requirements

- DTO decoding tests use captured sanitized fixtures shaped exactly like server DTOs.
- Every enum/range from Zod schemas has valid and invalid tests.
- Multipart tests cover Android file streams and Web bytes/filename/MIME.
- 401 clears the correct user/admin session; no refresh endpoint is assumed.
- Relative media URLs are prefixed once; absolute URLs remain unchanged.
- Admin and user tokens are stored and routed separately.

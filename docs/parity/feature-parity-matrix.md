# Daily Meal Feature Parity Matrix

## Status Legend

- `Not started`: contract identified; no Flutter implementation yet
- `In progress`: implementation exists but verification is incomplete
- `Verified`: implementation and required Android/Web evidence are recorded
- `Accepted limitation`: platform limitation documented and explicitly approved by the user

Phase 0 initializes every product row as `Not started`. A row may become `Verified` only with source mapping, Flutter files, tests and fresh command/manual evidence.

| Slice | Feature/screen | Source reference | APIs/events | Flutter target | Android | Web | Required evidence |
|---:|---|---|---|---|---|---|---|
| 1 | Bootstrap/config | `client/App.tsx`; API base in `client/src/api/client.ts:39` | environment validation | `lib/main.dart`, `lib/app/app.dart`, `lib/app/config/*` | Verified | Verified | config/smoke tests; Android/Web build in `docs/parity/verification-slice-1.md` |
| 1 | Theme/design system | `client/src/theme/*`; shared components | none | `lib/app/theme/*`, `lib/core/widgets/*` | Verified | Verified | Work Sans 400/500/600/700 bundled, Material 3 token tests and platform builds |
| 1 | Responsive shell | navigator and PWA shell | none | `lib/core/responsive/*`, `lib/app/router/*` | Verified | Verified | compact/medium/expanded widget tests and builds |
| 1 | Typed network/errors | `client/src/api/client.ts`; server error middleware | all REST | `lib/core/network/*`, `lib/core/errors/*` | Verified | Verified | bearer/401/error/media URL tests |
| 1 | Session storage | `client/src/context/AuthContext.tsx` | bearer auth | `lib/core/storage/*` | Verified | Verified | shared storage contract tests and platform builds |
| 1 | Analytics adapter | `client/src/services/analytics.ts` | POST `/api/ingest/events` | `lib/core/analytics/*` | Verified | Verified | redaction, exact ingest envelope, 100-event chunking and lifecycle flush |
| 2 | Login/Register | `LoginScreen.tsx`; `AuthContext.tsx` | auth register/login | `features/auth` | Verified | Verified | contract/widget/session tests and Slice 2 builds |
| 2 | Phone/OTP | `LoginScreen.tsx`; login validation | phone endpoints | `features/auth` | Verified | Verified | validation, request/verify and first-time setup tests |
| 2 | Forgot password | `LoginScreen.tsx` | forgot OTP endpoints | `features/auth` | Verified | Verified | request/verify state journey and API contract tests |
| 2 | Google auth/link | `googleSignIn.ts`; auth context | Google endpoints | `features/auth` | In progress | In progress | SDK/token exchange tests and builds pass; live OAuth console/device evidence remains |
| 2 | Facebook auth | `LoginScreen.tsx` | POST `/api/auth/facebook` | `features/auth` | In progress | In progress | Android manifest/plugin registration and Web token exchange verified; real Meta Client Token, key hashes and live login remain |
| 2 | Admin login/guards | `AdminScreens.tsx`; navigator | POST `/api/admin/login` | `features/auth`, `features/admin` | Verified | Verified | dedicated route, session separation, guard and widget tests |
| 2 | Onboarding | `OnboardingScreen.tsx`; preferences constants | PATCH preferences | `features/onboarding` | Verified | Verified | exact options/PATCH contract/controller/widget route tests |
| 3 | Home feed | `HomeScreen.tsx` | GET feed; `post:stats-updated` | `features/feed` | Verified | Verified | page/refresh/append/dedup plus typed live stats update and lifecycle tests, responsive widgets and builds |
| 3 | Image/video/carousel | `HomeScreen.tsx`; `PostVideoPlayer.tsx` | media URLs | `features/feed/presentation` | Verified | Verified | carousel, 65% viewport autoplay/pause, loop/mute/lifecycle behavior, tests and builds |
| 3 | Like/save | Home/PostCard | post like/save; stats event | `features/posts` | Verified | Verified | exact mutation contract plus optimistic success/rollback tests |
| 3 | Double-tap hearts | Home; `tapGestures.ts` | like | `features/feed` | Verified | Verified | like-only gesture/animation widget test and platform builds |
| 3 | Comments | `CommentsScreen.tsx` | comments REST; comment event | `features/comments` | Verified | Verified | REST validation plus join-post/leave-post, live decode/dedup and lifecycle tests |
| 3 | Recipe/nutrition | `RecipeScreen.tsx`; nutrition helpers | nutrition insight | `features/posts`, `meal_analysis` | Verified | Verified | per-image/legacy recipe and nutrition detail decoder/widget tests plus builds |
| 3 | Post summary | `PostSummaryScreen.tsx`; filters | GET summary | `features/user_utility` | Verified | Verified | all/friends/following/strangers, deduplicated paging and responsive grid |
| 4 | Media picker/camera | `CreatePostScreen.tsx`; image picker util | permissions | `core/media`, `features/posts/create` | In progress | In progress | Android/Web adapters, MIME/size/duration tests and builds pass; physical camera/browser chooser evidence remains |
| 4 | Upload image/video | create/edit profile screens | multipart uploads | `core/network/upload` | In progress | In progress | exact multipart field/MIME contract and build verified; live large-file/progress/cancel evidence remains |
| 4 | AI meal analysis | create screen; meal helpers | POST meal analyze | `features/meal_analysis` | In progress | In progress | exact hints/decoder/controller/UI journey verified with mock; live production AI evidence remains |
| 4 | Sticker editor | create screen; sticker helpers | sticker list/create | `features/posts/stickers` | In progress | In progress | list/select/drag/scale/rotate plus Premium upload/create contract implemented; live media capability evidence remains |
| 4 | Create/edit/delete post | Create/Edit screens | post CRUD | `features/posts/editor` | Verified | Verified | exact POST/PATCH/DELETE contracts, owner-only UI, confirmation, feed reconciliation, tests and platform builds |
| 5 | Search posts/users | `SearchScreen.tsx` | post/user search | `features/search` | Verified | Verified | API contract, controller rollback and responsive widget tests |
| 5 | Own profile | `ProfileScreen.tsx` | user/posts/saved | `features/profile` | Verified | Verified | owner route, posts/saved tabs, API/controller/widget tests |
| 5 | Public profile | `PublicProfileScreen.tsx` | user/posts | `features/profile` | Verified | Verified | parameterized route, profile/posts and follow journey tests |
| 5 | Edit profile/avatar | `EditProfileScreen.tsx` | update me/upload | `features/profile/edit` | Verified | Verified | name/bio PATCH plus avatar/cover picker, MIME/size validation and multipart tests |
| 5 | Followers/following | `FollowsScreen.tsx` | follow list/actions | `features/social` | Verified | Verified | exact list APIs, follow rollback and responsive sheet journey |
| 5 | Restrict/block/report | PublicProfile/Blocked | interactions endpoints | `features/social/safety` | Verified | Verified | confirmation UI, optimistic rollback, blocked list and exact endpoint tests |
| 5 | Saved/settings/password | Saved/Settings/ChangePassword | saved, password | `features/user_utility`; profile saved tab | Verified | Verified | exact password contract/validation, saved route, settings/logout/Google link |
| 5 | Support/share account | Support/ShareAccount | no production backend contract | `features/user_utility` | Verified | Verified | preserves explicit not-yet-sent/invite state without fabricating delivery |
| 5 | Progress/streak | `ProgressScreen.tsx`; progress helper | user posts | `features/user_utility` | Verified | Verified | owner post source, likes/comments/post totals and responsive grid |
| 6 | Inbox | `InboxScreen.tsx` | conversations; updated event | `features/messaging/inbox` | In progress | In progress | REST, ordering/dedup, responsive UI and reconnect REST recovery tests pass; live two-session delivery pending |
| 6 | Chat | `ChatScreen.tsx` | messages; message event | `features/messaging/chat` | In progress | In progress | send/receive dedup, room lifecycle, reconnect rejoin/reload and widget journey pass; live delivery pending |
| 6 | Notification center | `NotificationsScreen.tsx`; context | notification CRUD/event | `features/notifications` | In progress | In progress | CRUD rollback, realtime dedup, deep links and reconnect reload pass; live delivery pending |
| 6 | Android push | Notification context | Expo-only push token endpoint | `core/notifications` | Blocked by backend contract | Not started | backend rejects/non-delivers FCM tokens; requires FCM delivery + Firebase config |
| 6 | Web Push | PWA web push/context | VAPID/subscription endpoints | `core/notifications/web` | In progress | In progress | service worker, permission, register/unregister tests and Web build pass; live browser delivery pending |
| 7 | Premium benefits/plans | `PremiumBenefitsScreen.tsx` | plans/trial | `features/premium` | Verified | Verified | exact plan/trial contracts, auth update and responsive widget tests |
| 7 | PayOS payment | Premium screen | create/status | `features/premium/payment` | Verified | Verified | HTTPS checkout abstraction, PENDING/PAID terminal refresh and platform builds |
| 8 | Admin dashboard/KPI | `AdminScreens.tsx` | dashboard/summary | `features/admin` | Verified | Verified | exact range contract, responsive KPI/custom chart, controller/widget tests |
| 8 | Admin AI report | `AdminScreens.tsx` | POST reports/ai | `features/admin` | Verified | Verified | range body, loading/error/result journey |
| 8 | Admin analytics | Admin charts | 24h/heatmap/summary | `features/admin` | Verified | Verified | timezone/preset/metric contracts, 24h chart and semantic heatmap |
| 8 | Admin users | `AdminScreens.tsx` | users/insights/detail/premium | `features/admin` | Verified | Verified | search/page/detail/insights/Premium action contracts and responsive journey |
| 8 | Admin posts/moderation | `AdminScreens.tsx` | posts/insights/moderation | `features/admin` | Verified | Verified | search/filter/page/insights/moderation contracts and responsive cards |
| 8 | Admin reports | `AdminScreens.tsx` | reports/update | `features/admin` | Verified | Verified | status pagination and resolve/dismiss/reopen mutations |
| 8 | Admin payments | `AdminScreens.tsx` | payments | `features/admin` | Verified | Verified | search/page responsive list and exact contract tests |

## Cross-Cutting Acceptance Rows

| Capability | Android | Web | Evidence required |
|---|---|---|---|
| App icon/splash/assets/fonts | Verified | Verified | Daily Meal logo icons/splash/PWA metadata, Work Sans assets and build artifacts |
| Accessibility and 48dp targets | In progress | In progress | semantic media/actions, padded targets and Android AVD accessibility hierarchy verified; full TalkBack/screen-reader walkthrough pending |
| Keyboard/focus/hover | Not applicable | Verified | Material focus/hover states, native Google control, 390px/768px browser walkthrough and email-to-password Tab-order widget evidence |
| Reduced motion | Verified | Verified | `MediaQuery.disableAnimations` removes custom heart durations; widget test |
| Offline/error/retry | Verified | Verified | Dio failures map to safe user messages at the HTTP boundary; Home offline-to-retry recovery and queue-retention tests pass |
| Production configuration | Verified | Verified | Slice 1 debug APK/Web release builds with production dart-defines |
| README/setup/build documentation | Verified | Verified | production defines, run/build commands, architecture and limitations documented |
| React Native route parity | Verified | Verified | reverse navigator audit maps every active source screen to a Flutter route, sheet, tab or responsive Admin destination |

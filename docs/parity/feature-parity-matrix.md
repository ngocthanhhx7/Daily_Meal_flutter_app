# Daily Meal Feature Parity Matrix

## Status Legend

- `Not started`: contract identified; no Flutter implementation yet
- `In progress`: implementation exists but verification is incomplete
- `Verified`: implementation and required Android/Web evidence are recorded
- `Accepted limitation`: platform limitation documented and explicitly approved by the user

Phase 0 initializes every product row as `Not started`. A row may become `Verified` only with source mapping, Flutter files, tests and fresh command/manual evidence.

| Slice | Feature/screen | Source reference | APIs/events | Flutter target | Android | Web | Required evidence |
|---:|---|---|---|---|---|---|---|
| 1 | Bootstrap/config | `client/App.tsx`; API base in `client/src/api/client.ts:39` | environment validation | `lib/app/bootstrap.dart`, `lib/app/config/app_config.dart` | Not started | Not started | config unit tests; release defines |
| 1 | Theme/design system | `client/src/theme/*`; shared components | none | `lib/app/theme/*`, `lib/core/widgets/*` | Not started | Not started | theme/widget/golden tests |
| 1 | Responsive shell | navigator and PWA shell | none | `lib/core/responsive/*`, `lib/app/router/*` | Not started | Not started | 4 viewport widget/golden checks |
| 1 | Typed network/errors | `client/src/api/client.ts`; server error middleware | all REST | `lib/core/network/*`, `lib/core/errors/*` | Not started | Not started | interceptor/error/media URL tests |
| 1 | Session storage | `client/src/context/AuthContext.tsx` | bearer auth | `lib/core/storage/*` | Not started | Not started | platform storage tests/fakes |
| 1 | Analytics adapter | `client/src/services/analytics.ts` | POST `/api/ingest/events` | `lib/core/analytics/*` | Not started | Not started | redaction/batch tests |
| 2 | Login/Register | `LoginScreen.tsx`; `AuthContext.tsx` | auth register/login | `features/auth` | Not started | Not started | widget + integration journey |
| 2 | Phone/OTP | `LoginScreen.tsx`; login validation | phone endpoints | `features/auth` | Not started | Not started | validation/controller/integration tests |
| 2 | Forgot password | `LoginScreen.tsx` | forgot OTP endpoints | `features/auth` | Not started | Not started | state and journey tests |
| 2 | Google auth/link | `googleSignIn.ts`; auth context | Google endpoints | `features/auth` | Not started | Not started | supported-platform auth evidence |
| 2 | Facebook auth | `LoginScreen.tsx` | POST `/api/auth/facebook` | `features/auth` | Not started | Not started | auth result/error evidence |
| 2 | Admin login/guards | `AdminScreens.tsx`; navigator | POST `/api/admin/login` | `features/auth`, `features/admin` | Not started | Not started | guard/integration tests |
| 2 | Onboarding | `OnboardingScreen.tsx`; preferences constants | PATCH preferences | `features/onboarding` | Not started | Not started | widget + persisted route test |
| 3 | Home feed | `HomeScreen.tsx` | GET feed; post stats event | `features/feed` | Not started | Not started | pagination/refresh/integration |
| 3 | Image/video/carousel | `HomeScreen.tsx`; `PostVideoPlayer.tsx` | media URLs | `features/posts/presentation` | Not started | Not started | lifecycle and viewport tests |
| 3 | Like/save | Home/PostCard | post like/save; stats event | `features/posts` | Not started | Not started | rollback/dedup tests |
| 3 | Double-tap hearts | Home; `tapGestures.ts` | like | `features/feed` | Not started | Not started | timing/reduced-motion tests |
| 3 | Comments | `CommentsScreen.tsx` | comments REST; comment event | `features/posts/comments` | Not started | Not started | room lifecycle/realtime tests |
| 3 | Recipe/nutrition | `RecipeScreen.tsx`; nutrition helpers | nutrition insight | `features/posts`, `meal_analysis` | Not started | Not started | decoding/widget tests |
| 3 | Post summary | `PostSummaryScreen.tsx`; filters | GET summary | `features/posts/summary` | Not started | Not started | filter/paging tests |
| 4 | Media picker/camera | `CreatePostScreen.tsx`; image picker util | permissions | `core/media`, `features/posts/create` | Not started | Not started | Android/Web capability evidence |
| 4 | Upload image/video | create/edit profile screens | multipart uploads | `core/network/upload` | Not started | Not started | progress/cancel/platform tests |
| 4 | AI meal analysis | create screen; meal helpers | POST meal analyze | `features/meal_analysis` | Not started | Not started | mapping/controller/integration |
| 4 | Sticker editor | create screen; sticker helpers | sticker list/create | `features/posts/stickers` | Not started | Not started | transform/range/gesture tests |
| 4 | Create/edit/delete post | Create/Edit screens | post CRUD | `features/posts/editor` | Not started | Not started | publish/edit/delete journey |
| 5 | Search posts/users | `SearchScreen.tsx` | post/user search | `features/search` | Not started | Not started | debounce/filter/personalized tests |
| 5 | Own profile | `ProfileScreen.tsx` | user/posts/saved | `features/profile` | Not started | Not started | tabs/state/widget tests |
| 5 | Public profile | `PublicProfileScreen.tsx` | user/posts/saved | `features/profile` | Not started | Not started | route/data tests |
| 5 | Edit profile/avatar | `EditProfileScreen.tsx` | update me/upload | `features/profile/edit` | Not started | Not started | validation/upload tests |
| 5 | Followers/following | `FollowsScreen.tsx` | follow list/actions | `features/social` | Not started | Not started | mutation/list tests |
| 5 | Restrict/block/report | PublicProfile/Blocked | interactions endpoints | `features/social/safety` | Not started | Not started | confirmation/error tests |
| 5 | Saved/settings/password | Saved/Settings/ChangePassword | saved, password | respective features | Not started | Not started | widget/journey tests |
| 5 | Support/share account | Support/ShareAccount | platform share/support | `features/profile/utility` | Not started | Not started | platform behavior evidence |
| 5 | Progress/streak | `ProgressScreen.tsx`; progress helper | user/post data | `features/profile/progress` | Not started | Not started | summary/unit/widget tests |
| 6 | Inbox | `InboxScreen.tsx` | conversations; updated event | `features/messaging/inbox` | Not started | Not started | ordering/dedup/reconnect tests |
| 6 | Chat | `ChatScreen.tsx` | messages; message event | `features/messaging/chat` | Not started | Not started | send/receive/room journey |
| 6 | Notification center | `NotificationsScreen.tsx`; context | notification CRUD/event | `features/notifications` | Not started | Not started | action/state/deep-link tests |
| 6 | Android push | Notification context | push token endpoints | `core/notifications` | Not started | Not started | device token lifecycle evidence |
| 6 | Web Push | PWA web push/context | VAPID/subscription endpoints | `core/notifications/web` | Not started | Not started | browser permission/subscription evidence |
| 7 | Premium benefits/plans | `PremiumBenefitsScreen.tsx` | plans/trial | `features/premium` | Not started | Not started | plan/trial state tests |
| 7 | PayOS payment | Premium screen | create/status | `features/premium/payment` | Not started | Not started | return/status terminal states |
| 8 | Admin dashboard/KPI | `AdminScreens.tsx` | dashboard/summary | `features/admin/dashboard` | Not started | Not started | ranges/responsive charts |
| 8 | Admin AI report | `AdminScreens.tsx` | POST reports/ai | `features/admin/reports` | Not started | Not started | loading/error/result tests |
| 8 | Admin analytics | Admin charts | 24h/heatmap/summary | `features/admin/analytics` | Not started | Not started | chart mapping/golden tests |
| 8 | Admin users | `AdminScreens.tsx` | users/insights/detail/premium | `features/admin/users` | Not started | Not started | search/page/action journey |
| 8 | Admin posts/moderation | `AdminScreens.tsx` | posts/insights/moderation | `features/admin/posts` | Not started | Not started | filter/moderate tests |
| 8 | Admin reports | `AdminScreens.tsx` | reports/update | `features/admin/reports` | Not started | Not started | resolve/dismiss journey |
| 8 | Admin payments | `AdminScreens.tsx` | payments | `features/admin/payments` | Not started | Not started | search/page/responsive tests |

## Cross-Cutting Acceptance Rows

| Capability | Android | Web | Evidence required |
|---|---|---|---|
| App icon/splash/assets/fonts | Not started | Not started | build artifact and visual check |
| Accessibility and 48dp targets | Not started | Not started | semantics/widget/manual evidence |
| Keyboard/focus/hover | Not applicable | Not started | keyboard walkthrough |
| Reduced motion | Not started | Not started | setting-driven widget/manual check |
| Offline/error/retry | Not started | Not started | network failure tests |
| Production configuration | Not started | Not started | release build commands |
| README/setup/build documentation | Not started | Not started | clean setup walkthrough |

# Daily Meal Source Inventory

## Baseline

- Inventory date: 2026-07-11
- Source: `D:\WW\Daily_Meal_App\daily_meal` at `d135258` (`main`), clean working tree
- Target: `D:\WW\Daily_Meal_flutter_app` at `4ee8176` (`master`)
- Flutter: 3.41.9 stable
- Dart: 3.11.5
- Production API: `https://api.dailymeal.site`

The target contains an uncommitted Flutter scaffold owned by the user. Phase 0 does not modify those scaffold files.

## Baseline Verification

`flutter pub get` succeeds. The initial target does not pass analysis or tests:

- `test/widget_test.dart:11` imports the nonexistent package `daily_meal_app` while `pubspec.yaml` declares `daily_meal_flutter_app`.
- `test/widget_test.dart:16` constructs the nonexistent `MyApp` class.
- Fresh result: 3 analyzer issues and one test compilation failure.

These are pre-existing scaffold failures to address in Slice 1 with a red/green bootstrap test.

The source baseline is healthy: root `npm.cmd run typecheck` exits 0 for both server and client, and root `npm.cmd test` exits 0 with 4 test files and 74 tests passing. This establishes the source contracts as a reliable migration baseline.

## Client Entry and Navigation

| Area | Source | Responsibility |
|---|---|---|
| Entry | `client/App.tsx`, `client/index.js` | Application providers and Expo entry |
| Navigation | `client/src/navigation/AppNavigator.tsx` | Auth/admin/onboarding guards and all user routes |
| Auth state | `client/src/context/AuthContext.tsx` | Session restoration, user/admin login and profile mutations |
| Realtime | `client/src/context/SocketContext.tsx` | Authenticated Socket.IO lifecycle |
| Notifications | `client/src/context/NotificationContext.tsx` | REST, realtime, Android push and Web Push state |
| REST client | `client/src/api/client.ts` | Production base URL, auth requests, multipart and typed capabilities |
| API types | `client/src/types/api.ts` | User, post, meal, admin, message and payment shapes |

Navigation source references: auth/admin/onboarding branching at `client/src/navigation/AppNavigator.tsx:108-128`; user routes at lines 131-170.

## Screens

Production routes/screens:

- Access: `LoginScreen.tsx`, admin login inside `AdminScreens.tsx`, `OnboardingScreen.tsx`
- Feed/content: `HomeScreen.tsx`, `CommentsScreen.tsx`, `RecipeScreen.tsx`, `PostSummaryScreen.tsx`
- Creation: `CreatePostScreen.tsx`, `EditPostScreen.tsx`; `MealsScreen.tsx` is legacy and explicitly removed from navigation
- Discovery/social: `SearchScreen.tsx`, `PublicProfileScreen.tsx`, `FollowsScreen.tsx`, `BlockedScreen.tsx`
- Account: `ProfileScreen.tsx`, `EditProfileScreen.tsx`, `ChangePasswordScreen.tsx`, `SettingsScreen.tsx`, `SavedScreen.tsx`
- Messaging: `InboxScreen.tsx`, `ChatScreen.tsx`
- Growth/utility: `NotificationsScreen.tsx`, `ProgressScreen.tsx`, `SupportScreen.tsx`, `ShareAccountScreen.tsx`, `PremiumBenefitsScreen.tsx`
- Admin: `AdminScreens.tsx` exports login, dashboard, user list and user detail; dashboard contains post moderation, reports, payments and analytics sections

There are 46 files under `client/src/screens`, including pure helpers and 13 focused test files. `HomeScreen.tsx`, `CreatePostScreen.tsx`, and `AdminScreens.tsx` are large behavioral references and must be decomposed rather than ported as god files.

## Shared Client Code

- Components (17 files): branded text/buttons/surfaces, post cards/previews, image/video, nutrition, sticker, animation, SVG and admin charts.
- Utilities: feed pagination, tap gesture timing, media playback, post navigation/previews, nutrition conversion, content state, keyboard avoidance, progress summary and sticker placement.
- Services: analytics/telemetry and Google Sign-In.
- PWA: install gate, mobile Web shell, platform detection and Web Push helpers.
- Theme: `colors.ts`, `spacing.ts`, `typography.ts`.
- Preferences: `client/src/constants/preferences.ts`.

## Server Inventory

| Group | Files | Notes |
|---|---:|---|
| Route modules | 12 | admin, analytics, auth, meals, messages, notifications, onboarding, payments, posts, stickers, uploads, users |
| Models | 16 | users, posts, follows, interactions, comments, messages, notifications, payments, uploads, stickers and analytics |
| Services | 16 | auth, Google, SMS/email, PayOS, push, Socket.IO, storage, AI meal suitability and admin analytics/reports |
| Middleware | 4 | auth/admin auth, errors, validation and uploads |
| API tests | 1 suite plus service tests | `server/src/tests/api.test.ts` and focused service tests |

Router mount points are defined at `server/src/app.ts:40-51`. Static uploads are exposed at `server/src/app.ts:34`.

## Delivery Slices

1. Foundation/contracts
2. Auth/onboarding
3. Feed/content
4. Creation/media/AI
5. Search/profile/social
6. Messaging/notifications
7. Premium/payments
8. Admin

Each slice must update the parity matrix and retain source references as evidence.

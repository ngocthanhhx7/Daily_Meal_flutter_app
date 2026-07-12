# React Native to Flutter route audit

Date: 2026-07-12

This audit starts from the current React Native `AppNavigator.tsx`, rather than
from the Flutter feature list, to detect omitted user-visible flows.

## Auth and main navigation

| React Native screen | Flutter destination | Result |
|---|---|---|
| `LoginScreen` | `/login` — `LoginScreen` | Mapped |
| `AdminLoginScreen` | `/admin/login` — `AdminLoginScreen` | Mapped |
| `OnboardingScreen` | `/onboarding` — `OnboardingScreen` | Mapped |
| `HomeScreen` | `/` — `HomeScreen` | Mapped |
| `SearchScreen` | `/search` — `SearchScreen` | Mapped |
| `CreatePostScreen` | `/create` — `CreatePostScreen` | Mapped |
| `ProfileScreen` | `/profile` — `ProfileScreen` | Mapped |
| `PublicProfileScreen` | `/users/:id` — parameterized `ProfileScreen` | Mapped |
| `FollowsScreen` | responsive followers/following sheet from Profile | Consolidated |
| `InboxScreen` | `/messages` — `InboxScreen` | Mapped |
| `ChatScreen` | `/messages/:id` — `ChatScreen` | Mapped |

## Content, profile and utilities

| React Native screen | Flutter destination | Result |
|---|---|---|
| `CommentsScreen` | responsive `CommentsSheet` from each post | Consolidated modal |
| `RecipeScreen` | responsive `RecipeNutritionSheet` | Consolidated modal |
| `EditPostScreen` | `/posts/edit` with typed `FeedPost` extra | Mapped |
| `EditProfileScreen` | edit mode within owner `ProfileScreen` | Consolidated |
| `ChangePasswordScreen` | `/settings/password` | Mapped |
| `SettingsScreen` | `/settings` | Mapped |
| `NotificationsScreen` | `/notifications` | Mapped |
| `SavedScreen` | `/profile/saved` — saved Profile tab | Consolidated |
| `PostSummaryScreen` | `/posts/summary` | Mapped |
| `BlockedScreen` | `/profile/blocked` | Mapped |
| `SupportScreen` | `/support` | Mapped |
| `ShareAccountScreen` | `/profile/share` | Mapped |
| `PremiumBenefitsScreen` | `/premium` | Mapped |
| `ProgressScreen` | `/profile/progress` | Mapped |

## Admin

The React Native navigator exposes `AdminDashboard`, `AdminUsers` and
`AdminUserDetail`. Flutter consolidates these, plus posts, reports, payments and
analytics, into the responsive `/admin` shell. Compact layouts use destination
navigation and cards; larger layouts use the expanded management workspace.
Typed controller/API tests cover each management destination and detail action.

## Deliberately excluded source files

- `MealsScreen.tsx` still exists in the source tree, but the current React
  Native navigator explicitly states that it was removed because calorie
  analysis moved to `CreatePostScreen`. Flutter implements that analysis in its
  Create Post flow and correctly does not expose a stale Meals route.
- `POST /api/posts/:id/nutrition-insight` exists in the backend and legacy API
  client but has no call site in any current React Native screen. Adding a new
  button for it would expand product behavior rather than reproduce the app.
- Native push-token registration is not mapped because the backend delivery
  worker filters exclusively for `ExponentPushToken[` values and sends through
  Expo. The separate Android FCM limitation remains explicit in the parity
  matrix.

## Audit conclusion

Every screen registered by the current React Native navigator has a Flutter
route, responsive modal, tab or consolidated Admin destination. No active
source screen is represented only by a placeholder route.

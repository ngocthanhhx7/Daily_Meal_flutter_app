# Daily Meal Flutter Master Prompt — Design Specification

## Objective

Create a master implementation prompt that directs a coding agent to rebuild the existing Daily Meal Expo/React Native client as a production-ready Flutter application. The Flutter application must preserve the original product identity, content, behavior, navigation, API integration, and feature scope while allowing targeted UX improvements using Material 3.

The existing Node.js backend remains the source of truth and is already deployed at `https://api.dailymeal.site`. Rebuilding or changing the backend is out of scope unless an endpoint incompatibility is proven and documented.

## Source and Target

- Source monorepo: `D:\WW\Daily_Meal_App\daily_meal`
- Source client: `D:\WW\Daily_Meal_App\daily_meal\client`
- Source backend contract: `D:\WW\Daily_Meal_App\daily_meal\server`
- Target Flutter workspace: `D:\WW\Daily_Meal_flutter_app`
- Target platforms: Android and Flutter Web
- Admin layout targets: phone and tablet responsive behavior, with a usable wide-Web layout

## Product Parity Scope

The Flutter version includes the complete user product and the complete admin product. “Mobile-first” does not permit removing admin functionality.

### Identity and Access

- Email registration and login
- Phone registration/login and OTP verification
- Forgotten-password OTP flow
- Google login and Google account linking
- Facebook login
- Persistent user and admin sessions
- User, onboarding, and admin route guards

### Onboarding and Personalization

- Interest and eating-style selection
- Persisted onboarding completion
- Personalized feed and search inputs

### Feed and Content

- Locket-style home feed with pagination and refresh
- Image, multi-image, and video presentation
- Like, save, comments, and realtime post-stat updates
- Double-tap heart-rain interaction
- Recipe detail, nutrition detail/insight, post summary, and filtering
- Correct loading, empty, error, retry, and pagination states

### Creation and AI Meal Analysis

- Camera and gallery permissions
- Multi-image and short-video selection/capture
- Multipart upload with validation and progress
- AI meal analysis using the existing backend
- Calories, nutrients, meal suitability, recipe metadata, and captions
- Sticker list, sticker creation, placement, scaling, and rotation
- Create, edit, and delete posts

### Social, Profiles, and Messaging

- Personalized post and user search with filters
- Own profile and public profiles
- Followers/following lists
- Follow/unfollow
- Restrict, block, report, and unblock
- Saved posts
- Inbox, conversation creation, realtime chat, and message deduplication

### Notifications, Progress, and Utilities

- Notification list, mark one/all read, delete one/all
- Android push registration and Web Push where supported by the existing backend
- Progress and streak presentation
- Settings, edit profile/avatar, password change, support, and share-account flows
- Existing analytics/telemetry behavior without sensitive data leakage

### Premium and Payments

- Premium benefits and plan selection
- Premium trial claim
- PayOS payment creation and status handling
- Success, cancel, failure, expired, and already-premium states

### Administration

- Separate admin authentication and route guard
- Dashboard KPIs and selectable date ranges
- AI-generated admin reports
- Analytics summary, 24-hour charts, interaction charts, and heatmap
- User search, pagination, insights, details, and premium controls
- Post filtering, pagination, insights, and moderation status/reason
- Report queues and open/resolved/dismissed workflows with admin notes
- Payment search, pagination, and transaction presentation

## Architecture

Use a contract-first, vertical-slice delivery strategy. Inspect and record the existing REST and Socket.IO contracts before implementing dependent Flutter code. Implement slices in this order:

1. Project foundation and API contract inventory
2. Authentication and onboarding
3. Feed and post consumption
4. Creation, media, stickers, and AI analysis
5. Search, profiles, and social relationships
6. Chat and notifications
7. Premium and payments
8. Administration

Each slice must run end-to-end against the real backend and include responsive UI, state management, failure states, and tests before it is considered complete.

Use a feature-first structure with isolated presentation, application, domain, and data responsibilities. Recommended technical baseline:

- Riverpod with immutable asynchronous state
- GoRouter with user/onboarding/admin guards
- Dio with typed request handling and interceptors
- Freezed/json_serializable or an equivalently robust typed-model approach
- Socket.IO client with authenticated reconnect and lifecycle-safe room management
- Secure token storage on Android and the safest Web session mechanism compatible with the backend contract
- Cached media, camera/image picker, video playback, charts, notifications, and Web Push packages selected for current Flutter stable compatibility

Package versions must be verified when implementation begins rather than frozen in the prompt.

## Visual System and Responsive Behavior

Preserve the original Daily Meal identity and reuse authorized source assets, logo, icons, imagery, Vietnamese copy, and the established palette:

- Ink `#202124`
- Muted `#74746F`
- Line `#E4E1D8`
- Surface `#FFFFFF`
- Canvas `#F4F3EF`
- Strong canvas `#ECE9DF`
- Green `#8BA58A`
- Dark green `#4F6F3D`
- Yellow `#F6DE68`
- Red `#E65B55`
- Blue `#65A9D7`

Material 3 adaptations may improve accessibility, hierarchy, touch behavior, keyboard behavior, and responsiveness without changing product meaning or removing flows.

- Phone: bottom navigation and native-feeling stack/modal transitions
- Tablet/narrow Web: adaptive NavigationRail or drawer
- Wide Web user experience: centered readable content rather than stretched mobile UI
- Wide Web admin: sidebar with responsive charts, tables, filters, and detail panes
- Narrow admin: tables transform into cards/lists; all actions remain available

Validate at 360×800, 600×1024, 1024×768, and 1440×900.

## Production Configuration and Security

Runtime/build-time configuration must support:

- `API_BASE_URL=https://api.dailymeal.site`
- `FACEBOOK_APP_ID=3483710358450589`
- `GOOGLE_WEB_CLIENT_ID=20654020356-nsqam5ladrg7j5v6agefq8pucnrcqtn8.apps.googleusercontent.com`

Use `--dart-define` or a non-committed environment mechanism. These identifiers are configuration, not authorization to commit private client secrets. Never log JWTs, OTPs, credentials, authorization headers, or sensitive request bodies.

Dio must consistently handle base URLs, relative upload/media URLs, bearer tokens, timeouts, structured backend errors, and unauthorized sessions. Do not invent token refresh behavior when the backend does not provide it.

Socket connections must authenticate according to the existing server, reconnect with bounded backoff, join and leave rooms with widget/application lifecycle, remove listeners, and deduplicate realtime payloads.

## State and Failure Handling

Every asynchronous surface includes explicit initial/loading, data, empty, error, retry, refreshing, and pagination states as applicable. Mutations may use optimistic updates only when rollback is deterministic. Upload and payment flows expose progress and terminal failure/cancel states.

Unsupported platform capabilities must degrade intentionally. For example, Web camera, notifications, and third-party authentication must show actionable compatibility guidance instead of failing silently.

## Verification and Definition of Done

The implementation agent maintains a parity matrix that maps every React Native screen, API method, Socket.IO event, permission, asset group, and user/admin journey to its Flutter implementation and verification evidence.

Required verification includes:

- Unit tests for DTO/domain mapping, repositories, controllers, pagination, and pure behavior
- Widget tests for major loading/data/empty/error states and responsive variants
- Integration tests for critical user and admin journeys
- Golden tests for important branded screens/components where stable
- Accessibility semantics, minimum 48dp touch targets, reasonable contrast, Web keyboard navigation, and reduced-motion handling
- `dart format` verification
- `flutter analyze`
- `flutter test`
- Android release build
- Flutter Web release build

Completion is not permitted while TODOs, long-lived mock data, placeholder screens, dead controls, unhandled critical console errors, or unmapped parity items remain.

## Master Prompt Behavior

The final master prompt must instruct the coding agent to:

1. Inspect source code rather than rely only on this summary.
2. Preserve unrelated user changes in the Flutter workspace.
3. Create an evidence-based inventory and phased plan before implementation.
4. Implement the approved vertical slices without rewriting the backend.
5. Use real production-compatible contracts and avoid speculative endpoints.
6. Verify after every slice and report concrete commands/results.
7. Continue until the parity matrix and build/test gates are satisfied.

The prompt should be executable as a single master instruction but explicitly require phased checkpoints, small focused files, and evidence before completion claims.

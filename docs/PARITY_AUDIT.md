# Daily Meal Flutter parity audit

Updated: 2026-07-13. Authorities, in order: production React Native source, production site, approved Figma, Flutter implementation.

## Route coverage

React Native registers 29 active routes in `client/src/navigation/AppNavigator.tsx`; Flutter now exposes all 29 route identities in `lib/app/router/app_route.dart`.

| React Native route | Flutter mapping | Status | Priority |
|---|---|---|---|
| Login, AdminLogin, Onboarding, Home, Search, Create, Profile, PublicProfile | Equivalent named routes | Present | P0 |
| Inbox, Chat, EditProfile, Settings, ChangePassword, Notifications | Equivalent named routes | Present | P0/P1 |
| Saved, PostSummary, Blocked, Support, ShareAccount, PremiumBenefits, Progress | Equivalent feature routes | Present; utility shell and core states source-aligned | P1/P2 |
| AdminDashboard | `/admin` | Present | P0 |
| Follows | `/users/:id/follows?tab=` / `FollowsScreen` | Present and refresh-safe | P1 |
| Comments | `/posts/:id/comments` / `CommentsScreen` | Present; hero gracefully falls back after refresh | P0 |
| Recipe | `/posts/:id/recipe?authorId=` / `RecipeScreen` | Present; restores through author posts contract | P0 |
| AdminUsers | `/admin/users` / restored Admin destination | Present and refresh-safe | P0 |
| AdminUserDetail | `/admin/users/:id` / responsive detail workspace | Present and refresh-safe | P0 |

Additional routing gaps:

- Edit Post uses `/posts/:id/edit?authorId=` and restores through the author-posts contract after Web refresh.
- Notification taps return to Home but do not focus the referenced post.
- Android does not yet expose the `dailymeal://` VIEW/BROWSABLE scheme.
- The production backend has no verified `GET /api/posts/:id`; Recipe and Edit Post therefore restore through `GET /api/users/:authorId/posts`. Notification focus still needs an author-aware destination or a backend single-post contract.

## UI priority matrix

| Surface | Current parity | Remaining highest-impact work |
|---|---|---|
| Home header/action bar | Close | Replace remaining Material center icons, badge geometry and motion |
| Home artwork | Close for one image | Dedicated 2/3/4-image spread, sticker placement, heart rain, expanded video |
| Search/Profile/Inbox compact shell | Improved | Complete device-level visual regression and remaining post-result composition |
| Edit Profile | Feature-complete baseline | Refine TextField/segment/chip geometry and picker permission copy |
| Profile/Public Profile | Partial | Source header/menu/CTA geometry and dedicated public composition |
| Comments | Improved | Complete populated-production visual regression and category sheet |
| Recipe | Partial | Full-screen header/author footer and route identity |
| Create/Edit Post | Improved | Finish Create capture-state visual regression and device QA |
| Notifications/Chat/Settings | Improved | Complete device-level visual regression and refine edge states |
| Admin Dashboard/KPI/Analytics | Partial-high | Chart hierarchy and responsive density |
| Admin Posts/Payments/Reports/AI | Partial | Media previews, filters, charts and complete metadata |
| Admin Users/User Detail | Low | Analytics-rich list plus full responsive detail workspace |

## Evidence produced

- Home before: `C:\tmp\dailymeal-before-priority.png`
- Home action-bar after: `C:\tmp\dailymeal-home-actionbar-after2.png`
- Home artwork/overlay after: `C:\tmp\dailymeal-home-artwork-after.png`
- Latest authenticated Android cold-start/Home: `C:\tmp\dailymeal-user-check.png`
- Latest Android owner Profile: `C:\tmp\dailymeal-profile-check.png`
- Comments production fallback/composer: `C:\tmp\dailymeal-comments-after.png`
- Android debug build passed with production API defines.
- Web release build passed with production API defines.
- Full Flutter suite last verified at 185 passing tests after F014/F015; targeted Home/responsive tests passed after F016/F017.
- Full Flutter suite verified at 203 passing tests after the source-style Edit Post slice; no-define debug APK built, installed and resumed `MainActivity` on `emulator-5554` without Flutter/configuration crashes.

## Next execution order

1. Finish Home 2/3/4-image layouts and source SVG/motion.
2. Route and rebuild Comments/Recipe using a refresh-safe post retrieval contract.
3. Refine Profile/Public Profile and Edit Profile visual geometry.
4. Implement Admin Users and Admin User Detail as URL-addressable responsive screens.
5. Complete remaining P1 user surfaces.

Notification post taps now preserve `postId` in the Home URL and search a
bounded number of feed pages before focusing the referenced post. Missing or
deleted posts produce an explicit message instead of silently opening the
wrong feed item. Android also accepts the React Native-compatible
`dailymeal://` custom scheme; verified HTTPS App Links remain out of scope
until `dailymeal.site` publishes Digital Asset Links.

Profile owner parity now includes the source bottom-sheet menu, native
Android/Web profile sharing, and post-grid navigation to the refresh-safe edit
route. Recipe parity now uses the source full-screen header, artwork fallback,
recipe-only content, author footer and author navigation. Search opens Recipe
as a full screen, while post notifications follow the source mapping:
Like -> Recipe and Comment -> Comments.

Admin AI reports now decode and render the full production response contract:
typed section objectives, metric assessment/meaning, insights, conclusions,
section actions, anomalies, risks, priority actions, range and metric snapshot.

Admin Posts now forwards independent search, moderation, range/custom-date,
media-kind and sorting state to both list and insight endpoints. The responsive
workspace renders source-style KPI cards, media previews, author/status/stats
metadata and explicit visible/review/hidden moderation actions without compact
header overflow.

User-first follow-up: Public Profile now loads and exposes public Saved posts,
renders birthday visibility, uses source Follow/Message ordering and blocked
states, and provides a URL-addressable people-search menu action. Edit Profile
now uses the source avatar labels, compact header geometry, rectangular
birthday/preference controls and 50px primary/ghost actions.

Android bootstrap no longer depends on external `--dart-define` flags for the
known production deployment. `AppConfig.fromEnvironment()` ships the approved
production API/social public identifiers while preserving build-time
overrides and strict `fromMap` validation. A no-define debug APK cold-started
to Login on AVD with no splash hang or Flutter configuration exception.

Messaging now matches the source mobile composition: Inbox back/title copy,
48px avatars and compact rows; Chat 188px gradient hero, participant avatar,
timestamped white/sage bubbles, source composer and empty state. Notifications
now uses the source header, count/bulk toolbar, typed colors, relative time,
unread dot, swipe delete and explicit row delete while preserving deep links.

Premium now follows the source benefits header/banner, three benefit cards and
yellow active-plan treatment while preserving the working PayOS lifecycle.
Settings and user utilities now share source-style compact headers, bordered
rows/cards, yellow logout/unblock actions, FAQ and family-share copy, explicit
empty/error states, and confirmation before unblocking. The intentionally
unavailable family API remains clearly disclosed instead of simulating success.

Search now uses the source back/home title row, discovery hero, 56px search
action, branded quick filters and black segmented control. People results use
the source 50px avatar card, bio/follower fallback and friend/follow-back labels;
the existing API filters, URL initialization and public-profile routing remain intact.

Edit Post now matches the production interaction model: a source-style stacked
media preview and caption metadata card lead into action rows for feed focus,
bottom-sheet caption/tag editing, optional Recipe navigation and confirmed
deletion. Existing refresh-safe route restoration and update/delete contracts
remain unchanged.

Comments now preserves backend like counts, renders source-style participant
bubbles with avatar overlap, relative time, reply focus, local double-tap heart
feedback and the translucent rounded composer. Its 128px post hero uses the
production fade mask and falls back to the bundled source asset when legacy
production media returns 404, verified on the authenticated Android AVD.
6. Run screen-by-screen Android/Web visual regression and accessibility/performance gates.

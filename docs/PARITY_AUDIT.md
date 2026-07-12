# Daily Meal Flutter parity audit

Updated: 2026-07-13. Authorities, in order: production React Native source, production site, approved Figma, Flutter implementation.

## Route coverage

React Native registers 28 active routes in `client/src/navigation/AppNavigator.tsx`; Flutter exposes all 28 route identities uniquely in `lib/app/router/app_route.dart`.

| React Native route | Flutter mapping | Status | Priority |
|---|---|---|---|
| Login, AdminLogin, Onboarding, Home, Search, Create, Profile, PublicProfile | Equivalent named routes | Present | P0 |
| Inbox, Chat, EditProfile, Settings, ChangePassword, Notifications | Equivalent named routes | Present | P0/P1 |
| Saved, PostSummary, Blocked, Support, ShareAccount, PremiumBenefits, Progress | Equivalent feature routes | Present; utility composition and core states source-aligned | P1/P2 |
| AdminDashboard | `/admin` | Present | P0 |
| Follows | `/users/:id/follows?tab=` / `FollowsScreen` | Present and refresh-safe | P1 |
| Comments | `/posts/:id/comments` / `CommentsScreen` | Present; hero gracefully falls back after refresh | P0 |
| Recipe | `/posts/:id/recipe?authorId=` / `RecipeScreen` | Present; restores through author posts contract | P0 |
| AdminUsers | `/admin/users` / restored Admin destination | Present and refresh-safe | P0 |
| AdminUserDetail | `/admin/users/:id` / responsive detail workspace | Present and refresh-safe | P0 |

Routing notes:

- Edit Post and Recipe use author-aware URLs and restore through the production author-posts contract after Web refresh.
- Notification post taps preserve `postId`; Like routes to Recipe, Comment routes to Comments, and general post targets focus Home.
- Android exposes the React Native-compatible `dailymeal://` VIEW/BROWSABLE scheme. Verified HTTPS App Links still require Digital Asset Links on the production domain.

## UI priority matrix

| Surface | Current parity | Remaining highest-impact work |
|---|---|---|
| Home header/action bar | Close | Replace remaining Material center icons, badge geometry and motion |
| Home artwork | Close | Complete device visual regression for 2/3/4-image spread and video |
| Search/Profile/Inbox compact shell | Improved | Complete device-level visual regression |
| Edit Profile | Improved | Complete device visual regression and picker permission copy |
| Profile/Public Profile | Improved | Complete device visual regression for populated profiles |
| Comments | Improved | Complete populated-production visual regression and category sheet |
| Recipe | Close | Complete populated-production device visual regression |
| Create/Edit Post | Improved | Complete Premium capture/sticker device visual regression |
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
- Create Post Free capture state: `C:\tmp\dailymeal-create-capture.png`
- Home production-media fallback restored: `C:\tmp\dailymeal-home-media-fallback.png`
- Android user-route matrix: `C:\tmp\matrix-search.png`, `C:\tmp\matrix-edit-profile.png`, `C:\tmp\matrix-saved.png`, `C:\tmp\matrix-inbox.png`, `C:\tmp\matrix-notifications.png`, `C:\tmp\matrix-premium.png`, `C:\tmp\matrix-post-summary.png`, `C:\tmp\matrix-support.png`, `C:\tmp\matrix-share-account.png`, and `C:\tmp\matrix-create.png`.
- Settings crash regression fixed and cold-start verified on Android: `C:\tmp\matrix-settings-fixed.png`; device log contained no Flutter assertion, overflow, or fatal exception.
- Web login responsive evidence: `C:\tmp\web-login-mobile-retry.png`, `C:\tmp\web-login-tablet.png`, and `C:\tmp\web-login-desktop.png`. The 375 px, 768 px, and 1280 px viewports render without overflow.
- Authenticated Web mobile matrix covers Home, Search, Profile, Edit Profile, Saved, Inbox, Notifications, Premium, Settings, Post Summary, Progress, Support, Share Account, and Create under `C:\tmp\web-matrix-*-mobile.png`.
- Authenticated tablet evidence covers the complex Home, Search, Edit Profile, Settings, Post Summary, and Create layouts under `C:\tmp\web-matrix-*-tablet.png`; Search correctly switches to navigation rail while mobile-first screens remain centered and bounded.
- Repeated Google SDK initialization no longer leaks `Bad state: init() has already been called` in Settings; verified at `C:\tmp\web-settings-sdk-fixed-mobile-final.png`. SDK initialization is coalesced application-wide and remains retryable after failure.
- Inbox empty state now matches the React Native `EmptyState` composition and copy; verified at `C:\tmp\web-inbox-empty-fixed-mobile-final.png`.
- Imperative Web navigation now reflects the pushed route in the browser URL. Search → Public Profile was verified at `C:\tmp\web-public-profile-url-reflection.png`, changing `#/search` to the matching `#/users/<id>` deep link.
- Production Recipe populated state is verified at `C:\tmp\web-recipe-production-mobile.png`, including media, ingredients, steps, author action, and refresh-safe author query.
- Production Comments surface is verified at `C:\tmp\web-comments-populated-mobile.png`; the list endpoint returns empty while the post summary reports 12 comments. The UI correctly renders the source empty/composer state, and the count/list mismatch is backend data evidence rather than a client fabrication target.
- Public Profile reports 88 followers and 24 following for the recipe author, while both production list contracts return empty. Follows renders the source empty states honestly; switching tabs now persists `tab=followers|following` in the refresh-safe URL, verified at `C:\tmp\web-follows-tab-url-fixed.png`.
- Premium Create is covered without mutating subscription/payment state: widget tests exercise 3-image → 1-video selection, controller tests verify the exact video publish/duration contract, and sticker selection/custom sticker coverage remains active.
- Chat production shell is verified at `C:\tmp\web-chat-production-shell.png`. A hard refresh now restores the participant name from the conversations contract without route `extra`, verified at `C:\tmp\web-chat-refresh-restored.png`.
- Authenticated mobile Lighthouse snapshot scored Accessibility 93 and Best Practices 100 (`C:\tmp\dailymeal-lighthouse\report.html`). The remaining accessibility failure is Flutter engine's generated zoom-lock viewport; overriding engine viewport behavior remains an explicit UX/accessibility decision rather than an unreviewed patch.
- Web QA follow-up: the Google Identity Services platform button is visually clipped inside the source-style circular social button. Localhost also reports the expected unapproved-origin GSI error and a production analytics-ingest 400; recheck both on the deployed Web origin.
- Android debug build passed with production API defines.
- Latest Web release build passed after the Settings regression fix. The standard JavaScript build is healthy; the Socket.IO dependency still emits the known Wasm dry-run compatibility warning.
- Full Flutter suite verified at 215 passing tests, including exact 28-route coverage, Web URL reflection, refresh-safe Chat/Follows routes, Premium Create media contracts, Settings regressions, social SDK lifecycle invariants, and Inbox empty-state parity.
- No-define debug APK built, installed and resumed `MainActivity` on `emulator-5554` without Flutter/configuration crashes.

## Next execution order

1. Run the 28-route user/admin identity audit and complete user-route Android/Web screenshot coverage.
2. Exercise populated Profile, Saved, Follows, Comments and Recipe states against production data.
3. Exercise Premium Create video/multi-image/sticker states on Android and Web.
4. Close remaining user accessibility, keyboard and media edge states.
5. Resume the deferred Admin visual/parity audit only after user evidence is complete.

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

Search post results now match React Native's vertical full-feed composition
instead of the earlier Flutter-only compact grid. Result cards preserve
like/save mutations and expose Comment, Recipe and author-profile navigation;
the people tab remains the source 50px relationship-card list.

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

Create Post now preserves the production capture-to-edit state transition
instead of opening the form immediately after selection. The compact source
header changes from `Thêm bài viết` to `Chỉnh bài viết`, selected media remains
in the capture preview until `Tiếp tục`, Free accounts expose camera-only input,
and Premium retains album/video actions. Existing multi-media, AI nutrition,
recipe, sticker and publish contracts remain intact.

The Create edit step now also uses the production AI hint panel and full-width
calorie action, source public/friends visibility segments, bordered content
surface and opt-in recipe switch. The non-source private dropdown and always-
expanded recipe editor have been removed from the user-facing flow while the
backend draft contract remains unchanged.

Premium Create now opens sticker selection as a dedicated `Nhãn dán` step,
keeps the media preview interactive, exposes none/server/custom choices plus
scale and rotation, and returns through `Hoàn tất`. A regression test verifies
the chosen sticker reaches the publish payload. Android debug and Web release
builds both pass; the Free camera-only capture state was visually verified on AVD.

Post Summary now uses the source four-part yellow segmented control and a
single-scroll two-column layout with the right column offset by 50px. Progress
uses the source compact comments/likes total pill instead of Material chips.
Both surfaces open the referenced post through the existing Home focus URL and
gracefully replace missing/failed media with branded placeholders.

Saved is no longer an alias that opens the full Profile screen on a selected
tab. `/profile/saved` now has its own source header, `Người dùng` action label,
bookmark empty state and staggered compact-post grid with Home focus routing.
Follows now uses the source black segmented control, full explanatory empty
states and yellow/ghost relationship actions while preserving refresh-safe
user URLs and follow mutations.

Home no longer exposes a beige broken-image placeholder when legacy production
media returns 404 or a post has no resolvable image. It now falls back to the
bundled source `home-food-main.png` artwork, preserving the production card
composition and avoiding technical error visuals; verified on authenticated AVD.
6. Run screen-by-screen Android/Web visual regression and accessibility/performance gates.

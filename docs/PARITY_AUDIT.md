# Daily Meal Flutter parity audit

Updated: 2026-07-12. Authorities, in order: production React Native source, production site, approved Figma, Flutter implementation.

## Route coverage

React Native registers 29 active routes in `client/src/navigation/AppNavigator.tsx`; Flutter currently exposes 28 URL routes in `lib/app/router/app_route.dart`.

| React Native route | Flutter mapping | Status | Priority |
|---|---|---|---|
| Login, AdminLogin, Onboarding, Home, Search, Create, Profile, PublicProfile | Equivalent named routes | Present | P0 |
| Inbox, Chat, EditProfile, Settings, ChangePassword, Notifications | Equivalent named routes | Present | P0/P1 |
| Saved, PostSummary, Blocked, Support, ShareAccount, PremiumBenefits, Progress | Equivalent feature route, sometimes shared surface | Present with composition differences | P1/P2 |
| AdminDashboard | `/admin` | Present | P0 |
| Follows | `/users/:id/follows?tab=` / `FollowsScreen` | Present and refresh-safe | P1 |
| Comments | `/posts/:id/comments` / `CommentsScreen` | Present; hero gracefully falls back after refresh | P0 |
| Recipe | `RecipeNutritionSheet` only | Missing full-screen route identity | P0 |
| AdminUsers | `/admin/users` / restored Admin destination | Present and refresh-safe | P0 |
| AdminUserDetail | `/admin/users/:id` / responsive detail workspace | Present and refresh-safe | P0 |

Additional routing gaps:

- Edit Post uses `/posts/edit` plus an in-memory `FeedPost`; Web refresh cannot restore it.
- Notification taps return to Home but do not focus the referenced post.
- Android does not yet expose the `dailymeal://` VIEW/BROWSABLE scheme.
- The production backend has no verified `GET /api/posts/:id`; refresh-safe Comments, Recipe, Edit Post and notification focus require a supported retrieval strategy rather than a path that only works with `extra`.

## UI priority matrix

| Surface | Current parity | Remaining highest-impact work |
|---|---|---|
| Home header/action bar | Close | Replace remaining Material center icons, badge geometry and motion |
| Home artwork | Close for one image | Dedicated 2/3/4-image spread, sticker placement, heart rain, expanded video |
| Search/Profile/Inbox compact shell | Improved | Common non-source bottom tab bar removed in F017 |
| Edit Profile | Feature-complete baseline | Refine TextField/segment/chip geometry and picker permission copy |
| Profile/Public Profile | Partial | Source header/menu/CTA geometry and dedicated public composition |
| Comments | Low | Full-screen hero, bubbles, time/reply/like metadata and source action bar |
| Recipe | Partial | Full-screen header/author footer and route identity |
| Create/Edit Post | Partial | Source capture states, preview deck and edit action sheet |
| Notifications/Chat/Settings | Partial | Replace Material ListTile/AppBar/Chip composition with source widgets/assets |
| Admin Dashboard/KPI/Analytics | Partial-high | Chart hierarchy and responsive density |
| Admin Posts/Payments/Reports/AI | Partial | Media previews, filters, charts and complete metadata |
| Admin Users/User Detail | Low | Analytics-rich list plus full responsive detail workspace |

## Evidence produced

- Home before: `C:\tmp\dailymeal-before-priority.png`
- Home action-bar after: `C:\tmp\dailymeal-home-actionbar-after2.png`
- Home artwork/overlay after: `C:\tmp\dailymeal-home-artwork-after.png`
- Android debug build passed with production API defines.
- Web release build passed with production API defines.
- Full Flutter suite last verified at 185 passing tests after F014/F015; targeted Home/responsive tests passed after F016/F017.

## Next execution order

1. Finish Home 2/3/4-image layouts and source SVG/motion.
2. Route and rebuild Comments/Recipe using a refresh-safe post retrieval contract.
3. Refine Profile/Public Profile and Edit Profile visual geometry.
4. Implement Admin Users and Admin User Detail as URL-addressable responsive screens.
5. Complete remaining P1 user surfaces and deep-link/notification focus.
6. Run screen-by-screen Android/Web visual regression and accessibility/performance gates.

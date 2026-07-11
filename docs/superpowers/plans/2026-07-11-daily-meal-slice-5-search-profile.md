# Daily Meal Slice 5 — Search, Profile and Social Safety Plan

**Goal:** Replace remaining user-navigation placeholders with production-backed
search, own/public profiles, follow graph, profile management and safety tools.

## Locked search contracts

- `GET /api/posts/search` accepts `q`, `maxCalories`, `saved`,
  `premiumSticker`, `personalized` and returns `{posts}` (max 50).
- `GET /api/users/search` accepts `q`, `personalized`, excludes self/blocked
  users and returns `{users}` (max 25 after ranking).
- Search runs both requests together, supports empty-query discovery, three
  original quick filters and post/people segments.
- User DTO includes relationship and viewer-interaction state; Flutter must not
  decode a public search result as a fully authenticated session user.

## Execution

1. Add typed `PublicUser`, search filters/API/repository/controller with 350 ms
   debounce, stale-response suppression and follow mutation rollback.
2. Build responsive Search screen with posts/people segments and connect the
   existing navigation shell.
3. Implement own/public profile data, posts/saved tabs, followers/following and
   public-profile routing.
4. Implement edit profile/avatar/cover, password/settings/saved/support/share,
   progress/streak and account safety actions (restrict/block/report).
5. Run full tests/analyzer/Android/Web builds and update parity evidence without
   claiming live share/permissions or production mutations from mocked tests.

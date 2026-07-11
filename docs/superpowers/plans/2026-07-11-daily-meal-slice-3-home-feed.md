# Daily Meal Slice 3 — Home Feed Implementation Plan

**Goal:** Replace the authenticated home placeholder with a production-backed,
responsive feed that preserves the original post/media/actions contract on
Android and Web.

## Contract locked from the production source

- `GET /api/posts/feed?page={n}&limit={n}` returns `{posts, page, limit}`.
- Default page size is 20; Flutter requests 20 and infers `hasMore` when the
  returned page contains fewer than 20 items.
- `POST /api/posts/:id/like` returns `{liked, stats}`.
- `POST /api/posts/:id/save` returns `{saved, stats}`.
- Post payload supports image/video media, multiple images, layout transforms,
  recipe/nutrition/sticker data, visibility, viewer state and timestamps.
- Relative media URLs resolve against the configured API origin.

## Task 1 — Typed post contract

Create immutable author/media/stats/viewer/post models and strict decoders.
Cover image, video, optional recipe/nutrition/sticker and malformed required
fields with unit tests.

## Task 2 — Feed data and state

Create `FeedApi`, `FeedRepository` and `FeedController`. Test exact query/body
contracts, initial load, pull-to-refresh, append/deduplication, terminal page,
optimistic like/save and rollback on failure.

## Task 3 — Responsive presentation

Create `HomeScreen`, `PostCard`, image carousel and video placeholder/lifecycle
boundary. Use compact bottom navigation and medium/expanded navigation rail via
the existing adaptive shell. Include loading, empty, retry, pagination and
accessible 48dp action targets.

## Task 4 — Integration and evidence

Wire `/` to the real home route, run focused/full tests, analyzer, Android debug
and Web release builds, then update the parity matrix and record Slice 3 evidence.

Comments/recipe detail navigation are explicit follow-on subflows in Slice 3;
their buttons must remain visible but must not be marked verified until their
dedicated journeys exist.

# Daily Meal Slice 4 — Create Post Implementation Plan

**Goal:** Deliver the original multi-step Android/Web post composer with real
media upload, optional AI nutrition analysis, recipe/sticker editing and exact
post creation payloads.

## Locked production contracts

- Multipart `POST /api/uploads?category=post` accepts exactly one `image` or
  `video` field and returns `{upload}`.
- Images are limited by backend upload policy; video upload requires Premium.
- `POST /api/meals/analyze` sends `{uploadId, hints?}` and returns `{meal}`.
- `GET /api/stickers`; Premium-only custom sticker `POST /api/stickers`.
- `POST /api/posts` uses the full server schema: media type, up to three images,
  optional video <=30 seconds, layout/transforms, caption <=2000, up to 20 tags,
  legacy/per-image recipes, nutrition summary/details, meal/sticker/placement
  and visibility.
- Free users may compose one image; Premium users may compose up to three
  images or one video, matching the original client behavior.

## Task 1 — Draft domain and exact API contracts

Model upload/meal/sticker/draft data and validation bounds. Add contract tests
for multipart upload, AI analysis, stickers and post serialization.

## Task 2 — Media capability adapters

Use `image_picker` for Android camera/gallery and Web file selection. Normalize
picked bytes/name/MIME without relying on mobile filesystem paths. Enforce
count/media/Premium/duration constraints before upload.

## Task 3 — Composer state machine

Implement capture → edit → sticker steps; upload progress, per-image AI
analysis/hints, recipe editing, transforms, sticker placement and publish retry.
Preserve the draft after recoverable failures.

## Task 4 — Responsive UI and navigation

Replace the Create navigation placeholder with a responsive Material 3 composer
for phone/tablet/Web, including camera/gallery permission errors, previews,
nutrition results and accessible controls.

## Task 5 — Verification

Run focused/full tests, analyzer, Android/Web builds, record manual capability
boundaries and update parity evidence. Real camera/gallery and provider AI
success require device/browser + production credentials and must not be claimed
from mocks alone.

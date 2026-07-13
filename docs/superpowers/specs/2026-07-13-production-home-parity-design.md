# Production Home Parity Design

## Objective

Port the production Daily Meal Home experience from
`D:\WW\Daily_Meal_App\daily_meal\client` to Flutter before auditing the
remaining user screens. Production code and runtime behavior are authoritative;
the supplied Figma file and screenshot are supporting references. Admin flows
are out of scope.

## Scope

This increment covers the Home feed and the user-facing surfaces opened
directly from a feed post:

- production-parity post artwork and controls;
- correct sticker source and placement;
- one-month Premium trial ticket and confirmation flow;
- calorie badge and detailed nutrition sheet;
- overlapping double-tap heart-rain bursts;
- navigation from an author chip to that user's public profile;
- regression coverage and AVD visual verification.

The later full-user audit remains part of the parent goal but will receive its
own design and implementation plan after Home parity is verified.

## Sources of Truth

Use the following priority when references disagree:

1. production behavior and code in `client/src/screens/HomeScreen.tsx`;
2. related production helpers and API contracts;
3. `https://dailymeal.site/` observed at the implementation date;
4. supplied screenshot and copied assets;
5. Figma, which reflects the initial rather than final production design.

The Flutter implementation must reuse existing domain models, repositories,
Riverpod controllers, and GoRouter routes. It must not duplicate API clients or
introduce a second navigation system.

## Component Design

### Sticker artwork

Create a focused sticker resolver/widget used by feed artwork and recipe
artwork. It resolves bundled keys (`custom-smile`, `openmoji-yum`,
`openmoji-cooking`, and `openmoji-noodles`), server URLs, and user-uploaded
paths. Unknown non-URI keys render nothing instead of a placeholder.

Render the sticker in a 78 by 78 logical-pixel absolute layer. Its default
placement is `{x: 0.78, y: 0.78, scale: 1, rotation: 0}`. Apply normalized
coordinates relative to the artwork, center translation, rotation, and scale.
The sticker remains above image/video content and below non-artwork overlays.
Feed code must stop substituting `openmoji-yum.png` for every sticker.

### Premium trial ticket

Show `assets/feed/Group.png` on the visible post only when onboarding is
complete, the authenticated user is not Premium, `premiumTrialUsed` is false,
and the offer has not been hidden during the current Home lifetime.

Tapping the ticket opens a centered modal with the production title, message,
three benefits, “Để sau”, and “Nâng Premium”. “Để sau” hides the offer for the
current Home lifetime. Backdrop dismissal closes the modal but leaves the
ticket visible. Accept calls the existing `claimTrial` controller operation,
publishes the returned authenticated user, hides the ticket on success, and
shows an error while keeping the offer retryable on failure. Repeated taps are
disabled while the request is in flight.

### Calories and nutrition detail

Select calories per artwork image from the corresponding
`nutritionDetails[index].total`. Use legacy `nutritionSummary` only for image
zero of a single-image post. Combined totals sum calories, protein,
carbohydrates, and fat and average available confidence values.

The feed badge is 172 logical pixels wide and at least 38 high. It is green
`#8BA58A` below 500 calories and red `#E65B55` at or above 500. Every two seconds
it alternates between “N Calo” and “chạm để xem calo”, with the production
subtle wobble. Motion is disabled when platform accessibility requests reduced
animations.

Tapping the badge opens a slide-up sheet capped at 86% of the viewport. The
sheet displays total calories, Protein/Carbs/Fat pills, per-image/per-item
nutrition, warnings, and AI insight states. For authenticated non-demo posts it
loads `GET /api/posts/:postId/nutrition-insight`. It provides loading, fallback,
error with retry, and unavailable states without discarding locally available
nutrition totals.

### Double-tap heart rain

Use a 300 ms double-tap threshold and cancel the pending single-tap artwork
action when a double tap wins. Double tap likes only an unliked post; it never
unlikes an already-liked post. Animation always plays.

Each double tap creates an independent burst so bursts can overlap. A burst has
15 non-interactive heart particles originating around artwork center at 50%
horizontal and 54% vertical. Each particle animates opacity, scale, rotation,
and an upward/outward translation for 760–1000 ms with a 0–145 ms delay and
cubic-out easing. Hearts are size 22; every third is pink `#FF7AA2`, with the
others red `#E65B55`. Reduced-motion mode replaces the rain with a short static
confirmation that does not continuously animate.

The bottom action heart keeps its separate production response: scale from 1
to 1.5 over 150 ms, then spring back.

### Public author profile navigation

Make the feed author chip interactive. A real post with an author ID pushes the
existing public profile route with that ID. Demo posts or posts without an
author ID fall back to the authenticated user's profile. The same rule applies
from expanded artwork/recipe surfaces. Returning preserves the current feed
page and post position.

### Home visual structure

Preserve the production vertical paged feed, maximum artwork width of 380, 3:4
artwork aspect ratio, centered phone-width layout on large viewports, “Bảng
tin” header, notification badge, profile entry, category drawer, and bottom
comment/like/save/create controls. Use the copied production assets and palette
(`canvas #F4F3EF`, `strong canvas #ECE9DF`, green `#8BA58A`, dark green
`#4F6F3D`, red `#E65B55`, yellow `#F6DE68`).

Existing pagination, socket stat merging, optimistic like/save rollback, video
visibility behavior, post deep links, comments, and recipe navigation must not
regress.

## Data and State Flow

`HomeScreen` continues to observe the feed controller and authenticated user.
Feed post models expose nutrition and sticker placement without presentation
fallbacks. Focused widgets receive immutable post/viewer state and callbacks;
network mutations remain in existing Riverpod controllers.

Trial flow is `ticket -> modal -> PremiumController.claimTrial -> repository ->
POST /api/users/me/premium-trial -> session user update`. Nutrition insight is
`calorie badge -> sheet -> nutrition controller/repository -> GET insight`,
while parsed post nutrition remains immediately visible. Author navigation is
`author chip -> GoRouter public-profile route(userId)`.

## Error Handling

- Broken or unknown sticker sources fail closed without breaking artwork.
- Trial failure retains eligibility and exposes a retryable Vietnamese error.
- Nutrition insight failure retains parsed totals and provides retry.
- Optimistic like/save behavior continues to roll back on API failure.
- Navigation ignores duplicate taps while a route transition is active.
- All asynchronous UI checks `mounted` before presenting follow-up state.

## Testing and Verification

Implementation follows red-green-refactor. Add focused widget/unit tests that
first fail for:

- bundled, remote, unknown, and transformed sticker rendering;
- exact trial eligibility, dismissal, successful claim, busy state, and retry;
- per-image nutrition selection, 500-calorie color boundary, badge tap, macro
  totals, insight loading/error/retry/fallback;
- a 15-particle burst, overlapping bursts, already-liked behavior, unliked
  like callback, and reduced motion;
- real-author public profile routing, fallback routing, and feed position
  preservation.

Run focused tests after each behavior, then the complete Flutter test suite and
`flutter analyze --no-pub`. Build and run on the configured AVD from
`D:\Android`; log in with the supplied test account only at runtime and never
store credentials in source, tests, logs, screenshots, or documentation.

Capture AVD screenshots for Home idle state, sticker placement, Premium ticket
and modal, nutrition sheet, heart rain, and public profile. Compare them against
production at the same viewport and record remaining measurable differences.
Home parity is accepted only when automated tests pass and the AVD flows work
with production data without material layout or interaction differences.

## Non-Goals

- Admin routes or admin UI.
- Redesigning production behavior based solely on Figma.
- Replacing existing repositories, router, or state management.
- Completing unrelated user screens in the same implementation plan.

# Production Home Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the production Daily Meal Home feed behavior to Flutter, including exact sticker placement, Premium trial entry, calorie detail, heart-rain interaction, and public-author navigation.

**Architecture:** Keep `HomeScreen` as the feed orchestrator and existing Riverpod controllers as mutation owners. Extract pure nutrition selection, sticker rendering, heart-rain, and trial presentation into focused widgets/services so each behavior can be tested independently and reused by recipe artwork without duplicating network or routing logic.

**Tech Stack:** Flutter/Dart, Riverpod, GoRouter, Dio, flutter_test, video_player, visibility_detector.

---

## File Structure

- Create `lib/features/feed/domain/feed_nutrition.dart`: pure per-image and combined nutrition calculations.
- Create `lib/features/feed/presentation/feed_sticker.dart`: bundled/remote sticker resolution and transformed artwork layer.
- Create `lib/features/feed/presentation/heart_rain.dart`: independent particle bursts and reduced-motion fallback.
- Create `lib/features/feed/data/nutrition_insight_api.dart`: exact production insight endpoint.
- Create `lib/features/feed/data/nutrition_insight_repository.dart`: testable insight boundary.
- Create `lib/features/feed/application/nutrition_insight_controller.dart`: sheet loading/retry state.
- Create `lib/features/feed/presentation/nutrition_detail_sheet.dart`: production calorie detail sheet.
- Create `lib/features/premium/presentation/premium_trial_offer.dart`: ticket and claim modal.
- Modify `lib/features/feed/domain/feed_post.dart`: retain sticker placement and parse insight models.
- Modify `lib/features/feed/presentation/post_media.dart`: expose artwork overlay and overlapping double-tap bursts.
- Modify `lib/features/feed/presentation/post_card.dart`: compose sticker, calorie badge, heart feedback, and author action.
- Modify `lib/features/feed/presentation/home_screen.dart`: trial eligibility, sheet opening, and public-profile routing.
- Modify `lib/features/feed/presentation/recipe_nutrition_sheet.dart`: reuse sticker and nutrition presentation.
- Add matching tests under `test/features/feed` and `test/features/premium`.

### Task 1: Preserve production sticker placement in the feed model

**Files:**
- Modify: `lib/features/feed/domain/feed_post.dart`
- Test: `test/features/feed/domain/feed_post_test.dart`

- [ ] **Step 1: Write the failing placement decode test**

Add a fixture assertion that expresses the required model API:

```dart
expect(post.stickerPlacement, isNotNull);
expect(post.stickerPlacement!.x, .31);
expect(post.stickerPlacement!.y, .72);
expect(post.stickerPlacement!.scale, 1.4);
expect(post.stickerPlacement!.rotation, -12);
```

Include `stickerPlacement: {'x': .31, 'y': .72, 'scale': 1.4, 'rotation': -12}` in the fixture.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/domain/feed_post_test.dart`

Expected: compilation failure because `FeedPost.stickerPlacement` does not exist.

- [ ] **Step 3: Add the immutable placement model and parser**

```dart
class FeedStickerPlacement {
  const FeedStickerPlacement({
    this.x = .78,
    this.y = .78,
    this.scale = 1,
    this.rotation = 0,
  });

  factory FeedStickerPlacement.fromJson(Map<String, dynamic> json) =>
      FeedStickerPlacement(
        x: _number(json['x'], fallback: .78),
        y: _number(json['y'], fallback: .78),
        scale: _number(json['scale'], fallback: 1),
        rotation: _number(json['rotation']),
      );

  final double x, y, scale, rotation;
}
```

Add `FeedStickerPlacement? stickerPlacement` to `FeedPost`, parse it when the JSON value is a map, and preserve it in `copyWith`.

- [ ] **Step 4: Verify GREEN and commit**

Run: `flutter test test/features/feed/domain/feed_post_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed/domain/feed_post.dart test/features/feed/domain/feed_post_test.dart && git commit -m "feat(feed): parse sticker placement"`

### Task 2: Render actual bundled and remote stickers with production transforms

**Files:**
- Create: `lib/features/feed/presentation/feed_sticker.dart`
- Create: `test/features/feed/presentation/feed_sticker_test.dart`
- Modify: `lib/features/feed/presentation/post_card.dart`
- Modify: `lib/features/feed/presentation/recipe_nutrition_sheet.dart`

- [ ] **Step 1: Write failing resolver and widget tests**

Use `FeedSticker` with `PostSticker(assetPath: 'openmoji-cooking', ...)` and assert `find.byKey(const Key('feed-sticker-image'))`. Add tests for an HTTPS asset, an unknown key rendering no image, and a placement of `.31/.72/1.4/-12` producing `Positioned` plus `Transform` widgets.

```dart
await tester.pumpWidget(MaterialApp(home: SizedBox(
  width: 300,
  height: 400,
  child: FeedSticker(
    sticker: sticker,
    placement: const FeedStickerPlacement(x: .31, y: .72, scale: 1.4, rotation: -12),
    resolver: MediaUrlResolver(baseUri: Uri.parse('https://api.dailymeal.site')),
  ),
)));
expect(find.byKey(const Key('feed-sticker-image')), findsOneWidget);
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/presentation/feed_sticker_test.dart`

Expected: FAIL because `FeedSticker` is undefined.

- [ ] **Step 3: Implement the resolver and transformed layer**

```dart
const bundledStickerAssets = <String, String>{
  'custom-smile': 'assets/stickers/custom-smile.png',
  'openmoji-yum': 'assets/stickers/openmoji-yum.png',
  'openmoji-cooking': 'assets/stickers/openmoji-cooking.png',
  'openmoji-noodles': 'assets/stickers/openmoji-noodles.png',
};
```

Normalize an optional filename extension before lookup. Use `Image.asset` for known keys, `Image.network` for resolved HTTP(S) URLs, and `SizedBox.shrink` otherwise. Place a 78x78 child at `x * width - 25`, `y * height - 25`, then apply radians rotation and scale. Give the image key `feed-sticker-image`.

- [ ] **Step 4: Replace hard-coded sticker rendering**

In `FeedPostCard`, replace the fixed `openmoji-yum.png` `Positioned` with `FeedSticker(sticker: post.sticker!, placement: post.stickerPlacement ?? const FeedStickerPlacement(), resolver: resolver)`. Reuse the same widget in recipe artwork.

- [ ] **Step 5: Verify and commit**

Run: `flutter test test/features/feed/presentation/feed_sticker_test.dart test/features/feed/presentation/recipe_nutrition_sheet_test.dart test/features/feed/presentation/home_screen_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed test/features/feed && git commit -m "feat(feed): render production stickers"`

### Task 3: Add pure per-image nutrition selection and totals

**Files:**
- Create: `lib/features/feed/domain/feed_nutrition.dart`
- Create: `test/features/feed/domain/feed_nutrition_test.dart`

- [ ] **Step 1: Write failing selection tests**

Cover these exact cases: detail index 1 wins for the second image; legacy summary applies only to image zero of a single-image post; legacy summary is ignored for multi-image posts; combined totals sum calories/protein/carbs/fat and average confidence.

```dart
expect(nutritionForImage(multiImagePost, 1)?.calories, 220);
expect(nutritionForImage(multiImagePost, 0), isNull);
expect(combineNutrition(multiImagePost.nutritionDetails).calories, 385);
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/domain/feed_nutrition_test.dart`

Expected: compilation failure because the helpers are absent.

- [ ] **Step 3: Implement pure helpers**

```dart
NutritionSummary? nutritionForImage(FeedPost post, int index) {
  if (index >= 0 && index < post.nutritionDetails.length) {
    return post.nutritionDetails[index].total;
  }
  if (index == 0 && post.images.length == 1) return post.nutritionSummary;
  return null;
}
```

Implement `combineNutrition` with `fold`, treating absent confidence separately so its average denominator includes only present values.

- [ ] **Step 4: Verify and commit**

Run: `flutter test test/features/feed/domain/feed_nutrition_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed/domain/feed_nutrition.dart test/features/feed/domain/feed_nutrition_test.dart && git commit -m "feat(feed): calculate per-image nutrition"`

### Task 4: Add the nutrition insight contract and retryable controller

**Files:**
- Create: `lib/features/feed/data/nutrition_insight_api.dart`
- Create: `lib/features/feed/data/nutrition_insight_repository.dart`
- Create: `lib/features/feed/application/nutrition_insight_controller.dart`
- Create: `test/features/feed/data/nutrition_insight_api_test.dart`
- Create: `test/features/feed/application/nutrition_insight_controller_test.dart`

- [ ] **Step 1: Write the failing API contract test**

Use the project's fake Dio adapter and assert exactly:

```dart
expect(request.method, 'GET');
expect(request.path, '/api/posts/post-1/nutrition-insight');
```

Return a fixture with `headline`, `verdict`, `suggestions`, `items`, `source`, and per-item macros, then assert typed decoding.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/data/nutrition_insight_api_test.dart`

Expected: FAIL because the API class/model is absent.

- [ ] **Step 3: Implement API and repository**

```dart
class NutritionInsightApi {
  NutritionInsightApi(this._client);
  final ApiClient _client;

  Future<NutritionInsight> load(String postId) async {
    final response = await _client.dio.get<Object?>(
      '/api/posts/$postId/nutrition-insight',
    );
    return NutritionInsight.fromJson(extractDataMap(response.data));
  }
}
```

Define only fields present in the production contract and a repository interface `Future<NutritionInsight> load(String postId)`.

- [ ] **Step 4: Write failing controller tests**

Assert initial loading, success, error preservation, and retry invoking the repository twice. The state API must expose `loading`, `insight`, and `errorMessage`.

- [ ] **Step 5: Implement controller and verify GREEN**

Use a `ChangeNotifier` controller with an idempotent `load()` and explicit `retry()` that clears only the previous error. Never erase post-local totals because those are supplied separately to presentation.

Run: `flutter test test/features/feed/data/nutrition_insight_api_test.dart test/features/feed/application/nutrition_insight_controller_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed test/features/feed && git commit -m "feat(feed): load nutrition insight"`

### Task 5: Build the production calorie badge and detail sheet

**Files:**
- Create: `lib/features/feed/presentation/nutrition_detail_sheet.dart`
- Create: `test/features/feed/presentation/nutrition_detail_sheet_test.dart`
- Modify: `lib/features/feed/presentation/post_card.dart`
- Modify: `lib/features/feed/presentation/home_screen.dart`

- [ ] **Step 1: Write failing badge boundary and sheet tests**

Assert key `calorie-badge-post-1`, `#8BA58A` at 499, `#E65B55` at 500, alternation to `chạm để xem calo` after two seconds, and no timer-driven motion under `MediaQuery(disableAnimations: true)`. Tap the badge and assert `Chi tiết calo`, total kcal, and Protein/Carbs/Fat labels.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/presentation/nutrition_detail_sheet_test.dart`

Expected: FAIL because the badge/sheet does not exist.

- [ ] **Step 3: Implement `CalorieBadge`**

Use a stateful two-second label timer, width 172, minimum height 38, threshold colors, white text, and a repeating production wobble only when animations are enabled. Cancel timer and animation controller in `dispose`.

- [ ] **Step 4: Implement `NutritionDetailSheet`**

Use `DraggableScrollableSheet`/modal constraints capped at `.86 * viewport`. Render local total and macro pills immediately, then an insight card with loading, source/fallback, error retry, headline/verdict, suitable/caution groups, suggestions, image, ingredient rows, and total row.

- [ ] **Step 5: Wire Home presentation**

Pass the selected per-image nutrition into the badge. On tap, construct the insight controller with the existing API client provider and open `showModalBottomSheet(isScrollControlled: true, ...)`. Demo or unauthenticated posts render local totals without issuing the insight request.

- [ ] **Step 6: Verify and commit**

Run: `flutter test test/features/feed/presentation/nutrition_detail_sheet_test.dart test/features/feed/presentation/home_screen_test.dart test/features/feed/presentation/recipe_nutrition_sheet_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed test/features/feed && git commit -m "feat(feed): show calorie detail"`

### Task 6: Replace the single-heart overlay with overlapping production rain

**Files:**
- Create: `lib/features/feed/presentation/heart_rain.dart`
- Create: `test/features/feed/presentation/heart_rain_test.dart`
- Modify: `lib/features/feed/presentation/post_media.dart`
- Modify: `test/features/feed/presentation/post_media_test.dart`

- [ ] **Step 1: Write failing particle and gesture tests**

Double-tap once and assert 15 widgets with keys beginning `heart-particle-`. Double-tap again before one second and assert 30. Assert an already-liked post invokes no like callback but still shows 15 hearts; an unliked post invokes exactly one callback. Under reduced motion assert `heart-rain-static` and no particle animations.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/presentation/heart_rain_test.dart test/features/feed/presentation/post_media_test.dart`

Expected: FAIL because the current overlay contains one icon.

- [ ] **Step 3: Implement independent bursts**

```dart
class HeartBurst {
  HeartBurst(this.id, this.startedAt);
  final int id;
  final DateTime startedAt;
}
```

`HeartRainController.addBurst()` appends rather than replaces a burst and removes it after 1145 ms. `HeartRain` deterministically creates 15 particle trajectories per burst, with durations 760–1000 ms, delays 0–145 ms, size 22, center `(50%,54%)`, cubic-out transforms, every third pink and the rest red. Use `IgnorePointer`.

- [ ] **Step 4: Wire double tap**

Replace `_showHeart` in `PostMedia` with burst state. Keep Flutter's 300 ms double-tap recognizer semantics, call like only when initially unliked, and always add a burst. Preserve the existing multi-image single-tap spread action.

- [ ] **Step 5: Verify and commit**

Run: `flutter test test/features/feed/presentation/heart_rain_test.dart test/features/feed/presentation/post_media_test.dart test/features/feed/presentation/home_screen_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed/presentation test/features/feed/presentation && git commit -m "feat(feed): add production heart rain"`

### Task 7: Add the Home Premium trial ticket and modal

**Files:**
- Create: `lib/features/premium/presentation/premium_trial_offer.dart`
- Create: `test/features/premium/presentation/premium_trial_offer_test.dart`
- Modify: `lib/features/feed/presentation/home_screen.dart`
- Modify: `test/features/feed/presentation/home_screen_test.dart`

- [ ] **Step 1: Write failing eligibility tests**

Assert the ticket exists only for an onboarded, non-Premium user with `premiumTrialUsed == false`. Assert it is absent for Premium, used-trial, and incomplete-onboarding users.

```dart
expect(find.byKey(const Key('premium-trial-ticket')), findsOneWidget);
```

- [ ] **Step 2: Write failing modal behavior tests**

Tap ticket; assert title `Nhận 1 tháng Premium miễn phí?`, three benefit rows, `Để sau`, and `Nâng Premium`. Verify backdrop close preserves the ticket, `Để sau` hides it for that Home lifetime, busy state prevents duplicate calls, success hides it and publishes the updated user, and error leaves it retryable.

- [ ] **Step 3: Verify RED**

Run: `flutter test test/features/premium/presentation/premium_trial_offer_test.dart test/features/feed/presentation/home_screen_test.dart`

Expected: FAIL because no Home ticket exists.

- [ ] **Step 4: Implement the offer widget**

Create `PremiumTrialOffer` with `eligible`, `busy`, `onClaim`, and `onUserUpdated`. Render `assets/feed/Group.png`; use a max-width 360, radius 28 white modal, `Colors.black45` backdrop, green primary action, and local dismissal state matching the spec.

- [ ] **Step 5: Connect the existing Premium controller**

Home obtains the authenticated user and constructs/reads the existing premium controller provider. `onClaim` awaits `claimTrial`; its existing `onUserUpdated` path updates the auth controller. Present Vietnamese success/error snackbars and guard callbacks with `mounted`.

- [ ] **Step 6: Verify and commit**

Run: `flutter test test/features/premium/presentation/premium_trial_offer_test.dart test/features/premium/application/premium_controller_test.dart test/features/feed/presentation/home_screen_test.dart`

Expected: PASS.

Commit: `git add lib/features/premium lib/features/feed/presentation/home_screen.dart test/features/premium test/features/feed/presentation/home_screen_test.dart && git commit -m "feat(home): add Premium trial offer"`

### Task 8: Route Home author chips to public profiles and preserve feed state

**Files:**
- Modify: `lib/features/feed/presentation/home_screen.dart`
- Modify: `test/features/feed/presentation/home_screen_test.dart`
- Modify: `test/app/router/app_router_test.dart`

- [ ] **Step 1: Write failing route tests**

Pump Home under a test GoRouter. Tap the author chip for a real post and assert location `/users/author-1`. For a post with an empty author ID, assert `/profile`. Navigate back and assert the same feed post key remains visible.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/presentation/home_screen_test.dart`

Expected: FAIL because Home does not pass `onAuthor`.

- [ ] **Step 3: Wire the route callback**

```dart
onAuthor: () {
  final id = post.author.id.trim();
  if (id.isEmpty || post.id.startsWith('demo-post-')) {
    context.pushNamed(AppRoute.profile.name);
  } else {
    context.pushNamed(
      AppRoute.publicProfile.name,
      pathParameters: {'id': id},
    );
  }
},
```

The `demo-post-` predicate matches the production sample data contract in
`client/src/data/sample.ts`. Do not infer demo state from a display name. Keep
Home alive by using push rather than replace/go.

- [ ] **Step 4: Verify and commit**

Run: `flutter test test/features/feed/presentation/home_screen_test.dart test/features/profile/presentation/profile_screen_test.dart test/app/router/app_route_coverage_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed/presentation/home_screen.dart test/features/feed/presentation/home_screen_test.dart test/app/router && git commit -m "feat(home): open public author profiles"`

### Task 9: Match production Home layout and protect existing feed behaviors

**Files:**
- Modify: `lib/features/feed/presentation/home_screen.dart`
- Modify: `lib/features/feed/presentation/post_card.dart`
- Modify: `test/features/feed/presentation/home_screen_test.dart`

- [ ] **Step 1: Add failing layout assertions**

At phone and desktop test sizes assert: maximum artwork width 380, aspect ratio 3:4 (height/width), centered max-width 430 Home, header label `Bảng tin`, and presence of notification/profile/category/comment/like/save/create controls. Add regression assertions for pagination trigger, initial-post deep link, recipe/comments navigation, and optimistic busy states.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/features/feed/presentation/home_screen_test.dart`

Expected: at least the artwork geometry assertions fail against the current layout.

- [ ] **Step 3: Apply production geometry and palette**

Use `ConstrainedBox(maxWidth: 430)` for the screen and `ConstrainedBox(maxWidth: 380)` plus `AspectRatio(aspectRatio: 3 / 4)` for artwork. Preserve vertical `PageView` paging and existing lazy load threshold. Use existing `AppColors` values or update only mismatched Home tokens to the exact production palette.

- [ ] **Step 4: Verify and commit**

Run: `flutter test test/features/feed/presentation/home_screen_test.dart test/features/feed/application/feed_controller_test.dart test/features/feed/data/feed_repository_test.dart`

Expected: PASS.

Commit: `git add lib/features/feed/presentation test/features/feed/presentation && git commit -m "fix(home): match production feed layout"`

### Task 10: Full verification and AVD parity evidence

**Files:**
- Create: `docs/qa/2026-07-13-production-home-parity.md`
- Modify tests only if a real uncovered regression is first reproduced by a failing test.

- [ ] **Step 1: Run static and automated verification**

Run:

```powershell
flutter analyze --no-pub
flutter test
```

Expected: both exit 0 with no analyzer errors and all tests passing.

- [ ] **Step 2: Build and launch on the configured Android toolchain**

Set `ANDROID_HOME`/`ANDROID_SDK_ROOT` to the detected SDK under `D:\Android`, run `flutter doctor -v`, list devices with `flutter devices`, start the available AVD if necessary, and run:

```powershell
flutter run -d <avd-device-id> --debug
```

Expected: app installs and reaches the login/Home flow without runtime exceptions.

- [ ] **Step 3: Verify production-data flows manually**

Log in using the supplied account without writing credentials to disk or command history. Verify and capture: Home idle, actual sticker and transform, eligible/ineligible trial behavior, calorie sheet and retry, two overlapping heart bursts, public profile navigation/back preservation, comments, recipe, pagination, like/save rollback-visible behavior, and video play/mute.

- [ ] **Step 4: Record parity evidence**

Write `docs/qa/2026-07-13-production-home-parity.md` with device/viewport, commit SHA, commands/results, screenshot paths, each requirement's production reference and AVD observation, and any measurable remaining delta. Do not claim parity while a material delta remains.

- [ ] **Step 5: Commit verification evidence**

Commit: `git add -f docs/qa/2026-07-13-production-home-parity.md && git commit -m "test(home): record production parity evidence"`

## Plan Self-Review

- Every Home requirement in the approved spec maps to at least one task.
- Existing pagination, realtime, video, deep-link, comments, recipe, and optimistic interaction behavior is covered by regression verification.
- New behavior follows test-first red-green-refactor and does not require admin changes.
- Credentials are runtime-only and excluded from source, logs, docs, and screenshots.
- Full-user parity remains explicitly scheduled after this independently testable Home increment.

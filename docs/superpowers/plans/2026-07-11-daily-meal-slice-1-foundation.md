# Daily Meal Slice 1 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken Flutter counter scaffold with a tested Android/Web foundation that validates production configuration, provides Daily Meal theming/responsiveness, typed networking/errors, session storage, routing shells, reusable async-state widgets and privacy-safe analytics.

**Architecture:** Build small platform-independent primitives first and inject platform services through Riverpod. Keep feature routes as typed shells in Slice 1; real authentication and product screens begin in Slice 2. REST DTOs remain feature-owned while the core client owns transport, authorization, errors and URL resolution.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Material 3, Riverpod, GoRouter, Dio, Freezed/json_serializable, flutter_secure_storage, shared_preferences, Work Sans and flutter_test.

---

## File Structure

Create or modify these focused units:

- `lib/main.dart`: production entry only
- `lib/app/bootstrap.dart`: provider container/bootstrap boundary
- `lib/app/app.dart`: `MaterialApp.router`
- `lib/app/config/app_config.dart`: validated dart defines
- `lib/app/config/config_exception.dart`: configuration failure type
- `lib/app/theme/app_colors.dart`: brand tokens
- `lib/app/theme/app_theme.dart`: Material 3 theme
- `lib/app/router/app_router.dart`: GoRouter and redirect policy
- `lib/app/router/app_route.dart`: route names/paths
- `lib/core/errors/app_failure.dart`: transport/domain-safe failure representation
- `lib/core/network/api_client.dart`: Dio construction/interceptors
- `lib/core/network/api_exception_mapper.dart`: Dio/server error mapping
- `lib/core/network/media_url_resolver.dart`: absolute/relative URL logic
- `lib/core/storage/session_store.dart`: session interface
- `lib/core/storage/secure_session_store.dart`: Android secure storage
- `lib/core/storage/web_session_store.dart`: explicit Web-compatible storage adapter
- `lib/core/responsive/app_breakpoints.dart`: breakpoint policy
- `lib/core/responsive/adaptive_scaffold.dart`: phone/rail/wide shell
- `lib/core/widgets/async_content.dart`: loading/empty/error/retry rendering
- `lib/core/analytics/analytics_event.dart`: allow-listed event model
- `lib/core/analytics/analytics_sanitizer.dart`: privacy filtering
- `test/`: matching unit/widget tests

Do not create feature DTOs or real auth screens in this slice.

### Task 1: Repair the Scaffold with a Red Bootstrap Test

**Files:**
- Modify: `pubspec.yaml`
- Replace: `lib/main.dart`
- Replace: `test/widget_test.dart`
- Create: `lib/app/app.dart`

- [ ] **Step 1: Write the failing app smoke test**

Replace the stale package import and assert a stable root semantic:

```dart
import 'package:daily_meal_flutter_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots the Daily Meal application', (tester) async {
    await tester.pumpWidget(const DailyMealApp());
    expect(find.bySemanticsLabel('Daily Meal application'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test and verify the intended failure**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because `lib/app/app.dart` and `DailyMealApp` do not exist.

- [ ] **Step 3: Add only the minimal app root and dependencies needed by subsequent tasks**

Add current SDK-compatible versions of `flutter_riverpod`, `go_router`, `dio`, `freezed_annotation`, `json_annotation`, `flutter_secure_storage`, `shared_preferences`, `flutter_svg`, plus generator dev dependencies after verifying with official pub.dev package pages and `flutter pub outdated`.

Create a minimal `DailyMealApp` whose root has `Semantics(label: 'Daily Meal application', container: true, child: MaterialApp(...))`. Replace `main.dart` with `runApp(const DailyMealApp())`.

- [ ] **Step 4: Verify the repaired baseline**

Run:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test test/widget_test.dart
```

Expected: all commands exit 0.

- [ ] **Step 5: Commit only bootstrap/dependency files**

```powershell
git add pubspec.yaml pubspec.lock lib/main.dart lib/app/app.dart test/widget_test.dart
git commit -m "feat: establish Flutter application bootstrap"
```

### Task 2: Add Validated Production Configuration

**Files:**
- Create: `lib/app/config/app_config.dart`
- Create: `lib/app/config/config_exception.dart`
- Create: `test/app/config/app_config_test.dart`

- [ ] **Step 1: Write failing validation tests**

Cover: HTTPS production URL accepted; missing API URL rejected outside tests; malformed URL rejected; Facebook/Google identifiers retained; trailing slash normalized once.

Use an injectable factory rather than directly testing compile-time environment:

```dart
final config = AppConfig.fromMap({
  'API_BASE_URL': 'https://api.dailymeal.site/',
  'FACEBOOK_APP_ID': '3483710358450589',
  'GOOGLE_WEB_CLIENT_ID': '20654020356-example.apps.googleusercontent.com',
});
expect(config.apiBaseUrl.toString(), 'https://api.dailymeal.site');
```

- [ ] **Step 2: Verify tests fail because the config types are absent**

Run: `flutter test test/app/config/app_config_test.dart`

- [ ] **Step 3: Implement immutable configuration**

`AppConfig.fromEnvironment()` reads the three exact `String.fromEnvironment` keys. `fromMap` validates URI scheme/host and normalizes the base URL without silently supplying production values in debug/test code.

- [ ] **Step 4: Run config and full tests**

Run: `flutter test test/app/config/app_config_test.dart && flutter test`

Expected: exit 0.

- [ ] **Step 5: Commit configuration**

```powershell
git add lib/app/config test/app/config
git commit -m "feat: validate Daily Meal runtime configuration"
```

### Task 3: Implement Brand Theme and Responsive Breakpoints

**Files:**
- Create: `lib/app/theme/app_colors.dart`
- Create: `lib/app/theme/app_theme.dart`
- Create: `lib/core/responsive/app_breakpoints.dart`
- Create: `test/app/theme/app_theme_test.dart`
- Create: `test/core/responsive/app_breakpoints_test.dart`

- [ ] **Step 1: Write failing token and breakpoint tests**

Assert all approved colors exactly and classify widths as compact `<600`, medium `600..<1024`, expanded `>=1024`.

- [ ] **Step 2: Run focused tests and observe missing types**

Run: `flutter test test/app/theme test/core/responsive`

- [ ] **Step 3: Implement const tokens and Material 3 theme**

Set `useMaterial3: true`, Work Sans typography, 48dp minimum interactive dimension guidance, visible focus/hover states and canvas `#F4F3EF`. Do not add dark mode because the source product is explicitly light-only.

- [ ] **Step 4: Verify focused/full tests and analyzer**

Run: `dart format lib test; flutter analyze; flutter test`

- [ ] **Step 5: Commit theme/responsive tokens**

```powershell
git add lib/app/theme lib/core/responsive/app_breakpoints.dart test/app/theme test/core/responsive
git commit -m "feat: add Daily Meal theme and breakpoints"
```

### Task 4: Add Failure Types and Media URL Resolution

**Files:**
- Create: `lib/core/errors/app_failure.dart`
- Create: `lib/core/network/media_url_resolver.dart`
- Create: `test/core/network/media_url_resolver_test.dart`

- [ ] **Step 1: Write failing URL cases**

Cover `/uploads/a.jpg`, `uploads/a.jpg`, absolute HTTPS URLs, empty strings and a base URL with/without trailing slash. Ensure absolute URLs are never double-prefixed.

- [ ] **Step 2: Run the failing test**

Run: `flutter test test/core/network/media_url_resolver_test.dart`

- [ ] **Step 3: Implement sealed failures and pure URL resolver**

Failures distinguish unauthorized, forbidden, validation, notFound, conflict, timeout, network, server and unknown with safe user-facing Vietnamese messages and optional status/code—not raw sensitive bodies.

- [ ] **Step 4: Verify**

Run: `flutter test test/core/network/media_url_resolver_test.dart; flutter analyze`

- [ ] **Step 5: Commit**

```powershell
git add lib/core/errors lib/core/network/media_url_resolver.dart test/core/network
git commit -m "feat: define failures and media URL resolution"
```

### Task 5: Build the Typed Dio Transport Boundary

**Files:**
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/network/api_exception_mapper.dart`
- Create: `lib/core/network/auth_token_provider.dart`
- Create: `test/core/network/api_client_test.dart`
- Create: `test/core/network/api_exception_mapper_test.dart`

- [ ] **Step 1: Write failing transport tests with a fake adapter**

Assert base URL, JSON headers, bearer injection, no Authorization header without a token, timeout mapping, backend message mapping, and a callback on 401. Assert request/log output redacts authorization/password/otp.

- [ ] **Step 2: Run tests and verify missing implementation failure**

Run: `flutter test test/core/network/api_client_test.dart test/core/network/api_exception_mapper_test.dart`

- [ ] **Step 3: Implement transport only**

Use one Dio instance, injected token provider and unauthorized callback. Configure connect/send/receive timeouts. Do not implement refresh tokens or automatic mutation retries.

- [ ] **Step 4: Verify**

Run: `dart format lib test; flutter analyze; flutter test`

- [ ] **Step 5: Commit**

```powershell
git add lib/core/network test/core/network
git commit -m "feat: add authenticated API transport"
```

### Task 6: Add Platform-Aware Session Storage

**Files:**
- Create: `lib/core/storage/session.dart`
- Create: `lib/core/storage/session_store.dart`
- Create: `lib/core/storage/secure_session_store.dart`
- Create: `lib/core/storage/web_session_store.dart`
- Create: `lib/core/storage/session_store_provider.dart`
- Create: `test/core/storage/session_store_contract_test.dart`

- [ ] **Step 1: Write a shared contract test**

For each in-memory-backed test adapter, verify save/read/replace/clear and separation of user/admin sessions. Assert logs/string representations never expose tokens.

- [ ] **Step 2: Run and verify failure**

Run: `flutter test test/core/storage/session_store_contract_test.dart`

- [ ] **Step 3: Implement adapters and conditional provider**

Android uses `flutter_secure_storage`. Web uses an explicit adapter compatible with the current bearer-token backend; document that browser JavaScript compromise can access client-managed bearer storage and avoid describing it as equivalent to HttpOnly cookies.

- [ ] **Step 4: Verify tests/analyzer**

Run: `flutter test test/core/storage; flutter analyze`

- [ ] **Step 5: Commit**

```powershell
git add lib/core/storage test/core/storage
git commit -m "feat: add platform session storage"
```

### Task 7: Add Router Guards and Adaptive Shell

**Files:**
- Create: `lib/app/router/app_route.dart`
- Create: `lib/app/router/app_router.dart`
- Create: `lib/app/router/session_route_state.dart`
- Create: `lib/core/responsive/adaptive_scaffold.dart`
- Modify: `lib/app/app.dart`
- Create: `test/app/router/app_router_test.dart`
- Create: `test/core/responsive/adaptive_scaffold_test.dart`

- [ ] **Step 1: Write failing redirect matrix tests**

Cover loading, signed-out, signed-in/not-onboarded, signed-in/onboarded and admin states. User and admin sessions must never enter each other's protected branches.

- [ ] **Step 2: Write failing viewport tests**

At 360px expect bottom navigation; at 600px expect rail/drawer behavior; at 1440px expect bounded content/admin sidebar shell.

- [ ] **Step 3: Implement router/shell with non-product placeholders**

Use clearly named internal `FoundationRouteProbe` widgets only in Slice 1 tests. Do not present them as completed product screens or add them to the parity matrix as verified features.

- [ ] **Step 4: Verify route and viewport tests**

Run: `flutter test test/app/router test/core/responsive; flutter analyze`

- [ ] **Step 5: Commit**

```powershell
git add lib/app/router lib/core/responsive lib/app/app.dart test/app/router test/core/responsive
git commit -m "feat: add guarded adaptive application shell"
```

### Task 8: Add Reusable Async-State Surfaces

**Files:**
- Create: `lib/core/widgets/async_content.dart`
- Create: `lib/core/widgets/app_loading_view.dart`
- Create: `lib/core/widgets/app_empty_view.dart`
- Create: `lib/core/widgets/app_error_view.dart`
- Create: `test/core/widgets/async_content_test.dart`

- [ ] **Step 1: Write widget tests for loading/data/empty/error/retry**

Verify retry callback, Vietnamese semantic labels, 48dp retry target and no simultaneous loading/error rendering.

- [ ] **Step 2: Run failing test**

Run: `flutter test test/core/widgets/async_content_test.dart`

- [ ] **Step 3: Implement composable state views**

Keep feature copy injectable; core widgets provide layout, semantics and actions only.

- [ ] **Step 4: Verify**

Run: `flutter test test/core/widgets; flutter analyze`

- [ ] **Step 5: Commit**

```powershell
git add lib/core/widgets test/core/widgets
git commit -m "feat: add accessible asynchronous state views"
```

### Task 9: Add Privacy-Safe Analytics Primitives

**Files:**
- Create: `lib/core/analytics/analytics_event.dart`
- Create: `lib/core/analytics/analytics_sanitizer.dart`
- Create: `lib/core/analytics/analytics_client.dart`
- Create: `test/core/analytics/analytics_sanitizer_test.dart`

- [ ] **Step 1: Write failing redaction/allow-list tests**

Reject/remove keys matching password, otp, token, authorization, message body and unknown nested sensitive values. Preserve approved screen/referrer/duration/status metadata.

- [ ] **Step 2: Verify failure**

Run: `flutter test test/core/analytics/analytics_sanitizer_test.dart`

- [ ] **Step 3: Implement sanitizer and injectable client**

The client may queue events but must not start production batching until the server analytics payload is implemented from `client/src/services/analytics.ts` in a dedicated follow-up task.

- [ ] **Step 4: Verify all quality gates for Slice 1**

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=https://api.dailymeal.site --dart-define=FACEBOOK_APP_ID=3483710358450589 --dart-define=GOOGLE_WEB_CLIENT_ID=20654020356-nsqam5ladrg7j5v6agefq8pucnrcqtn8.apps.googleusercontent.com
flutter build web --release --dart-define=API_BASE_URL=https://api.dailymeal.site --dart-define=FACEBOOK_APP_ID=3483710358450589 --dart-define=GOOGLE_WEB_CLIENT_ID=20654020356-nsqam5ladrg7j5v6agefq8pucnrcqtn8.apps.googleusercontent.com
```

Expected: all commands exit 0. Record artifact paths and any environment-only limitation with the original exit code/output.

- [ ] **Step 5: Update parity evidence and commit**

Update Slice 1 rows in `docs/parity/feature-parity-matrix.md` only where tests/build evidence supports `Verified`.

```powershell
git add lib/core/analytics test/core/analytics docs/parity/feature-parity-matrix.md
git commit -m "feat: complete Flutter foundation slice"
```

## Slice 1 Completion Review

- Re-run every command in Task 9 immediately before completion claims.
- Search `lib`, `test` and Slice 1 docs for `TODO`, `FIXME`, stale counter code and long-lived mock data.
- Confirm user-owned untracked scaffold/config files were not accidentally staged.
- Confirm no feature row beyond Slice 1 was marked verified.
- Link fresh command output in the parity matrix or a Slice 1 verification report.

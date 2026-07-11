# Daily Meal Slice 2 Auth and Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement production-backed user/admin authentication, phone and password-reset OTP flows, Google/Facebook token exchange, session restoration/logout, and two-step onboarding for Android and Web.

**Architecture:** Keep platform OAuth acquisition behind interfaces; the auth repository owns REST and DTO decoding, while an `AuthController` owns user/admin session state and route decisions. Screens consume immutable controller state through Riverpod and never call Dio or storage directly.

**Tech Stack:** Riverpod, Dio, GoRouter, flutter_secure_storage/shared_preferences adapters from Slice 1, Google Sign-In/Web OAuth adapters, Flutter widget/integration tests.

---

### Task 1: User DTOs and Validation

**Files:**
- Create: `lib/features/auth/domain/app_user.dart`
- Create: `lib/features/auth/domain/auth_result.dart`
- Create: `lib/features/auth/domain/auth_validation.dart`
- Test: `test/features/auth/domain/app_user_test.dart`
- Test: `test/features/auth/domain/auth_validation_test.dart`

- [ ] Write failing tests using sanitized server-shaped fixtures for optional email/phone/birthday, preferences, premium dates and counts.
- [ ] Write failing validation tests for email, phone presence, six-digit OTP, six-character auth password and eight-character reset password.
- [ ] Run focused tests and confirm missing implementation failures.
- [ ] Implement immutable types/validation without inventing server fields.
- [ ] Run focused/full tests and commit `feat: model Daily Meal authentication`.

### Task 2: Auth API and Repository

**Files:**
- Create: `lib/features/auth/data/auth_api.dart`
- Create: `lib/features/auth/data/auth_repository.dart`
- Test: `test/features/auth/data/auth_api_test.dart`
- Test: `test/features/auth/data/auth_repository_test.dart`

- [ ] Test every auth path/body/envelope from `docs/parity/api-contract.md` with a recording Dio adapter.
- [ ] Test that successful user/admin results replace the opposite session kind and that failed calls do not persist tokens.
- [ ] Implement register/login/phone/OTP/reset/Facebook/Google/link/me/admin/password methods.
- [ ] Map Dio failures through `ApiExceptionMapper`; never expose raw tokens in diagnostics.
- [ ] Run focused/full tests and commit `feat: connect authentication API`.

### Task 3: Session Restoration and Auth Controller

**Files:**
- Create: `lib/features/auth/application/auth_state.dart`
- Create: `lib/features/auth/application/auth_controller.dart`
- Create: `lib/features/auth/application/auth_providers.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/auth/application/auth_controller_test.dart`

- [ ] Test restoration priority: valid admin → admin; invalid admin clears it then attempts valid user; invalid user clears session; no tokens → signed out.
- [ ] Test user route state from `completedOnboarding`, admin/user mutual exclusion and logout clearing both.
- [ ] Implement Riverpod controller and connect route refresh to real state instead of the foundation probe notifier.
- [ ] Run tests/analyzer and commit `feat: restore authenticated sessions`.

### Task 4: Email Login/Register and Password Reset UI

**Files:**
- Create: `lib/features/auth/presentation/login_screen.dart`
- Create: `lib/features/auth/presentation/password_reset_sheet.dart`
- Create: `lib/features/auth/presentation/auth_form_state.dart`
- Test: `test/features/auth/presentation/login_screen_test.dart`
- Test: `test/features/auth/presentation/password_reset_sheet_test.dart`

- [ ] Test login/register mode, email validation, loading lock, accessible errors and successful route transition.
- [ ] Test request OTP → verify six digits/new password → authenticated state.
- [ ] Implement responsive Material 3 UI using original Vietnamese content/brand hierarchy.
- [ ] Run widget/full tests and commit `feat: add email authentication UI`.

### Task 5: Phone OTP UI

**Files:**
- Create: `lib/features/auth/presentation/phone_auth_form.dart`
- Test: `test/features/auth/presentation/phone_auth_form_test.dart`

- [ ] Test request code, `requiresPasswordSetup`, OTP input, first-time password/display name and existing phone-password login.
- [ ] Do not display `devOtp` in production builds; allow it only under an explicit debug flag.
- [ ] Implement and verify Android/Web keyboard/focus behavior.
- [ ] Commit `feat: add phone OTP authentication`.

### Task 6: Onboarding

**Files:**
- Create: `lib/features/onboarding/domain/preference_options.dart`
- Create: `lib/features/onboarding/data/onboarding_repository.dart`
- Create: `lib/features/onboarding/application/onboarding_controller.dart`
- Create: `lib/features/onboarding/presentation/onboarding_screen.dart`
- Test: matching domain/data/controller/widget tests

- [ ] Test exact Vietnamese options, toggle behavior, max 10, interests → eating step and persisted completion.
- [ ] Implement PATCH `/api/onboarding/preferences`, update user state and route to home.
- [ ] Verify compact/medium/expanded layout and commit `feat: add personalized onboarding`.

### Task 7: Google and Facebook Platform Adapters

**Files:**
- Create: `lib/features/auth/platform/social_identity_provider.dart`
- Create: conditional Android/Web Google adapters
- Create: conditional Android/Web Facebook adapters
- Test: `test/features/auth/platform/social_identity_provider_test.dart`

- [ ] Test cancel, missing configuration/token, timeout and provider error mapping without real credentials.
- [ ] Implement platform token acquisition using current official packages/docs, then exchange tokens only through backend endpoints.
- [ ] Preserve Google 409 link-required message and account-link action.
- [ ] Verify supported platform builds and commit `feat: add social authentication`.

### Task 8: Slice Verification and Parity Evidence

**Files:**
- Modify: `docs/parity/feature-parity-matrix.md`
- Create: `docs/parity/verification-slice-2.md`
- Create: `integration_test/auth_onboarding_test.dart`

- [ ] Cover restore → route, email login/onboarding, phone OTP and admin login using a deterministic test backend/fake transport at the boundary.
- [ ] Run format, analyze, full tests, Android release-compatible build and Web release build with production defines.
- [ ] Record manual credential-dependent Google/Facebook evidence separately; do not claim verified without it.
- [ ] Update only proven parity rows and commit `feat: complete authentication slice`.

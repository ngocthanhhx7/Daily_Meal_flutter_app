# Verification — Slice 9 User utilities

## Implemented

- Responsive Settings hub reachable from the owner profile.
- Dedicated Saved route that opens the existing saved-post tab.
- Authenticated password change with 6/8-character and confirmation validation.
- Google account linking through the existing platform SDK token stream and
  `POST /api/auth/google/link`.
- Post Summary filters (`all`, `friends`, `following`, `strangers`) with
  30-item paging and ID deduplication.
- Progress totals and grid sourced from the authenticated owner's posts.
- Support and family-share screens preserve the production React Native
  behavior: no message/code is claimed to be sent while no backend contract
  exists.

## Automated evidence

- Exact password, Google-link, Post Summary and owner-post API tests.
- Controller tests for password validation, filtered paging/dedup and progress.
- Widget tests for password validation and honest Support behavior.
- `flutter analyze --no-pub`: no issues.
- `flutter test test/features/user_utility`: 8 passed.
- Full `flutter test`: 153 passed.
- Web release and Android debug APK builds: passed.
- Optional Wasm dry run retains the known `socket_io_common` warning; the
  production JavaScript Web artifact is unaffected.

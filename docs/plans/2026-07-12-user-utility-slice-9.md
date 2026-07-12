# Slice 9 — User settings and utility parity

## Contracts

- `PATCH /api/auth/password` for authenticated password changes.
- `GET /api/posts/summary?filter&page&limit` for filtered post summary.
- Progress uses the existing authenticated user-post contract.
- Saved uses the existing profile saved-post contract.
- Support and family sharing deliberately remain informational because the
  production backend exposes no submission/invite contract.

## Screens

Settings, Change Password, Post Summary, Progress, Support and Share Account,
all responsive and reachable from the owner profile.

## Verification

Exact API tests, validation/controller tests, responsive widget journeys,
full analyze/test and Android/Web builds.

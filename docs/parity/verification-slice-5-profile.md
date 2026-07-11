# Slice 5 Profile Verification

Date: 2026-07-11

## Verified scope

- Own profile loads `GET /api/users/:id`, posts and saved posts concurrently.
- Public profile uses a parameterized `/users/:id` route and does not request
  private saved posts.
- Responsive profile header renders cover, avatar, biography, counts, post grid
  and owner-only saved tab.
- Followers and following use their exact list endpoints and link onward to
  public profiles.
- Follow/unfollow is optimistic and restores the previous relationship after a
  failed request.
- Owner display name and biography edits validate locally and persist through
  `PATCH /api/users/me`.
- Avatar and cover actions use the shared Android/Web image picker validation,
  upload multipart field `image` with `category=avatar|cover`, then persist the
  returned URL through `PATCH /api/users/me`.
- Public-profile safety actions confirm restrict, block and report mutations;
  failed requests restore viewer-interaction state. The blocked-account route
  loads `/api/users/me/interactions/blocked` and supports optimistic unblock.

## Automated evidence

- Profile API contract tests cover profile, posts, saved posts, follow lists and
  update method/body.
- Controller tests cover owner loading, update state and follow rollback.
- Compact public-profile journey covers content, follow and follower sheet.
- Owner widget journey covers the edit dialog and server-backed UI refresh.

## Remaining scope

Birthday/theme settings, password/settings, progress/streak and account utility
screens remain tracked independently. This document does not claim those
capabilities complete.

# Daily Meal Slice 7 — Premium and PayOS Plan

## Locked contracts

- Public plans: `GET /api/payments/premium/plans` with three wire IDs:
  `premium_month`, `premium_quarter`, `premium_half`.
- One-time trial: `POST /api/users/me/premium-trial`; server is the sole source
  of truth for eligibility and expiry.
- Checkout: `POST /api/payments/payos/create` with `{planId}`, followed by an
  HTTPS checkout URL opened outside the app.
- Status: `GET /api/payments/payos/:orderCode`; terminal statuses are `PAID`,
  `CANCELLED`, and `EXPIRED`; `PENDING` and `PROCESSING` remain refreshable.
- Premium activation is trusted only after the server webhook updates the user;
  Flutter never marks an account Premium from a redirect alone.

## Execution

1. Add typed plan/payment wire models and exact API tests.
2. Add controller checkout URL validation, terminal-state refresh and auth-user
   refresh after `PAID`.
3. Add responsive benefits/plans/trial/payment UI and profile route.
4. Verify Android/Web launch integration through an injected launcher, platform
   builds and live production read-only plans probe.

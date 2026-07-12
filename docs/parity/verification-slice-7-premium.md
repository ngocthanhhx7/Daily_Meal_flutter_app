# Slice 7 Premium Verification

Date: 2026-07-12

## Verified behavior

- Plans are rendered from the production contract rather than hard-coded
  pricing.
- Trial eligibility is displayed from authenticated user state; activation is
  accepted only from the server-returned user.
- PayOS checkout creation sends the selected wire plan ID and rejects missing,
  non-HTTPS or malformed checkout URLs.
- Payment state remains pending/processing until the user explicitly refreshes;
  paid state triggers an authenticated user refresh. Redirect/query parameters
  never grant Premium locally.
- Cancelled/expired/paid payments are terminal and stop showing refresh actions.

## Evidence

- API tests cover plans, create, status and trial endpoints/payloads.
- Controller tests cover external checkout launch, pending-to-paid transition,
  user refresh and trial state publication.
- Responsive widget journey covers plan selection, checkout and status refresh.
- Full analyzer/test and Android/Web builds run at the checkpoint.
- Read-only production probe confirmed three plans and their current contract:
  month `39,000/1`, quarter `99,000/3`, half `199,000/6` (VND/months).

# Slice 8 — Admin production parity

## Goal

Port the production Admin experience to Flutter Android/Web with a responsive
Material 3 shell and exact `/api/admin` contracts.

## Vertical slices

1. Dashboard foundation: typed dashboard contract, range selection, KPI cards,
   daily trend, breakdowns, recent activity and admin logout.
2. Users: search, pagination, detail, insights and Premium mutation.
3. Posts: filters, insights, pagination and moderation mutation.
4. Reports and payments: status/search filters, pagination and report actions.
5. Analytics: summary, 24-hour series, heatmap and AI report lifecycle.

## Verification

- API contract tests assert exact method/path/query/body.
- Controller tests assert loading, refresh, filters and mutation reconciliation.
- Widget tests assert compact navigation and tablet/desktop navigation rail,
  responsive content, error/retry and action flows.
- `flutter test`, `flutter analyze --no-pub`, Android debug APK and Web release.
- Update `docs/parity/feature-parity-matrix.md` and add Slice 8 evidence.

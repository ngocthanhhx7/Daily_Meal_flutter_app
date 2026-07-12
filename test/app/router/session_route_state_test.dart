import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signed-out sessions are redirected to login', () {
    expect(
      routeRedirect(SessionRouteState.signedOut, AppRoute.home.path),
      AppRoute.login.path,
    );
    expect(
      routeRedirect(SessionRouteState.signedOut, AppRoute.login.path),
      isNull,
    );
  });

  test('signed-out sessions may open the dedicated admin login', () {
    expect(routeRedirect(SessionRouteState.signedOut, '/admin/login'), isNull);
  });

  test('users who need onboarding stay in the onboarding branch', () {
    expect(
      routeRedirect(SessionRouteState.needsOnboarding, AppRoute.home.path),
      AppRoute.onboarding.path,
    );
    expect(
      routeRedirect(
        SessionRouteState.needsOnboarding,
        AppRoute.onboarding.path,
      ),
      isNull,
    );
  });

  test('onboarded users cannot enter auth or admin branches', () {
    expect(
      routeRedirect(SessionRouteState.user, AppRoute.login.path),
      AppRoute.home.path,
    );
    expect(
      routeRedirect(SessionRouteState.user, AppRoute.adminDashboard.path),
      AppRoute.home.path,
    );
  });

  test('admins stay in admin routes and users cannot enter them', () {
    expect(
      routeRedirect(SessionRouteState.admin, AppRoute.home.path),
      AppRoute.adminDashboard.path,
    );
    expect(
      routeRedirect(SessionRouteState.admin, AppRoute.adminDashboard.path),
      isNull,
    );
  });
}

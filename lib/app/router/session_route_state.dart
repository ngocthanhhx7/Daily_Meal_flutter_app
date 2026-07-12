import 'package:daily_meal_flutter_app/app/router/app_route.dart';

enum SessionRouteState { loading, signedOut, needsOnboarding, user, admin }

String? routeRedirect(SessionRouteState state, String location) {
  final isLogin = location == AppRoute.login.path;
  final isAdminLogin = location == AppRoute.adminLogin.path;
  final isOnboarding = location == AppRoute.onboarding.path;
  final isAdmin =
      location == AppRoute.adminDashboard.path ||
      location.startsWith('${AppRoute.adminDashboard.path}/');

  return switch (state) {
    SessionRouteState.loading => null,
    SessionRouteState.signedOut =>
      (isLogin || isAdminLogin) ? null : AppRoute.login.path,
    SessionRouteState.needsOnboarding =>
      isOnboarding ? null : AppRoute.onboarding.path,
    SessionRouteState.user =>
      (isLogin || isAdminLogin || isOnboarding || isAdmin)
          ? AppRoute.home.path
          : null,
    SessionRouteState.admin =>
      (isAdmin && !isAdminLogin) ? null : AppRoute.adminDashboard.path,
  };
}

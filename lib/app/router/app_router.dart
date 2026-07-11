import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/login_screen.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/admin_login_screen.dart';
import 'package:daily_meal_flutter_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(ValueNotifier<SessionRouteState> sessionState) {
  return GoRouter(
    initialLocation: AppRoute.login.path,
    refreshListenable: sessionState,
    redirect: (context, state) =>
        routeRedirect(sessionState.value, state.matchedLocation),
    routes: [
      for (final route in AppRoute.values)
        GoRoute(
          path: route.path,
          name: route.name,
          builder: (context, state) => switch (route) {
            AppRoute.login => const LoginScreen(),
            AppRoute.adminLogin => const AdminLoginScreen(),
            AppRoute.onboarding => const OnboardingScreen(),
            _ => FoundationRouteProbe(route: route),
          },
        ),
    ],
  );
}

class FoundationRouteProbe extends StatelessWidget {
  const FoundationRouteProbe({required this.route, super.key});
  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Foundation route ${route.name}',
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

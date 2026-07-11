import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/login_screen.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/admin_login_screen.dart';
import 'package:daily_meal_flutter_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/home_screen.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/create_post_screen.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/edit_post_screen.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/presentation/search_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/profile_screen.dart';
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
            AppRoute.home => const HomeScreen(),
            AppRoute.search => const SearchScreen(),
            AppRoute.profile => const ProfileScreen(),
            AppRoute.publicProfile => ProfileScreen(
              userId: state.pathParameters['id'],
            ),
            AppRoute.createPost => const CreatePostScreen(),
            AppRoute.editPost =>
              state.extra is FeedPost
                  ? EditPostScreen(
                      post: state.extra! as FeedPost,
                      onUpdated: (post) => context.pop(post),
                      onDeleted: (id) => context.pop(id),
                    )
                  : FoundationRouteProbe(route: route),
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

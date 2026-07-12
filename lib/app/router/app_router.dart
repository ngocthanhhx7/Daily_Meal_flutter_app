import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/login_screen.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/admin_login_screen.dart';
import 'package:daily_meal_flutter_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/home_screen.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/recipe_screen.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/create_post_screen.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/edit_post_route_screen.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/presentation/search_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/profile_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/follows_screen.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/blocked_screen.dart';
import 'package:daily_meal_flutter_app/features/messaging/presentation/inbox_screen.dart';
import 'package:daily_meal_flutter_app/features/messaging/presentation/chat_screen.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:daily_meal_flutter_app/features/notifications/presentation/notifications_screen.dart';
import 'package:daily_meal_flutter_app/features/comments/presentation/comments_screen.dart';
import 'package:daily_meal_flutter_app/features/premium/presentation/premium_screen.dart';
import 'package:daily_meal_flutter_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:daily_meal_flutter_app/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:daily_meal_flutter_app/features/user_utility/presentation/user_utility_screens.dart';
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
            AppRoute.editProfile => const EditProfileScreen(),
            AppRoute.saved => const ProfileScreen(showSaved: true),
            AppRoute.publicProfile => ProfileScreen(
              userId: state.pathParameters['id'],
            ),
            AppRoute.follows => FollowsScreen(
              userId: state.pathParameters['id']!,
              initialTab: state.uri.queryParameters['tab'] == 'following'
                  ? FollowTab.following
                  : FollowTab.followers,
              displayName: state.uri.queryParameters['name'],
            ),
            AppRoute.blocked => const BlockedScreen(),
            AppRoute.inbox => const InboxScreen(),
            AppRoute.chat => ChatScreen(
              conversationId: state.pathParameters['id']!,
              otherUser: state.extra is ChatUser
                  ? state.extra! as ChatUser
                  : null,
            ),
            AppRoute.notifications => const NotificationsScreen(),
            AppRoute.comments => CommentsScreen(
              postId: state.pathParameters['id']!,
              post: state.extra is FeedPost ? state.extra! as FeedPost : null,
            ),
            AppRoute.recipe => RecipeScreen(
              postId: state.pathParameters['id']!,
              authorId:
                  state.uri.queryParameters['authorId'] ??
                  (state.extra is FeedPost
                      ? (state.extra! as FeedPost).author.id
                      : ''),
              post: state.extra is FeedPost ? state.extra! as FeedPost : null,
            ),
            AppRoute.premium => const PremiumScreen(),
            AppRoute.settings => const SettingsScreen(),
            AppRoute.changePassword => const ChangePasswordScreen(),
            AppRoute.postSummary => const PostSummaryScreen(),
            AppRoute.progress => const ProgressScreen(),
            AppRoute.support => const SupportScreen(),
            AppRoute.shareAccount => const ShareAccountScreen(),
            AppRoute.adminDashboard => const AdminDashboardScreen(),
            AppRoute.adminUsers => const AdminDashboardScreen(
              initialDestination: 7,
            ),
            AppRoute.adminUserDetail => AdminUserDetailScreen(
              userId: state.pathParameters['id']!,
            ),
            AppRoute.createPost => const CreatePostScreen(),
            AppRoute.editPost => EditPostRouteScreen(
              postId: state.pathParameters['id']!,
              authorId:
                  state.uri.queryParameters['authorId'] ??
                  (state.extra is FeedPost
                      ? (state.extra! as FeedPost).author.id
                      : ''),
              post: state.extra is FeedPost ? state.extra! as FeedPost : null,
            ),
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

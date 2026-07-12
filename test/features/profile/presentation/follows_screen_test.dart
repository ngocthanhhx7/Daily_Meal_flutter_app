import 'package:daily_meal_flutter_app/app/router/app_route.dart';
import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/profile/presentation/follows_screen.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Repository implements ProfileRepositoryContract {
  final requests = <bool>[];
  @override
  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) async {
    requests.add(followers);
    return [
      PublicUser.fromJson({
        'id': 'u2',
        'displayName': 'Bếp Bạn',
        'bio': 'Món ngon',
        'counts': {'followers': 12},
        'relationship': {'isFollowing': false, 'followsMe': true},
      }),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('switching tabs updates the refresh-safe route query', (
    tester,
  ) async {
    final repository = _Repository();
    final router = GoRouter(
      initialLocation: '/users/u1/follows?tab=followers&name=Bếp+Bạn',
      routes: [
        GoRoute(
          path: AppRoute.follows.path,
          name: AppRoute.follows.name,
          builder: (context, state) => FollowsScreen(
            userId: state.pathParameters['id']!,
            initialTab: state.uri.queryParameters['tab'] == 'following'
                ? FollowTab.following
                : FollowTab.followers,
            displayName: state.uri.queryParameters['name'],
            currentUserId: 'me',
            repository: repository,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đang theo dõi'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'following',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['name'],
      'Bếp Bạn',
    );
  });

  testWidgets('renders full follows surface and switches refresh-safe tabs', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FollowsScreen(
            userId: 'u1',
            currentUserId: 'u1',
            repository: repository,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ của tôi'), findsOneWidget);
    expect(find.text('Cộng đồng đang theo dõi bạn'), findsOneWidget);
    expect(find.text('Bếp Bạn'), findsOneWidget);
    await tester.tap(find.text('Đang theo dõi'));
    await tester.pumpAndSettle();
    expect(repository.requests, [true, false]);
  });
}

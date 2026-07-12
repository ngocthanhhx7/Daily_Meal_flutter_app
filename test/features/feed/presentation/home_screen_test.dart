import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

class _Repository implements FeedRepositoryContract {
  @override
  Future<FeedPage> loadPage({required int page, required int limit}) async =>
      FeedPage(
        posts: [
          FeedPost.fromJson({
            '_id': 'post-1',
            'author': {
              'id': 'user-1',
              'displayName': 'Bếp Nhà',
              'isPremium': true,
              'streakDays': 3,
            },
            'caption': 'Bữa cơm gia đình',
            'tags': ['dailymeal'],
            'visibility': 'public',
            'stats': {'likes': 1, 'comments': 2, 'saves': 3},
            'createdAt': '2026-07-11T08:00:00Z',
            'updatedAt': '2026-07-11T08:00:00Z',
          }),
        ],
        page: 1,
        limit: limit,
        hasMore: false,
      );

  @override
  Future<FeedMutation> toggleLike(String postId) async => const FeedMutation(
    active: true,
    stats: PostStats(likes: 2, comments: 2, saves: 3),
  );

  @override
  Future<FeedMutation> toggleSave(String postId) async => const FeedMutation(
    active: true,
    stats: PostStats(likes: 2, comments: 2, saves: 4),
  );
}

class _OfflineThenOnlineRepository extends _Repository {
  var loadCalls = 0;

  @override
  Future<FeedPage> loadPage({required int page, required int limit}) async {
    loadCalls++;
    if (loadCalls == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/posts/feed'),
        error: const AppFailure.network(
          technicalMessage: 'SocketException: internal-host.local',
        ),
      );
    }
    return super.loadPage(page: page, limit: limit);
  }
}

void main() {
  testWidgets('renders feed and optimistic actions on compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FeedController(_Repository());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdaptiveScaffold.compactNavigationKey), findsOneWidget);
    expect(find.text('Bếp Nhà'), findsOneWidget);
    expect(find.text('Bữa cơm gia đình'), findsOneWidget);
    expect(find.text('#dailymeal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('like-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('save-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('uses navigation rail on tablet width', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(
            controller: FeedController(_Repository()),
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AdaptiveScaffold.railNavigationKey), findsOneWidget);
  });

  testWidgets('double tap likes an unliked post without toggling it off', (
    tester,
  ) async {
    final controller = FeedController(_Repository());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('post-media-post-1')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const Key('post-media-post-1')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.state.posts.single.viewerState.liked, isTrue);
    expect(controller.state.posts.single.stats.likes, 2);

    await tester.tap(find.byKey(const Key('post-media-post-1')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const Key('post-media-post-1')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.state.posts.single.viewerState.liked, isTrue);
  });

  testWidgets('honors reduced-motion by disabling heart transitions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: HomeScreen(
              controller: FeedController(_Repository()),
              mediaResolver: MediaUrlResolver(
                Uri.parse('https://api.dailymeal.site'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(opacity.duration, Duration.zero);
    expect(scale.duration, Duration.zero);
  });

  testWidgets('shows a safe offline error and recovers through retry', (
    tester,
  ) async {
    final repository = _OfflineThenOnlineRepository();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(
            controller: FeedController(repository),
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(const AppFailure.network().userMessage), findsOneWidget);
    expect(find.textContaining('internal-host.local'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('Bếp Nhà'), findsOneWidget);
  });
}

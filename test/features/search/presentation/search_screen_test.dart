import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/post_card.dart';
import 'package:daily_meal_flutter_app/features/search/application/search_controller.dart'
    as app_search;
import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';
import 'package:daily_meal_flutter_app/features/search/presentation/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements SearchRepositoryContract {
  @override
  Future<SearchResult> search(String query, SearchFilters filters) async =>
      SearchResult(
        posts: [
          FeedPost.fromJson({
            '_id': 'post-1',
            'author': {'id': 'author-1', 'displayName': 'Bếp xanh'},
            'caption': 'Salad mùa hè',
            'visibility': 'public',
            'createdAt': '2026-07-11T08:00:00Z',
            'updatedAt': '2026-07-11T08:00:00Z',
          }),
        ],
        users: [
          PublicUser.fromJson({
            'id': 'user-1',
            'displayName': 'Bếp Nhà',
            'counts': {'posts': 12, 'followers': 30},
          }),
        ],
      );

  @override
  Future<PublicUser> setFollowing(
    String userId, {
    required bool following,
  }) async => PublicUser.fromJson({
    'id': userId,
    'displayName': 'Bếp Nhà',
    'relationship': {'isFollowing': following},
  });

  @override
  Future<FeedMutation> toggleLike(String postId) async => const FeedMutation(
    active: true,
    stats: PostStats(likes: 1, comments: 0, saves: 0),
  );

  @override
  Future<FeedMutation> toggleSave(String postId) async => const FeedMutation(
    active: true,
    stats: PostStats(likes: 0, comments: 0, saves: 1),
  );
}

void main() {
  testWidgets('renders post and people results and allows following', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = app_search.SearchController(
      _Repository(),
      debounceDuration: Duration.zero,
    );
    addTearDown(controller.dispose);
    await controller.searchNow();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SearchScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salad mùa hè'), findsOneWidget);
    expect(find.byType(FeedPostCard), findsOneWidget);
    await tester.tap(find.text('Người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('Bếp Nhà'), findsOneWidget);

    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('Đang theo dõi'), findsOneWidget);
  });
}

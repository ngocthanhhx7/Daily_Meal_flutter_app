import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/application/search_controller.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/search/data/search_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';
import 'package:flutter_test/flutter_test.dart';

PublicUser user({bool following = false}) => PublicUser.fromJson({
  'id': 'user-1',
  'displayName': 'Bếp Nhà',
  'relationship': {
    'isFollowing': following,
    'followsMe': true,
    'isFriend': following,
  },
});

FeedPost post(String caption) => FeedPost.fromJson({
  '_id': 'post-1',
  'author': {'id': 'user-1', 'displayName': 'Bếp Nhà'},
  'caption': caption,
  'visibility': 'public',
  'createdAt': '2026-07-11T08:00:00Z',
  'updatedAt': '2026-07-11T08:00:00Z',
});

class _Repository implements SearchRepositoryContract {
  bool failFollow = false;
  bool failPostMutation = false;
  String query = '';
  SearchFilters? filters;

  @override
  Future<SearchResult> search(String query, SearchFilters filters) async {
    this.query = query;
    this.filters = filters;
    return SearchResult(posts: [post(query)], users: [user()]);
  }

  @override
  Future<PublicUser> setFollowing(
    String userId, {
    required bool following,
  }) async {
    if (failFollow) throw StateError('network');
    return user(following: following);
  }

  @override
  Future<FeedMutation> toggleLike(String postId) async {
    if (failPostMutation) throw StateError('network');
    return const FeedMutation(
      active: true,
      stats: PostStats(likes: 1, comments: 0, saves: 0),
    );
  }

  @override
  Future<FeedMutation> toggleSave(String postId) async {
    if (failPostMutation) throw StateError('network');
    return const FeedMutation(
      active: true,
      stats: PostStats(likes: 0, comments: 0, saves: 1),
    );
  }
}

void main() {
  test(
    'searches current query and filters into both result segments',
    () async {
      final repository = _Repository();
      final controller = SearchController(repository);
      controller.updateQuery('salad');
      controller.updateFilters(
        const SearchFilters(maxCalories: 500, personalized: false),
      );

      await controller.searchNow();

      expect(repository.query, 'salad');
      expect(repository.filters?.maxCalories, 500);
      expect(controller.state.posts.single.caption, 'salad');
      expect(controller.state.users.single.displayName, 'Bếp Nhà');
      expect(controller.state.status, SearchStatus.ready);
    },
  );

  test('optimistic follow rolls back when mutation fails', () async {
    final repository = _Repository();
    final controller = SearchController(repository);
    await controller.searchNow();
    repository.failFollow = true;

    final pending = controller.toggleFollow('user-1');
    expect(controller.state.users.single.relationship.isFollowing, isTrue);
    await expectLater(pending, throwsStateError);
    expect(controller.state.users.single.relationship.isFollowing, isFalse);
  });

  test('post interactions are reflected in search results', () async {
    final controller = SearchController(_Repository());
    await controller.searchNow();

    await controller.toggleLike('post-1');
    await controller.toggleSave('post-1');

    expect(controller.state.posts.single.viewerState.liked, isTrue);
    expect(controller.state.posts.single.viewerState.saved, isTrue);
    expect(controller.state.posts.single.stats.saves, 1);
  });
}

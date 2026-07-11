import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:flutter_test/flutter_test.dart';

FeedPost post(String id, {bool liked = false, bool saved = false}) =>
    FeedPost.fromJson({
      '_id': id,
      'author': {'id': 'user-$id', 'displayName': 'Meal $id'},
      'caption': id,
      'visibility': 'public',
      'stats': {'likes': liked ? 1 : 0, 'comments': 0, 'saves': saved ? 1 : 0},
      'viewerState': {'liked': liked, 'saved': saved},
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });

class _Repository implements FeedRepositoryContract {
  final pages = <int, FeedPage>{};
  bool failLike = false;

  @override
  Future<FeedPage> loadPage({required int page, required int limit}) async =>
      pages[page]!;

  @override
  Future<FeedMutation> toggleLike(String postId) async {
    if (failLike) throw StateError('network');
    return const FeedMutation(
      active: true,
      stats: PostStats(likes: 1, comments: 0, saves: 0),
    );
  }

  @override
  Future<FeedMutation> toggleSave(String postId) async => const FeedMutation(
    active: true,
    stats: PostStats(likes: 1, comments: 0, saves: 1),
  );
}

void main() {
  test(
    'loads, appends without duplicates and stops at terminal page',
    () async {
      final repository = _Repository()
        ..pages[1] = FeedPage(
          posts: [post('1'), post('2')],
          page: 1,
          limit: 2,
          hasMore: true,
        )
        ..pages[2] = FeedPage(
          posts: [post('2'), post('3')],
          page: 2,
          limit: 2,
          hasMore: false,
        );
      final controller = FeedController(repository, pageSize: 2);

      await controller.loadInitial();
      expect(controller.state.posts.map((item) => item.id), ['1', '2']);

      await controller.loadMore();
      expect(controller.state.posts.map((item) => item.id), ['1', '2', '3']);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.page, 2);
    },
  );

  test('refresh replaces the feed with page one', () async {
    final repository = _Repository()
      ..pages[1] = FeedPage(
        posts: [post('old')],
        page: 1,
        limit: 20,
        hasMore: false,
      );
    final controller = FeedController(repository);
    await controller.loadInitial();
    repository.pages[1] = FeedPage(
      posts: [post('new')],
      page: 1,
      limit: 20,
      hasMore: false,
    );

    await controller.refresh();
    expect(controller.state.posts.single.id, 'new');
  });

  test(
    'optimistic like rolls back on failure and save adopts server stats',
    () async {
      final repository = _Repository()
        ..pages[1] = FeedPage(
          posts: [post('1')],
          page: 1,
          limit: 20,
          hasMore: false,
        );
      final controller = FeedController(repository);
      await controller.loadInitial();

      repository.failLike = true;
      final pending = controller.toggleLike('1');
      expect(controller.state.posts.single.viewerState.liked, isTrue);
      expect(controller.state.posts.single.stats.likes, 1);
      await expectLater(pending, throwsStateError);
      expect(controller.state.posts.single.viewerState.liked, isFalse);
      expect(controller.state.posts.single.stats.likes, 0);

      await controller.toggleSave('1');
      expect(controller.state.posts.single.viewerState.saved, isTrue);
      expect(controller.state.posts.single.stats.saves, 1);
    },
  );

  test('applies edited posts and removes deleted posts in place', () async {
    final repository = _Repository()
      ..pages[1] = FeedPage(
        posts: [post('1'), post('2')],
        page: 1,
        limit: 20,
        hasMore: false,
      );
    final controller = FeedController(repository);
    await controller.loadInitial();

    final edited = FeedPost.fromJson({
      '_id': '1',
      'author': {'id': 'user-1', 'displayName': 'Meal 1'},
      'caption': 'Edited',
      'visibility': 'public',
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T09:00:00Z',
    });
    controller.applyPost(edited);
    expect(controller.state.posts.first.caption, 'Edited');

    controller.removePost('1');
    expect(controller.state.posts.map((item) => item.id), ['2']);
  });
}

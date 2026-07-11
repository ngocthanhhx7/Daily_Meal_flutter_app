import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';

abstract interface class FeedRepositoryContract {
  Future<FeedPage> loadPage({required int page, required int limit});
  Future<FeedMutation> toggleLike(String postId);
  Future<FeedMutation> toggleSave(String postId);
}

class FeedRepository implements FeedRepositoryContract {
  FeedRepository(this._api);

  final FeedApi _api;

  @override
  Future<FeedPage> loadPage({required int page, required int limit}) =>
      _api.loadPage(page: page, limit: limit);

  @override
  Future<FeedMutation> toggleLike(String postId) => _api.toggleLike(postId);

  @override
  Future<FeedMutation> toggleSave(String postId) => _api.toggleSave(postId);
}

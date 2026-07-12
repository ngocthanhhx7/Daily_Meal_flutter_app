import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';

abstract interface class SearchRepositoryContract {
  Future<SearchResult> search(String query, SearchFilters filters);
  Future<PublicUser> setFollowing(String userId, {required bool following});
  Future<FeedMutation> toggleLike(String postId);
  Future<FeedMutation> toggleSave(String postId);
}

class SearchRepository implements SearchRepositoryContract {
  SearchRepository(this._api, this._feedApi);
  final SearchApi _api;
  final FeedApi _feedApi;

  @override
  Future<SearchResult> search(String query, SearchFilters filters) =>
      _api.search(query, filters);

  @override
  Future<PublicUser> setFollowing(String userId, {required bool following}) =>
      _api.setFollowing(userId, following: following);

  @override
  Future<FeedMutation> toggleLike(String postId) => _feedApi.toggleLike(postId);

  @override
  Future<FeedMutation> toggleSave(String postId) => _feedApi.toggleSave(postId);
}

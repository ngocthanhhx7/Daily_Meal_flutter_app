import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';
import 'package:dio/dio.dart';

class SearchResult {
  const SearchResult({required this.posts, required this.users});
  final List<FeedPost> posts;
  final List<PublicUser> users;
}

class SearchApi {
  SearchApi(this._dio);
  final Dio _dio;

  Future<SearchResult> search(String query, SearchFilters filters) async {
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>(
        '/api/posts/search',
        queryParameters: filters.postQuery(query),
      ),
      _dio.get<Map<String, dynamic>>(
        '/api/users/search',
        queryParameters: filters.userQuery(query),
      ),
    ]);
    final postData = responses[0].data;
    final userData = responses[1].data;
    final rawPosts = postData?['posts'];
    final rawUsers = userData?['users'];
    if (rawPosts is! List || rawUsers is! List) {
      throw const FormatException('Invalid search response');
    }
    return SearchResult(
      posts: rawPosts
          .whereType<Map>()
          .map((post) => FeedPost.fromJson(post.cast<String, dynamic>()))
          .toList(growable: false),
      users: rawUsers
          .whereType<Map>()
          .map((user) => PublicUser.fromJson(user.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  Future<PublicUser> setFollowing(
    String userId, {
    required bool following,
  }) async {
    final response = following
        ? await _dio.post<Map<String, dynamic>>('/api/users/$userId/follow')
        : await _dio.delete<Map<String, dynamic>>('/api/users/$userId/follow');
    final raw = response.data?['user'];
    if (raw is! Map) throw const FormatException('Invalid follow response');
    return PublicUser.fromJson(raw.cast<String, dynamic>());
  }
}

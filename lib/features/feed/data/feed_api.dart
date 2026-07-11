import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:dio/dio.dart';

class FeedPage {
  const FeedPage({
    required this.posts,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<FeedPost> posts;
  final int page;
  final int limit;
  final bool hasMore;
}

class FeedMutation {
  const FeedMutation({required this.active, required this.stats});

  final bool active;
  final PostStats stats;
}

class FeedApi {
  FeedApi(this._dio);

  final Dio _dio;

  Future<FeedPage> loadPage({required int page, required int limit}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/posts/feed',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = _data(response);
    final rawPosts = data['posts'];
    if (rawPosts is! List) throw const FormatException('Missing feed posts');
    final posts = rawPosts
        .whereType<Map>()
        .map((post) => FeedPost.fromJson(post.cast<String, dynamic>()))
        .toList(growable: false);
    final responsePage = (data['page'] as num?)?.toInt() ?? page;
    final responseLimit = (data['limit'] as num?)?.toInt() ?? limit;
    return FeedPage(
      posts: posts,
      page: responsePage,
      limit: responseLimit,
      hasMore: posts.length >= responseLimit,
    );
  }

  Future<FeedMutation> toggleLike(String postId) =>
      _mutation('/api/posts/$postId/like', 'liked');

  Future<FeedMutation> toggleSave(String postId) =>
      _mutation('/api/posts/$postId/save', 'saved');

  Future<FeedMutation> _mutation(String path, String activeKey) async {
    final response = await _dio.post<Map<String, dynamic>>(path);
    final data = _data(response);
    if (data[activeKey] is! bool || data['stats'] is! Map) {
      throw FormatException('Invalid feed mutation: $path');
    }
    return FeedMutation(
      active: data[activeKey] as bool,
      stats: PostStats.fromJson((data['stats'] as Map).cast<String, dynamic>()),
    );
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Missing response body');
    return data;
  }
}

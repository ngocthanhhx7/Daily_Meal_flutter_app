import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:dio/dio.dart';

abstract interface class PostLookupRepositoryContract {
  Future<FeedPost> findByAuthor({
    required String postId,
    required String authorId,
  });
}

class PostLookupRepository implements PostLookupRepositoryContract {
  PostLookupRepository(this._dio);
  final Dio _dio;

  @override
  Future<FeedPost> findByAuthor({
    required String postId,
    required String authorId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/$authorId/posts',
    );
    final raw = response.data?['posts'];
    if (raw is! List) {
      throw const FormatException('Invalid user posts response');
    }
    for (final item in raw.whereType<Map>()) {
      final post = FeedPost.fromJson(item.cast<String, dynamic>());
      if (post.id == postId) {
        return post;
      }
    }
    throw StateError('Post not found');
  }
}

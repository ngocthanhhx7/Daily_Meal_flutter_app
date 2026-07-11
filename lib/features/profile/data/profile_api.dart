import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:dio/dio.dart';

class ProfileBundle {
  const ProfileBundle({
    required this.user,
    required this.posts,
    required this.savedPosts,
  });
  final PublicUser user;
  final List<FeedPost> posts;
  final List<FeedPost> savedPosts;
}

class ProfileApi {
  ProfileApi(this._dio);
  final Dio _dio;

  Future<ProfileBundle> loadProfile(
    String userId, {
    required bool includeSaved,
  }) async {
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>('/api/users/$userId'),
      _dio.get<Map<String, dynamic>>('/api/users/$userId/posts'),
      if (includeSaved)
        _dio.get<Map<String, dynamic>>('/api/users/$userId/saved-posts'),
    ]);
    final rawUser = responses[0].data?['user'];
    if (rawUser is! Map) {
      throw const FormatException('Invalid profile response');
    }
    return ProfileBundle(
      user: PublicUser.fromJson(rawUser.cast<String, dynamic>()),
      posts: _posts(responses[1].data),
      savedPosts: includeSaved ? _posts(responses[2].data) : const [],
    );
  }

  Future<List<PublicUser>> loadFollows(
    String userId, {
    required bool followers,
  }) async {
    final suffix = followers ? 'followers' : 'following';
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/$userId/$suffix',
    );
    final raw = response.data?['users'];
    if (raw is! List) {
      throw const FormatException('Invalid follows response');
    }
    return raw
        .whereType<Map>()
        .map((item) => PublicUser.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<PublicUser> updateMe(Map<String, dynamic> changes) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/users/me',
      data: changes,
    );
    final raw = response.data?['user'];
    if (raw is! Map) {
      throw const FormatException('Invalid profile update response');
    }
    return PublicUser.fromJson(raw.cast<String, dynamic>());
  }

  List<FeedPost> _posts(Map<String, dynamic>? data) {
    final raw = data?['posts'];
    if (raw is! List) {
      throw const FormatException('Invalid profile posts response');
    }
    return raw
        .whereType<Map>()
        .map((item) => FeedPost.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }
}

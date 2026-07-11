import 'dart:typed_data';

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

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String category,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/uploads',
      queryParameters: {'category': category},
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      }),
    );
    final upload = response.data?['upload'];
    final url = upload is Map ? upload['url'] : null;
    if (url is! String || url.isEmpty) {
      throw const FormatException('Invalid profile image upload response');
    }
    return url;
  }

  Future<bool> setInteraction(
    String userId,
    String type, {
    required bool active,
    String? note,
  }) async {
    final response = active
        ? await _dio.post<Map<String, dynamic>>(
            '/api/users/$userId/interactions',
            data: {
              'type': type,
              if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
            },
          )
        : await _dio.delete<Map<String, dynamic>>(
            '/api/users/$userId/interactions/$type',
          );
    final value = response.data?['active'];
    if (value is! bool) {
      throw const FormatException('Invalid interaction response');
    }
    return value;
  }

  Future<List<PublicUser>> loadBlockedUsers() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/me/interactions/blocked',
    );
    final raw = response.data?['users'];
    if (raw is! List) {
      throw const FormatException('Invalid blocked users response');
    }
    return raw
        .whereType<Map>()
        .map((item) => PublicUser.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
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

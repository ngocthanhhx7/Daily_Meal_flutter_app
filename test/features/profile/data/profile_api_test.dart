import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/profile/data/profile_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch (options.path) {
      '/api/users/user-1' => {
        'user': {
          'id': 'user-1',
          'displayName': 'Bếp Nhà',
          'counts': {'posts': 1, 'followers': 2},
        },
      },
      '/api/users/me' => {
        'user': {'id': 'user-1', 'displayName': 'Bếp Mới', 'bio': 'Món mới'},
      },
      '/api/users/user-1/posts' || '/api/users/user-1/saved-posts' => {
        'posts': [
          {
            '_id': 'post-1',
            'author': {'id': 'user-1', 'displayName': 'Bếp Nhà'},
            'caption': 'Bữa sáng',
            'visibility': 'public',
            'createdAt': '2026-07-11T08:00:00Z',
            'updatedAt': '2026-07-11T08:00:00Z',
          },
        ],
      },
      '/api/users/user-1/followers' || '/api/users/user-1/following' => {
        'users': [
          {'id': 'user-2', 'displayName': 'Bạn Bếp'},
        ],
      },
      _ => throw StateError('Unexpected ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'loads profile, posts, saved posts and follow graph contracts',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter;
      final api = ProfileApi(dio);

      final profile = await api.loadProfile('user-1', includeSaved: true);
      final followers = await api.loadFollows('user-1', followers: true);
      final updated = await api.updateMe({
        'displayName': 'Bếp Mới',
        'bio': 'Món mới',
      });

      expect(profile.user.displayName, 'Bếp Nhà');
      expect(profile.posts.single.id, 'post-1');
      expect(profile.savedPosts.single.viewerState.saved, isFalse);
      expect(followers.single.id, 'user-2');
      expect(updated.displayName, 'Bếp Mới');
      final updateRequest = adapter.requests.singleWhere(
        (item) => item.path == '/api/users/me',
      );
      expect(updateRequest.method, 'PATCH');
      expect(updateRequest.data, {'displayName': 'Bếp Mới', 'bio': 'Món mới'});
      expect(
        adapter.requests.map((item) => item.path),
        containsAll([
          '/api/users/user-1',
          '/api/users/user-1/posts',
          '/api/users/user-1/saved-posts',
          '/api/users/user-1/followers',
        ]),
      );
    },
  );
}

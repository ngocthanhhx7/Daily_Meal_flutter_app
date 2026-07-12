import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/user_utility/data/user_utility_api.dart';
import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
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
      '/api/posts/summary' => {
        'posts': [
          {
            '_id': 'p1',
            'caption': 'Bữa sáng',
            'author': {'id': 'u1', 'displayName': 'An'},
            'images': [],
            'stats': {},
          },
        ],
        'page': 2,
        'hasMore': true,
      },
      '/api/users/u1/posts' => {
        'posts': [
          {
            '_id': 'mine',
            'caption': 'Món của tôi',
            'author': {'displayName': 'An'},
            'stats': {'likes': 4},
          },
        ],
      },
      '/api/auth/google/link' => {
        'user': {
          'id': 'u1',
          'displayName': 'An',
          'preferences': {'completedOnboarding': true},
          'counts': {},
        },
      },
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      options.path == '/api/auth/password' ? 204 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses exact change password contract', () async {
    final adapter = _Adapter();
    final api = UserUtilityApi(Dio()..httpClientAdapter = adapter);
    await api.changePassword(
      currentPassword: 'old-pass',
      newPassword: 'new-password',
    );
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/api/auth/password');
    expect(adapter.requests.single.data, {
      'currentPassword': 'old-pass',
      'newPassword': 'new-password',
    });
  });

  test('uses exact filtered post summary paging contract', () async {
    final adapter = _Adapter();
    final api = UserUtilityApi(Dio()..httpClientAdapter = adapter);
    final page = await api.postSummary(PostSummaryFilter.friends, page: 2);
    expect(page.posts.single.id, 'p1');
    expect(page.hasMore, isTrue);
    expect(adapter.requests.single.queryParameters, {
      'filter': 'friends',
      'page': 2,
      'limit': 30,
    });
  });

  test('loads progress from the exact owner posts contract', () async {
    final adapter = _Adapter();
    final api = UserUtilityApi(Dio()..httpClientAdapter = adapter);
    expect((await api.userPosts('u1')).single.likes, 4);
    expect(adapter.requests.single.path, '/api/users/u1/posts');
  });
  test('links Google with exact authenticated token exchange', () async {
    final adapter = _Adapter();
    final api = UserUtilityApi(Dio()..httpClientAdapter = adapter);
    expect((await api.linkGoogle('google-id-token')).id, 'u1');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/api/auth/google/link');
    expect(adapter.requests.single.data, {'idToken': 'google-id-token'});
  });
}

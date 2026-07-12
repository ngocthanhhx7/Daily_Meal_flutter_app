import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final body = switch (options.path) {
      '/api/posts/feed' => {
        'posts': [
          {
            '_id': 'post-1',
            'author': {'id': 'user-1', 'displayName': 'Meal'},
            'caption': 'Lunch',
            'visibility': 'public',
            'stats': {'likes': 1, 'comments': 2, 'saves': 3},
            'createdAt': '2026-07-11T08:00:00Z',
            'updatedAt': '2026-07-11T08:00:00Z',
          },
        ],
        'page': 2,
        'limit': 20,
      },
      '/api/posts/post-1/like' => {
        'liked': true,
        'stats': {'likes': 2, 'comments': 2, 'saves': 3},
      },
      '/api/posts/post-1/save' => {
        'saved': true,
        'stats': {'likes': 2, 'comments': 2, 'saves': 4},
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
  late _Adapter adapter;
  late FeedRepository repository;

  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    repository = FeedRepository(FeedApi(dio));
  });

  test('loads the exact page-based feed contract', () async {
    final result = await repository.loadPage(page: 2, limit: 20);

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, '/api/posts/feed');
    expect(adapter.lastRequest?.queryParameters, {'page': 2, 'limit': 20});
    expect(result.page, 2);
    expect(result.posts.single.id, 'post-1');
    expect(result.hasMore, isFalse);
  });

  test('uses exact like and save mutation contracts', () async {
    final liked = await repository.toggleLike('post-1');
    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/api/posts/post-1/like');
    expect(liked.active, isTrue);
    expect(liked.stats.likes, 2);

    final saved = await repository.toggleSave('post-1');
    expect(adapter.lastRequest?.path, '/api/posts/post-1/save');
    expect(saved.active, isTrue);
    expect(saved.stats.saves, 4);
  });
}

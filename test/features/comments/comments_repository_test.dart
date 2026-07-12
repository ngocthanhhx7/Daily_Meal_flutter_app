import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/comments/data/comments_api.dart';
import 'package:daily_meal_flutter_app/features/comments/data/comments_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final comment = {
      '_id': 'comment-1',
      'body': options.method == 'POST' ? 'Ngon quá!' : 'Đẹp quá',
      'author': {
        '_id': 'user-1',
        'displayName': 'Bếp Nhà',
        'avatarUrl': '/uploads/avatar.jpg',
        'themeColor': '#8BA58A',
      },
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    };
    final body = options.method == 'POST'
        ? {'comment': comment}
        : {
            'comments': [comment],
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      options.method == 'POST' ? 201 : 200,
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
  late CommentsRepository repository;

  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    repository = CommentsRepository(CommentsApi(dio));
  });

  test('loads comments using the exact post contract', () async {
    final comments = await repository.load('post-1');

    expect(adapter.request?.method, 'GET');
    expect(adapter.request?.path, '/api/posts/post-1/comments');
    expect(comments.single.id, 'comment-1');
    expect(comments.single.author.id, 'user-1');
    expect(comments.single.author.displayName, 'Bếp Nhà');
  });

  test('creates a trimmed comment using body envelope', () async {
    final comment = await repository.create('post-1', '  Ngon quá!  ');

    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/api/posts/post-1/comments');
    expect(adapter.request?.data, {'body': 'Ngon quá!'});
    expect(comment.body, 'Ngon quá!');
  });

  test('rejects blank and overlong comments before network', () async {
    await expectLater(repository.create('post-1', '  '), throwsArgumentError);
    await expectLater(
      repository.create('post-1', 'x' * 501),
      throwsArgumentError,
    );
  });
}

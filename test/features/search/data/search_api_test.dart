import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/search/data/search_api.dart';
import 'package:daily_meal_flutter_app/features/search/domain/search_filters.dart';
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
    final body = options.path == '/api/posts/search'
        ? {
            'posts': [
              {
                '_id': 'post-1',
                'author': {'id': 'user-1', 'displayName': 'Bếp Nhà'},
                'caption': 'Salad',
                'visibility': 'public',
                'createdAt': '2026-07-11T08:00:00Z',
                'updatedAt': '2026-07-11T08:00:00Z',
              },
            ],
          }
        : {
            'users': [
              {
                'id': 'user-1',
                'displayName': 'Bếp Nhà',
                'bio': 'Healthy food',
                'isPremium': true,
                'counts': {'followers': 4, 'following': 2, 'posts': 3},
                'relationship': {
                  'isFollowing': false,
                  'followsMe': true,
                  'isFriend': false,
                },
                'viewerInteraction': {
                  'restricted': false,
                  'blocked': false,
                  'reported': false,
                },
              },
            ],
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
    'searches posts and users with exact personalized filter contract',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter;
      final api = SearchApi(dio);
      const filters = SearchFilters(
        maxCalories: 500,
        saved: true,
        premiumSticker: true,
        personalized: false,
      );

      final result = await api.search(' salad ', filters);

      final postsRequest = adapter.requests.firstWhere(
        (request) => request.path == '/api/posts/search',
      );
      expect(postsRequest.queryParameters, {
        'q': 'salad',
        'maxCalories': 500,
        'saved': true,
        'premiumSticker': true,
        'personalized': false,
      });
      final usersRequest = adapter.requests.firstWhere(
        (request) => request.path == '/api/users/search',
      );
      expect(usersRequest.queryParameters, {
        'q': 'salad',
        'personalized': false,
      });
      expect(result.posts.single.id, 'post-1');
      expect(result.users.single.relationship.followsMe, isTrue);
      expect(result.users.single.counts.followers, 4);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_api.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
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
    final body = switch (options.path) {
      '/api/uploads' => {
        'upload': {
          '_id': 'upload-1',
          'mediaType': 'image',
          'url': '/uploads/meal.jpg',
          'mime': 'image/jpeg',
          'size': 3,
        },
      },
      '/api/meals/analyze' => {
        'meal': {
          '_id': 'meal-1',
          'image': {'url': '/uploads/meal.jpg', 'uploadId': 'upload-1'},
          'result': {
            'items': [
              {
                'name': 'Cơm',
                'portion': '1 bát',
                'calories': 200,
                'protein': 4,
                'carbs': 45,
                'fat': 1,
                'confidence': 0.9,
              },
            ],
            'total': {
              'calories': 200,
              'protein': 4,
              'carbs': 45,
              'fat': 1,
              'confidence': 0.9,
            },
            'warnings': ['Ước tính'],
          },
          'createdAt': '2026-07-11T08:00:00Z',
        },
      },
      '/api/stickers' when options.method == 'GET' => {
        'stickers': [
          {
            '_id': 'sticker-1',
            'key': 'fresh',
            'name': 'Fresh',
            'assetPath': '/stickers/fresh.svg',
            'premiumOnly': false,
          },
        ],
      },
      '/api/stickers' => {
        'sticker': {
          '_id': 'custom-1',
          ...((options.data as Map).cast<String, dynamic>()),
          'premiumOnly': true,
        },
      },
      '/api/posts' => {
        'post': {
          '_id': 'post-1',
          'author': {'id': 'user-1', 'displayName': 'Meal'},
          ...((options.data as Map).cast<String, dynamic>()),
          'stats': {'likes': 0, 'comments': 0, 'saves': 0},
          'createdAt': '2026-07-11T08:00:00Z',
          'updatedAt': '2026-07-11T08:00:00Z',
        },
      },
      '/api/posts/post-1' when options.method == 'PATCH' => {
        'post': {
          '_id': 'post-1',
          'author': {'id': 'user-1', 'displayName': 'Meal'},
          'caption': (options.data as Map)['caption'],
          'tags': (options.data as Map)['tags'],
          'visibility': 'public',
          'createdAt': '2026-07-11T08:00:00Z',
          'updatedAt': '2026-07-11T09:00:00Z',
        },
      },
      '/api/posts/post-1' => <String, dynamic>{},
      _ => throw StateError('Unexpected ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      options.path == '/api/stickers' ? 200 : 201,
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
  late PostEditorApi api;

  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    api = PostEditorApi(dio);
  });

  test('uploads image bytes with exact multipart field and category', () async {
    final upload = await api.upload(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'meal.jpg',
      mimeType: 'image/jpeg',
      mediaType: DraftMediaType.image,
    );

    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/api/uploads');
    expect(adapter.request?.queryParameters, {'category': 'post'});
    final form = adapter.request?.data as FormData;
    expect(form.files.single.key, 'image');
    expect(form.files.single.value.filename, 'meal.jpg');
    expect(form.files.single.value.contentType.toString(), 'image/jpeg');
    expect(upload.id, 'upload-1');
  });

  test(
    'analyzes upload, lists stickers and creates exact post payload',
    () async {
      final meal = await api.analyze('upload-1', hints: 'ít dầu');
      expect(adapter.request?.data, {
        'uploadId': 'upload-1',
        'hints': {'ingredientsText': 'ít dầu'},
      });
      expect(meal.result.total.calories, 200);

      final stickers = await api.stickers();
      expect(stickers.single.id, 'sticker-1');

      final draft = PostDraft(
        mediaType: DraftMediaType.image,
        images: const [
          UploadedMedia(
            id: 'upload-1',
            mediaType: DraftMediaType.image,
            url: '/uploads/meal.jpg',
            mime: 'image/jpeg',
            size: 3,
          ),
        ],
        caption: 'Bữa trưa',
        tags: const ['healthy'],
        visibility: PostVisibility.friends,
        layout: PostLayout.stack,
        recipes: const [
          ImageRecipe(
            imageIndex: 0,
            title: 'Cơm',
            ingredients: ['gạo'],
            steps: ['nấu'],
          ),
        ],
        nutritionDetails: [meal.toNutritionDetail(0)],
      );
      final created = await api.createPost(draft);

      expect(adapter.request?.path, '/api/posts');
      expect(adapter.request?.data, draft.toJson());
      expect(created.id, 'post-1');
    },
  );

  test('creates custom sticker and updates/deletes owned post', () async {
    final sticker = await api.createSticker(
      name: 'Tự tải',
      key: 'custom-1',
      assetPath: '/uploads/sticker.png',
    );
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.data, {
      'name': 'Tự tải',
      'key': 'custom-1',
      'assetPath': '/uploads/sticker.png',
    });
    expect(sticker.id, 'custom-1');

    final updated = await api.updatePost(
      'post-1',
      caption: ' Updated ',
      tags: const ['healthy'],
    );
    expect(adapter.request?.method, 'PATCH');
    expect(adapter.request?.path, '/api/posts/post-1');
    expect(adapter.request?.data, {
      'caption': 'Updated',
      'tags': ['healthy'],
    });
    expect(updated.caption, 'Updated');

    await api.deletePost('post-1');
    expect(adapter.request?.method, 'DELETE');
    expect(adapter.request?.path, '/api/posts/post-1');
  });
}

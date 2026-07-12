import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/domain/post_draft.dart';
import 'package:dio/dio.dart';

class PostEditorApi {
  PostEditorApi(this._dio);
  final Dio _dio;

  Future<UploadedMedia> upload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required DraftMediaType mediaType,
    String category = 'post',
  }) async {
    final form = FormData.fromMap({
      mediaType.name: MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/uploads',
      queryParameters: {'category': category},
      data: form,
    );
    final upload = _data(response)['upload'];
    if (upload is! Map) throw const FormatException('Missing upload');
    return UploadedMedia.fromJson(upload.cast<String, dynamic>());
  }

  Future<MealAnalysis> analyze(String uploadId, {String? hints}) async {
    final normalized = hints?.trim() ?? '';
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/meals/analyze',
      data: {
        'uploadId': uploadId,
        if (normalized.isNotEmpty) 'hints': {'ingredientsText': normalized},
      },
    );
    final meal = _data(response)['meal'];
    if (meal is! Map) throw const FormatException('Missing meal analysis');
    return MealAnalysis.fromJson(meal.cast<String, dynamic>());
  }

  Future<List<PostSticker>> stickers() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/stickers');
    final raw = _data(response)['stickers'];
    if (raw is! List) throw const FormatException('Missing stickers');
    return raw
        .whereType<Map>()
        .map((item) => PostSticker.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<PostSticker> createSticker({
    required String name,
    required String key,
    required String assetPath,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/stickers',
      data: {'name': name, 'key': key, 'assetPath': assetPath},
    );
    final raw = _data(response)['sticker'];
    if (raw is! Map) throw const FormatException('Missing created sticker');
    return PostSticker.fromJson(raw.cast<String, dynamic>());
  }

  Future<FeedPost> createPost(PostDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/posts',
      data: draft.toJson(),
    );
    final post = _data(response)['post'];
    if (post is! Map) throw const FormatException('Missing created post');
    return FeedPost.fromJson(post.cast<String, dynamic>());
  }

  Future<FeedPost> updatePost(
    String postId, {
    required String caption,
    required List<String> tags,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/posts/$postId',
      data: {'caption': caption.trim(), 'tags': tags},
    );
    final raw = _data(response)['post'];
    if (raw is! Map) throw const FormatException('Missing updated post');
    return FeedPost.fromJson(raw.cast<String, dynamic>());
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete<void>('/api/posts/$postId');
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Missing response body');
    return data;
  }
}

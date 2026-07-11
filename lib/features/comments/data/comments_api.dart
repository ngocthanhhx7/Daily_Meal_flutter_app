import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:dio/dio.dart';

class CommentsApi {
  CommentsApi(this._dio);
  final Dio _dio;

  Future<List<PostComment>> load(String postId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/posts/$postId/comments',
    );
    final data = _data(response);
    final raw = data['comments'];
    if (raw is! List) throw const FormatException('Missing comments');
    return raw
        .whereType<Map>()
        .map((item) => PostComment.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<PostComment> create(String postId, String body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/posts/$postId/comments',
      data: {'body': body},
    );
    final raw = _data(response)['comment'];
    if (raw is! Map) throw const FormatException('Missing created comment');
    return PostComment.fromJson(raw.cast<String, dynamic>());
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Missing response body');
    return data;
  }
}

import 'package:daily_meal_flutter_app/features/user_utility/domain/post_summary.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:dio/dio.dart';

class UserUtilityApi {
  UserUtilityApi(this._dio);
  final Dio _dio;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _dio.patch<void>(
    '/api/auth/password',
    data: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );

  Future<PostSummaryPage> postSummary(
    PostSummaryFilter filter, {
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/posts/summary',
      queryParameters: {'filter': filter.wireValue, 'page': page, 'limit': 30},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Invalid post summary response');
    }
    return PostSummaryPage.fromJson(data);
  }

  Future<List<SummaryPost>> userPosts(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/$userId/posts',
    );
    final raw = response.data?['posts'];
    if (raw is! List) {
      throw const FormatException('Invalid user posts response');
    }
    return raw
        .whereType<Map>()
        .map((e) => SummaryPost.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<AppUser> linkGoogle(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/google/link',
      data: {'idToken': idToken},
    );
    final raw = response.data?['user'];
    if (raw is! Map) {
      throw const FormatException('Invalid Google link response');
    }
    return AppUser.fromJson(raw.cast<String, dynamic>());
  }
}

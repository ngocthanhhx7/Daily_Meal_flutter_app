import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:dio/dio.dart';

class NotificationsApi {
  NotificationsApi(this._dio);
  final Dio _dio;
  Future<List<AppNotification>> load() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/notifications');
    final raw = response.data?['notifications'];
    if (raw is! List) {
      throw const FormatException('Invalid notifications response');
    }
    return raw
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> markRead(String id) async =>
      _dio.patch<void>('/api/notifications/$id/read');
  Future<void> markAllRead() async =>
      _dio.patch<void>('/api/notifications/read-all');
  Future<void> delete(String id) async =>
      _dio.delete<void>('/api/notifications/$id');
  Future<void> deleteAll() async => _dio.delete<void>('/api/notifications');
}

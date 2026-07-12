import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:dio/dio.dart';

class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<AdminDashboard> dashboard(AdminRange range) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/admin/dashboard',
      queryParameters: {'range': range.wireValue},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Invalid Admin dashboard response');
    }
    return AdminDashboard.fromJson(data);
  }

  Future<AdminPage<AdminUser>> users({String query = '', int page = 1}) async =>
      adminPage(
        await _get('/api/admin/users', {'q': query, 'page': page, 'limit': 20}),
        'users',
        AdminUser.fromJson,
      );

  Future<AdminUser> setPremium(
    String id,
    bool value, {
    String note = '',
  }) async {
    final data = await _patch('/api/admin/users/$id/premium', {
      'isPremium': value,
      if (note.isNotEmpty) 'note': note,
    });
    return AdminUser.fromJson(_object(data['user'], 'Admin user'));
  }

  Future<Map<String, dynamic>> userInsights(AdminRange range) =>
      _get('/api/admin/users/insights', {'range': range.wireValue});

  Future<Map<String, dynamic>> userDetail(String id) =>
      _get('/api/admin/users/$id', const {});

  Future<AdminPage<AdminPost>> posts({
    String query = '',
    int page = 1,
    String? moderationStatus,
    AdminRange range = AdminRange.sevenDays,
    String mediaKind = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? start,
    String? end,
  }) async => adminPage(
    await _get('/api/admin/posts', {
      'q': query,
      'page': page,
      'limit': 20,
      'moderationStatus': ?moderationStatus,
      'range': range.wireValue,
      if (mediaKind != 'all') 'mediaKind': mediaKind,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'start': ?start,
      'end': ?end,
    }),
    'posts',
    AdminPost.fromJson,
  );

  Future<AdminPost> moderatePost(
    String id,
    String status, {
    String reason = '',
  }) async {
    final data = await _patch('/api/admin/posts/$id/moderation', {
      'moderationStatus': status,
      if (reason.isNotEmpty) 'reason': reason,
    });
    return AdminPost.fromJson(_object(data['post'], 'Admin post'));
  }

  Future<Map<String, dynamic>> postInsights({
    String query = '',
    String? moderationStatus,
    AdminRange range = AdminRange.sevenDays,
    String mediaKind = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? start,
    String? end,
  }) => _get('/api/admin/posts/insights', {
    'q': query,
    'range': range.wireValue,
    'moderationStatus': ?moderationStatus,
    if (mediaKind != 'all') 'mediaKind': mediaKind,
    'sortBy': sortBy,
    'sortOrder': sortOrder,
    'start': ?start,
    'end': ?end,
  });

  Future<AdminPage<AdminReport>> reports({
    String status = 'open',
    int page = 1,
  }) async => adminPage(
    await _get('/api/admin/reports', {
      'status': status,
      'page': page,
      'limit': 20,
    }),
    'reports',
    AdminReport.fromJson,
  );

  Future<AdminReport> updateReport(
    String id,
    String status, {
    String adminNote = '',
  }) async {
    final data = await _patch('/api/admin/reports/$id', {
      'status': status,
      if (adminNote.isNotEmpty) 'adminNote': adminNote,
    });
    return AdminReport.fromJson(_object(data['report'], 'Admin report'));
  }

  Future<AdminPage<AdminPayment>> payments({
    String query = '',
    int page = 1,
  }) async => adminPage(
    await _get('/api/admin/payments', {'q': query, 'page': page, 'limit': 20}),
    'payments',
    AdminPayment.fromJson,
  );

  Future<Map<String, dynamic>> analyticsSummary(AdminRange range) =>
      _get('/api/admin/analytics/summary', {'range': range.wireValue});
  Future<AdminAnalytics24h> analytics24h({
    String preset = 'last24h',
    String timezone = 'Asia/Ho_Chi_Minh',
  }) async => AdminAnalytics24h.fromJson(
    await _get('/api/admin/analytics/24h', {
      'preset': preset,
      'timezone': timezone,
    }),
  );
  Future<AdminHeatmap> heatmap({
    String preset = '7d',
    String timezone = 'Asia/Ho_Chi_Minh',
    String metric = 'events',
  }) async => AdminHeatmap.fromJson(
    await _get('/api/admin/analytics/heatmap', {
      'preset': preset,
      'timezone': timezone,
      'metric': metric,
    }),
  );
  Future<AdminAiReport> generateAiReport(AdminRange range) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin/reports/ai',
      data: {'range': range.wireValue},
    );
    if (response.data case final data?) return AdminAiReport.fromJson(data);
    throw const FormatException('Invalid Admin AI report response');
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    if (response.data case final data?) return data;
    throw const FormatException('Invalid Admin list response');
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(path, data: body);
    if (response.data case final data?) return data;
    throw const FormatException('Invalid Admin mutation response');
  }

  static Map<String, dynamic> _object(Object? value, String name) {
    if (value is Map) return value.cast<String, dynamic>();
    throw FormatException('Invalid $name response');
  }
}

import 'package:daily_meal_flutter_app/features/admin/data/admin_api.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';

abstract interface class AdminRepositoryContract {
  Future<AdminDashboard> dashboard(AdminRange range);
  Future<AdminPage<AdminUser>> users({String query = '', int page = 1});
  Future<AdminUser> setPremium(String id, bool value, {String note = ''});
  Future<Map<String, dynamic>> userInsights(AdminRange range);
  Future<Map<String, dynamic>> userDetail(String id);
  Future<AdminPage<AdminPost>> posts({
    String query = '',
    int page = 1,
    String? moderationStatus,
  });
  Future<AdminPost> moderatePost(
    String id,
    String status, {
    String reason = '',
  });
  Future<Map<String, dynamic>> postInsights({String? moderationStatus});
  Future<AdminPage<AdminReport>> reports({
    String status = 'open',
    int page = 1,
  });
  Future<AdminReport> updateReport(
    String id,
    String status, {
    String adminNote = '',
  });
  Future<AdminPage<AdminPayment>> payments({String query = '', int page = 1});
  Future<Map<String, dynamic>> analyticsSummary(AdminRange range);
  Future<AdminAnalytics24h> analytics24h();
  Future<AdminHeatmap> heatmap({String metric = 'events'});
  Future<AdminAiReport> generateAiReport(AdminRange range);
}

class AdminRepository implements AdminRepositoryContract {
  AdminRepository(this._api);
  final AdminApi _api;
  @override
  Future<AdminDashboard> dashboard(AdminRange range) => _api.dashboard(range);
  @override
  Future<AdminPage<AdminUser>> users({String query = '', int page = 1}) =>
      _api.users(query: query, page: page);
  @override
  Future<AdminUser> setPremium(String id, bool value, {String note = ''}) =>
      _api.setPremium(id, value, note: note);
  @override
  Future<Map<String, dynamic>> userInsights(AdminRange range) =>
      _api.userInsights(range);
  @override
  Future<Map<String, dynamic>> userDetail(String id) => _api.userDetail(id);
  @override
  Future<AdminPage<AdminPost>> posts({
    String query = '',
    int page = 1,
    String? moderationStatus,
  }) =>
      _api.posts(query: query, page: page, moderationStatus: moderationStatus);
  @override
  Future<AdminPost> moderatePost(
    String id,
    String status, {
    String reason = '',
  }) => _api.moderatePost(id, status, reason: reason);
  @override
  Future<Map<String, dynamic>> postInsights({String? moderationStatus}) =>
      _api.postInsights(moderationStatus: moderationStatus);
  @override
  Future<AdminPage<AdminReport>> reports({
    String status = 'open',
    int page = 1,
  }) => _api.reports(status: status, page: page);
  @override
  Future<AdminReport> updateReport(
    String id,
    String status, {
    String adminNote = '',
  }) => _api.updateReport(id, status, adminNote: adminNote);
  @override
  Future<AdminPage<AdminPayment>> payments({String query = '', int page = 1}) =>
      _api.payments(query: query, page: page);
  @override
  Future<Map<String, dynamic>> analyticsSummary(AdminRange range) =>
      _api.analyticsSummary(range);
  @override
  Future<AdminAnalytics24h> analytics24h() => _api.analytics24h();
  @override
  Future<AdminHeatmap> heatmap({String metric = 'events'}) =>
      _api.heatmap(metric: metric);
  @override
  Future<AdminAiReport> generateAiReport(AdminRange range) =>
      _api.generateAiReport(range);
}

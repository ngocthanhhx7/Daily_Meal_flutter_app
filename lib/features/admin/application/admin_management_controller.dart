import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter/foundation.dart';

class AdminManagementController extends ChangeNotifier {
  AdminManagementController(this._repository);
  final AdminRepositoryContract _repository;

  bool loading = false, mutating = false;
  String query = '', reportStatus = 'open';
  String? moderationStatus, errorMessage;
  AdminPage<AdminUser>? userPage;
  AdminPage<AdminPost>? postPage;
  AdminPage<AdminReport>? reportPage;
  AdminPage<AdminPayment>? paymentPage;
  Map<String, dynamic>? userInsights, selectedUserDetail, postInsights;

  Future<void> loadUsers({int page = 1, String? search}) => _run(() async {
    if (search != null) query = search.trim();
    userPage = await _repository.users(query: query, page: page);
    userInsights ??= await _repository.userInsights(AdminRange.thirtyDays);
  });
  Future<void> loadPosts({
    int page = 1,
    String? search,
    String? status,
    bool clearStatus = false,
  }) => _run(() async {
    if (search != null) query = search.trim();
    if (clearStatus) {
      moderationStatus = null;
    } else if (status != null) {
      moderationStatus = status;
    }
    postPage = await _repository.posts(
      query: query,
      page: page,
      moderationStatus: moderationStatus,
    );
    postInsights = await _repository.postInsights(
      moderationStatus: moderationStatus,
    );
  });
  Future<void> loadReports({int page = 1, String? status}) => _run(() async {
    if (status != null) reportStatus = status;
    reportPage = await _repository.reports(status: reportStatus, page: page);
  });
  Future<void> loadPayments({int page = 1, String? search}) => _run(() async {
    if (search != null) query = search.trim();
    paymentPage = await _repository.payments(query: query, page: page);
  });

  Future<void> setPremium(AdminUser user, bool value, {String note = ''}) =>
      _mutate(() async {
        final updated = await _repository.setPremium(
          user.id,
          value,
          note: note,
        );
        userPage = _replace(userPage, updated, (item) => item.id);
      });
  Future<void> loadUserDetail(String id) => _run(() async {
    selectedUserDetail = await _repository.userDetail(id);
  });
  Future<void> moderate(AdminPost post, String status, {String reason = ''}) =>
      _mutate(() async {
        final updated = await _repository.moderatePost(
          post.id,
          status,
          reason: reason,
        );
        postPage = _replace(postPage, updated, (item) => item.id);
      });
  Future<void> resolve(AdminReport report, String status, {String note = ''}) =>
      _mutate(() async {
        final updated = await _repository.updateReport(
          report.id,
          status,
          adminNote: note,
        );
        if (reportStatus == 'all' || reportStatus == status) {
          reportPage = _replace(reportPage, updated, (item) => item.id);
        } else {
          final current = reportPage;
          if (current != null) {
            reportPage = AdminPage(
              items: current.items.where((e) => e.id != report.id).toList(),
              page: current.page,
              pages: current.pages,
              total: current.total - 1,
            );
          }
        }
      });

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    mutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      mutating = false;
      notifyListeners();
    }
  }

  static AdminPage<T>? _replace<T>(
    AdminPage<T>? page,
    T updated,
    String Function(T) id,
  ) => page == null
      ? null
      : AdminPage(
          items: [
            for (final item in page.items)
              if (id(item) == id(updated)) updated else item,
          ],
          page: page.page,
          pages: page.pages,
          total: page.total,
        );
}

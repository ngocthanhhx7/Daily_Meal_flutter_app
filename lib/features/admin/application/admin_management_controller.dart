import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter/foundation.dart';

class AdminManagementController extends ChangeNotifier {
  AdminManagementController(this._repository);
  final AdminRepositoryContract _repository;

  bool loading = false;
  final Set<String> _mutatingIds = <String>{};
  bool get mutating => _mutatingIds.isNotEmpty;
  bool isMutating(String id) => _mutatingIds.contains(id);
  String userQuery = '', postQuery = '', paymentQuery = '';
  String reportStatus = 'open';
  String? moderationStatus, errorMessage;
  AdminRange postRange = AdminRange.sevenDays;
  String postMediaKind = 'all',
      postSortBy = 'createdAt',
      postSortOrder = 'desc';
  String? postStart, postEnd;
  AdminPage<AdminUser>? userPage;
  AdminPage<AdminPost>? postPage;
  AdminPage<AdminReport>? reportPage;
  AdminPage<AdminPayment>? paymentPage;
  Map<String, dynamic>? userInsights, selectedUserDetail, postInsights;

  Future<void> loadUsers({int page = 1, String? search}) => _run(() async {
    if (search != null) userQuery = search.trim();
    userPage = await _repository.users(query: userQuery, page: page);
    userInsights ??= await _repository.userInsights(AdminRange.thirtyDays);
  });
  Future<void> loadPosts({
    int page = 1,
    String? search,
    String? status,
    bool clearStatus = false,
    AdminRange? range,
    String? mediaKind,
    String? sortBy,
    String? sortOrder,
    String? start,
    String? end,
    bool clearDates = false,
  }) => _run(() async {
    if (search != null) postQuery = search.trim();
    if (clearStatus) {
      moderationStatus = null;
    } else if (status != null) {
      moderationStatus = status;
    }
    if (range != null) postRange = range;
    if (mediaKind != null) postMediaKind = mediaKind;
    if (sortBy != null) postSortBy = sortBy;
    if (sortOrder != null) postSortOrder = sortOrder;
    if (clearDates) {
      postStart = null;
      postEnd = null;
    } else {
      if (start != null) postStart = start;
      if (end != null) postEnd = end;
    }
    postPage = await _repository.posts(
      query: postQuery,
      page: page,
      moderationStatus: moderationStatus,
      range: postRange,
      mediaKind: postMediaKind,
      sortBy: postSortBy,
      sortOrder: postSortOrder,
      start: postStart,
      end: postEnd,
    );
    postInsights = await _repository.postInsights(
      query: postQuery,
      moderationStatus: moderationStatus,
      range: postRange,
      mediaKind: postMediaKind,
      sortBy: postSortBy,
      sortOrder: postSortOrder,
      start: postStart,
      end: postEnd,
    );
  });
  Future<void> loadReports({int page = 1, String? status}) => _run(() async {
    if (status != null) reportStatus = status;
    reportPage = await _repository.reports(status: reportStatus, page: page);
  });
  Future<void> loadPayments({int page = 1, String? search}) => _run(() async {
    if (search != null) paymentQuery = search.trim();
    paymentPage = await _repository.payments(query: paymentQuery, page: page);
  });

  Future<void> setPremium(AdminUser user, bool value, {String note = ''}) =>
      _mutate(user.id, () async {
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
      _mutate(post.id, () async {
        final updated = await _repository.moderatePost(
          post.id,
          status,
          reason: reason,
        );
        postPage = _replace(postPage, updated, (item) => item.id);
      });
  Future<void> resolve(AdminReport report, String status, {String note = ''}) =>
      _mutate(report.id, () async {
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

  Future<void> _mutate(String id, Future<void> Function() action) async {
    _mutatingIds.add(id);
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      _mutatingIds.remove(id);
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

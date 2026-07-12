import 'dart:async';

import 'package:daily_meal_flutter_app/features/admin/application/admin_management_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AdminRepositoryContract {
  final premium = <String, Completer<AdminUser>>{};

  @override
  Future<AdminUser> setPremium(String id, bool value, {String note = ''}) {
    final completer = Completer<AdminUser>();
    premium[id] = completer;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FilterRepository implements AdminRepositoryContract {
  String? userQuery, postQuery, paymentQuery;
  AdminRange? postRange;
  String? postStatus, postMediaKind, postSortBy, postSortOrder;
  String? postStart, postEnd;
  var insightCalls = 0;

  @override
  Future<AdminPage<AdminUser>> users({String query = '', int page = 1}) async {
    userQuery = query;
    return const AdminPage(items: [], page: 1, pages: 1, total: 0);
  }

  @override
  Future<Map<String, dynamic>> userInsights(AdminRange range) async => {};

  @override
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
  }) async {
    postQuery = query;
    postRange = range;
    postStatus = moderationStatus;
    postMediaKind = mediaKind;
    postSortBy = sortBy;
    postSortOrder = sortOrder;
    postStart = start;
    postEnd = end;
    return const AdminPage(items: [], page: 1, pages: 1, total: 0);
  }

  @override
  Future<Map<String, dynamic>> postInsights({
    String query = '',
    String? moderationStatus,
    AdminRange range = AdminRange.sevenDays,
    String mediaKind = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? start,
    String? end,
  }) async {
    insightCalls++;
    expect(query, postQuery);
    expect(range, postRange);
    expect(moderationStatus, postStatus);
    expect(mediaKind, postMediaKind);
    expect(sortBy, postSortBy);
    expect(sortOrder, postSortOrder);
    expect(start, postStart);
    expect(end, postEnd);
    return {};
  }

  @override
  Future<AdminPage<AdminPayment>> payments({
    String query = '',
    int page = 1,
  }) async {
    paymentQuery = query;
    return const AdminPage(items: [], page: 1, pages: 1, total: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'keeps management queries isolated and forwards all post filters',
    () async {
      final repository = _FilterRepository();
      final controller = AdminManagementController(repository);

      await controller.loadUsers(search: 'alice');
      await controller.loadPosts(
        search: 'salad',
        status: 'review',
        range: AdminRange.thirtyDays,
        mediaKind: 'multi_image',
        sortBy: 'interactions',
        sortOrder: 'asc',
        start: '2026-07-01T00:00:00.000Z',
        end: '2026-07-12T23:59:59.999Z',
      );
      await controller.loadPayments(search: 'PAY-001');

      expect(repository.userQuery, 'alice');
      expect(repository.postQuery, 'salad');
      expect(repository.paymentQuery, 'PAY-001');
      expect(repository.postStatus, 'review');
      expect(repository.postRange, AdminRange.thirtyDays);
      expect(repository.postMediaKind, 'multi_image');
      expect(repository.postSortBy, 'interactions');
      expect(repository.postSortOrder, 'asc');
      expect(repository.postStart, '2026-07-01T00:00:00.000Z');
      expect(repository.postEnd, '2026-07-12T23:59:59.999Z');
      expect(repository.insightCalls, 1);
    },
  );

  test('tracks mutations per row instead of locking the whole table', () async {
    final repository = _Repository();
    final controller = AdminManagementController(repository);
    const first = AdminUser(id: 'u1', name: 'An');
    const second = AdminUser(id: 'u2', name: 'Bình');
    controller.userPage = const AdminPage(
      items: [first, second],
      page: 1,
      pages: 1,
      total: 2,
    );

    final firstMutation = controller.setPremium(first, true);
    expect(controller.isMutating(first.id), isTrue);
    expect(controller.isMutating(second.id), isFalse);

    final secondMutation = controller.setPremium(second, true);
    expect(controller.isMutating(first.id), isTrue);
    expect(controller.isMutating(second.id), isTrue);

    repository.premium['u1']!.complete(
      const AdminUser(id: 'u1', name: 'An', isPremium: true),
    );
    await firstMutation;
    expect(controller.isMutating(first.id), isFalse);
    expect(controller.isMutating(second.id), isTrue);

    repository.premium['u2']!.complete(
      const AdminUser(id: 'u2', name: 'Bình', isPremium: true),
    );
    await secondMutation;
    expect(controller.isMutating(second.id), isFalse);
    expect(controller.mutating, isFalse);
  });
}

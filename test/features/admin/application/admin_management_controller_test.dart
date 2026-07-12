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

void main() {
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

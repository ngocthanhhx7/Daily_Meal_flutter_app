import 'package:daily_meal_flutter_app/features/admin/application/admin_dashboard_controller.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AdminRepositoryContract {
  final calls = <AdminRange>[];
  @override
  Future<AdminDashboard> dashboard(AdminRange range) async {
    calls.add(range);
    return AdminDashboard(
      range: range.wireValue,
      allTime: const AdminTotals(users: 10),
      inRange: const AdminTotals(users: 2),
      today: const AdminToday(users: 1),
      daily: const [],
      breakdowns: const AdminBreakdowns(),
      recent: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('changes range and reconciles dashboard result', () async {
    final repository = _Repository();
    final controller = AdminDashboardController(repository);
    await controller.load(selectedRange: AdminRange.thirtyDays);
    expect(repository.calls, [AdminRange.thirtyDays]);
    expect(controller.range, AdminRange.thirtyDays);
    expect(controller.dashboard?.inRange.users, 2);
    expect(controller.loading, isFalse);
    expect(controller.errorMessage, isNull);
  });
}

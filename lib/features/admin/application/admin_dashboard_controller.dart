import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/features/admin/data/admin_repository.dart';
import 'package:daily_meal_flutter_app/features/admin/domain/admin_models.dart';
import 'package:flutter/foundation.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(this._repository);
  final AdminRepositoryContract _repository;

  AdminRange range = AdminRange.sevenDays;
  AdminDashboard? dashboard;
  bool loading = false;
  String? errorMessage;

  Future<void> load({AdminRange? selectedRange}) async {
    if (selectedRange != null) range = selectedRange;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboard = await _repository.dashboard(range);
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

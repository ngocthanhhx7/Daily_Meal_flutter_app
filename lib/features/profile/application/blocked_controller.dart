import 'package:daily_meal_flutter_app/features/profile/data/profile_repository.dart';
import 'package:daily_meal_flutter_app/features/search/domain/public_user.dart';
import 'package:flutter/foundation.dart';

class BlockedController extends ChangeNotifier {
  BlockedController(this._repository);
  final ProfileRepositoryContract _repository;
  List<PublicUser> users = const [];
  bool loading = false;
  String? errorMessage;
  final Set<String> _busy = {};
  bool isBusy(String id) => _busy.contains(id);

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      users = await _repository.loadBlockedUsers();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> unblock(String userId) async {
    if (!_busy.add(userId)) return;
    final previous = users;
    users = users.where((user) => user.id != userId).toList(growable: false);
    notifyListeners();
    try {
      await _repository.setInteraction(userId, 'block', active: false);
    } catch (error) {
      users = previous;
      errorMessage = error.toString();
      rethrow;
    } finally {
      _busy.remove(userId);
      notifyListeners();
    }
  }
}

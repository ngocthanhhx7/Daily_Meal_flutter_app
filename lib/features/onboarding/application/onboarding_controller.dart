import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter/foundation.dart';

enum OnboardingStep { interests, eatingStyles }

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._repository, this._auth);

  final OnboardingRepository _repository;
  final AuthController _auth;
  final Set<String> _interests = {};
  final Set<String> _eatingStyles = {};
  OnboardingStep step = OnboardingStep.interests;
  bool isBusy = false;
  String? errorMessage;

  Set<String> get interests => Set.unmodifiable(_interests);
  Set<String> get eatingStyles => Set.unmodifiable(_eatingStyles);

  void toggleInterest(String value) => _toggle(_interests, value);
  void toggleEatingStyle(String value) => _toggle(_eatingStyles, value);

  void next() {
    step = OnboardingStep.eatingStyles;
    notifyListeners();
  }

  void back() {
    step = OnboardingStep.interests;
    notifyListeners();
  }

  Future<void> complete() async {
    final user = _auth.state.user;
    if (user == null) {
      errorMessage = 'Phiên đăng nhập không hợp lệ.';
      notifyListeners();
      return;
    }
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final preferences = await _repository.savePreferences(
        interests: _interests.toList(growable: false),
        eatingStyles: _eatingStyles.toList(growable: false),
      );
      _auth.updateUser(user.withPreferences(preferences));
    } catch (_) {
      errorMessage = 'Không thể lưu sở thích. Vui lòng thử lại.';
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _toggle(Set<String> values, String value) {
    if (!values.remove(value) && values.length < 10) {
      values.add(value);
    }
    notifyListeners();
  }
}

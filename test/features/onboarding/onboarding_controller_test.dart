import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_controller.dart';
import 'package:daily_meal_flutter_app/features/onboarding/data/onboarding_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthRepository implements AuthRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OnboardingRepository extends OnboardingRepository {
  _OnboardingRepository() : super(Dio());

  @override
  Future<UserPreferences> savePreferences({
    required List<String> interests,
    required List<String> eatingStyles,
  }) async => UserPreferences(
    interests: interests,
    eatingStyles: eatingStyles,
    completedOnboarding: true,
  );
}

AppUser initialUser() => AppUser.fromJson({
  'id': 'user-1',
  'displayName': 'Meal',
  'isPremium': false,
  'preferences': {
    'interests': <String>[],
    'eatingStyles': <String>[],
    'completedOnboarding': false,
  },
});

void main() {
  test('toggles choices and completes onboarding into user state', () async {
    final auth = AuthController(_AuthRepository())..updateUser(initialUser());
    final controller = OnboardingController(_OnboardingRepository(), auth);

    controller.toggleInterest('Thích ăn uống');
    controller.toggleEatingStyle('Chế độ keto');
    await controller.complete();

    expect(auth.state.status, AuthStatus.user);
    expect(auth.state.user?.preferences.interests, ['Thích ăn uống']);
  });
}

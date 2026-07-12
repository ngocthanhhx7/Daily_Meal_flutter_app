import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/onboarding/application/onboarding_controller.dart';
import 'package:daily_meal_flutter_app/features/onboarding/data/onboarding_repository.dart';
import 'package:daily_meal_flutter_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

void main() {
  testWidgets('completes the two-step preference flow', (tester) async {
    final auth = AuthController(_AuthRepository())
      ..updateUser(
        AppUser.fromJson({
          'id': 'user-1',
          'displayName': 'Meal',
          'preferences': {'completedOnboarding': false},
        }),
      );
    final controller = OnboardingController(_OnboardingRepository(), auth);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: OnboardingScreen(controller: controller)),
      ),
    );

    expect(find.text('Chào bạn!!'), findsOneWidget);
    await tester.tap(find.text('Thích ăn uống'));
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pump();

    expect(find.text('Phong cách ăn'), findsOneWidget);
    await tester.tap(find.text('Chế độ keto'));
    await tester.tap(find.widgetWithText(FilledButton, 'Vào Daily Meal'));
    await tester.pumpAndSettle();

    expect(auth.state.user!.preferences.completedOnboarding, isTrue);
    expect(auth.state.user!.preferences.interests, ['Thích ăn uống']);
    expect(auth.state.user!.preferences.eatingStyles, ['Chế độ keto']);
  });
}

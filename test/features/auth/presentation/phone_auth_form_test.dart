import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/phone_auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PhoneRepository implements AuthRepositoryContract {
  int requests = 0;
  int verifications = 0;

  AppUser get _user => AppUser.fromJson({
    'id': 'phone-user',
    'phone': '+84901234567',
    'displayName': 'Chef',
    'isPremium': false,
    'preferences': {
      'interests': <String>[],
      'eatingStyles': <String>[],
      'completedOnboarding': true,
    },
  });

  @override
  Future<PhoneOtpResponse> requestPhoneOtp(String phone) async {
    requests++;
    return const PhoneOtpResponse(requiresPasswordSetup: true);
  }

  @override
  Future<AppUser> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? password,
    String? displayName,
  }) async {
    verifications++;
    expect(password, '123456');
    expect(displayName, 'Chef');
    return _user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('requests OTP then requires first-time password and name', (
    tester,
  ) async {
    final repository = _PhoneRepository();
    final controller = AuthController(repository);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PhoneAuthForm(controller: controller)),
      ),
    );

    await tester.enterText(
      find.byKey(PhoneAuthForm.phoneFieldKey),
      '+84901234567',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi OTP'));
    await tester.pumpAndSettle();

    expect(repository.requests, 1);
    expect(find.byKey(PhoneAuthForm.otpFieldKey), findsOneWidget);
    expect(find.byKey(PhoneAuthForm.passwordFieldKey), findsOneWidget);
    expect(find.byKey(PhoneAuthForm.displayNameFieldKey), findsOneWidget);

    await tester.enterText(find.byKey(PhoneAuthForm.otpFieldKey), '123456');
    await tester.enterText(
      find.byKey(PhoneAuthForm.passwordFieldKey),
      '123456',
    );
    await tester.enterText(
      find.byKey(PhoneAuthForm.displayNameFieldKey),
      'Chef',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận OTP'));
    await tester.pumpAndSettle();

    expect(repository.verifications, 1);
    expect(controller.state.status, AuthStatus.user);
  });
}

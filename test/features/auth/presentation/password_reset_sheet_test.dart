import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/password_reset_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ResetRepository implements AuthRepositoryContract {
  int requests = 0;
  int verifications = 0;

  @override
  Future<OtpRequestResponse> requestPasswordResetOtp(String email) async {
    requests++;
    return const OtpRequestResponse(message: 'sent');
  }

  @override
  Future<AppUser> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    verifications++;
    return AppUser.fromJson({
      'id': 'user-1',
      'email': email,
      'displayName': 'Meal',
      'isPremium': false,
      'preferences': {
        'interests': <String>[],
        'eatingStyles': <String>[],
        'completedOnboarding': true,
      },
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('requests then verifies email OTP and new password', (
    tester,
  ) async {
    final repository = _ResetRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordResetSheet(controller: AuthController(repository)),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(PasswordResetSheet.emailFieldKey),
      'meal@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi OTP'));
    await tester.pumpAndSettle();
    expect(repository.requests, 1);

    await tester.enterText(
      find.byKey(PasswordResetSheet.otpFieldKey),
      '123456',
    );
    await tester.enterText(
      find.byKey(PasswordResetSheet.newPasswordFieldKey),
      '12345678',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận OTP'));
    await tester.pumpAndSettle();

    expect(repository.verifications, 1);
  });
}

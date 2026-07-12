import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/login_screen.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/phone_auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser onboardedUser() => AppUser.fromJson({
  'id': 'user-1',
  'email': 'meal@example.com',
  'displayName': 'Meal',
  'isPremium': false,
  'preferences': {
    'interests': <String>[],
    'eatingStyles': <String>[],
    'completedOnboarding': true,
  },
});

class _Repository implements AuthRepositoryContract {
  int loginCalls = 0;
  int registerCalls = 0;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return onboardedUser();
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    registerCalls++;
    return onboardedUser();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('validates email before calling the repository', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: AuthController(repository))),
    );

    await tester.enterText(find.byKey(LoginScreen.emailFieldKey), 'bad-email');
    await tester.enterText(find.byKey(LoginScreen.passwordFieldKey), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập đúng định dạng email.'), findsOneWidget);
    expect(repository.loginCalls, 0);
  });

  testWidgets('submits email login and reaches authenticated state', (
    tester,
  ) async {
    final repository = _Repository();
    final controller = AuthController(repository);
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: controller)),
    );

    await tester.enterText(
      find.byKey(LoginScreen.emailFieldKey),
      'meal@example.com',
    );
    await tester.enterText(find.byKey(LoginScreen.passwordFieldKey), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(controller.state.status, AuthStatus.user);
  });

  testWidgets('switches to registration and shows display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: AuthController(_Repository()))),
    );

    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pump();

    expect(find.byKey(LoginScreen.displayNameFieldKey), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tạo tài khoản'), findsOneWidget);
  });

  testWidgets('switches from email to phone authentication', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: AuthController(_Repository()))),
    );

    await tester.tap(find.text('Số điện thoại'));
    await tester.pump();

    expect(find.byKey(PhoneAuthForm.phoneFieldKey), findsOneWidget);
    expect(find.byKey(LoginScreen.emailFieldKey), findsNothing);
  });

  testWidgets('moves keyboard focus from email to password with Tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: AuthController(_Repository()))),
    );

    await tester.tap(find.byKey(LoginScreen.emailFieldKey));
    await tester.pump();
    final emailEditable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(LoginScreen.emailFieldKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(emailEditable.focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final passwordEditable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(LoginScreen.passwordFieldKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordEditable.focusNode.hasFocus, isTrue);
  });
}

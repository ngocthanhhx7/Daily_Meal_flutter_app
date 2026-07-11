import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
import 'package:daily_meal_flutter_app/features/auth/presentation/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements AuthRepositoryContract {
  String? email;
  String? password;

  @override
  Future<AdminAuthResult> adminLogin({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    return const AdminAuthResult(
      token: 'admin-token',
      email: 'admin@dailymeal.site',
      displayName: 'Admin',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('validates and submits administrator credentials', (
    tester,
  ) async {
    final repository = _Repository();
    final controller = AuthController(repository);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AdminLoginScreen(controller: controller)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập admin'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);

    await tester.enterText(
      find.byKey(AdminLoginScreen.emailFieldKey),
      ' admin@dailymeal.site ',
    );
    await tester.enterText(
      find.byKey(AdminLoginScreen.passwordFieldKey),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập admin'));
    await tester.pumpAndSettle();

    expect(repository.email, 'admin@dailymeal.site');
    expect(repository.password, 'secret123');
    expect(controller.state.status, AuthStatus.admin);
  });
}

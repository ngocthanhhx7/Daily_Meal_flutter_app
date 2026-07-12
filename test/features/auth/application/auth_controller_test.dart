import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser user({bool onboarded = false}) => AppUser.fromJson({
  'id': 'user-1',
  'email': 'meal@example.com',
  'displayName': 'Meal',
  'isPremium': false,
  'preferences': {
    'interests': <String>[],
    'eatingStyles': <String>[],
    'completedOnboarding': onboarded,
  },
});

class _Repository implements AuthRepositoryContract {
  Session? adminSession;
  Session? userSession;
  bool adminValid = true;
  bool userValid = true;
  final cleared = <SessionKind>[];

  @override
  Future<Session?> readSession(SessionKind kind) async =>
      kind == SessionKind.admin ? adminSession : userSession;

  @override
  Future<void> validateAdmin() async {
    if (!adminValid) throw StateError('invalid admin');
  }

  @override
  Future<AppUser> currentUser() async {
    if (!userValid) throw StateError('invalid user');
    return user();
  }

  @override
  Future<void> clear(SessionKind kind) async => cleared.add(kind);

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async => user(onboarded: true);

  @override
  Future<AdminAuthResult> adminLogin({
    required String email,
    required String password,
  }) async => const AdminAuthResult(
    token: 'admin-token',
    email: 'admin@dailymeal.site',
    displayName: 'Admin',
  );

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('restores a valid admin before considering user session', () async {
    final repository = _Repository()
      ..adminSession = const Session.admin(
        token: 'admin-token',
        subjectId: 'admin@dailymeal.site',
      )
      ..userSession = const Session.user(
        token: 'user-token',
        subjectId: 'user-1',
      );
    final controller = AuthController(repository);

    await controller.restore();

    expect(controller.state.status, AuthStatus.admin);
    expect(repository.cleared, isEmpty);
  });

  test('clears invalid admin then restores a valid user', () async {
    final repository = _Repository()
      ..adminSession = const Session.admin(token: 'bad', subjectId: 'admin')
      ..userSession = const Session.user(
        token: 'user-token',
        subjectId: 'user-1',
      )
      ..adminValid = false;
    final controller = AuthController(repository);

    await controller.restore();

    expect(repository.cleared, [SessionKind.admin]);
    expect(controller.state.status, AuthStatus.needsOnboarding);
  });

  test('clears an invalid user and becomes signed out', () async {
    final repository = _Repository()
      ..userSession = const Session.user(token: 'bad', subjectId: 'user-1')
      ..userValid = false;
    final controller = AuthController(repository);

    await controller.restore();

    expect(repository.cleared, [SessionKind.user]);
    expect(controller.state.status, AuthStatus.signedOut);
  });

  test(
    'login derives the onboarded route state and logout signs out',
    () async {
      final controller = AuthController(_Repository());

      await controller.login(email: 'meal@example.com', password: '123456');
      expect(controller.state.status, AuthStatus.user);

      await controller.logout();
      expect(controller.state.status, AuthStatus.signedOut);
    },
  );
}

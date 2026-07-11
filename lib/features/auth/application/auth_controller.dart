import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepositoryContract _repository;
  AuthState _state = const AuthState.loading();

  AuthState get state => _state;
  Future<void> restored = Future.value();

  void startRestore() {
    restored = restore();
  }

  Future<void> restore() async {
    _setState(const AuthState.loading());
    final adminSession = await _repository.readSession(SessionKind.admin);
    if (adminSession != null) {
      try {
        await _repository.validateAdmin();
        _setState(
          AuthState(
            status: AuthStatus.admin,
            adminEmail: adminSession.subjectId,
          ),
        );
        return;
      } catch (_) {
        await _repository.clear(SessionKind.admin);
      }
    }

    final userSession = await _repository.readSession(SessionKind.user);
    if (userSession != null) {
      try {
        _setAuthenticatedUser(await _repository.currentUser());
        return;
      } catch (_) {
        await _repository.clear(SessionKind.user);
      }
    }
    _setState(const AuthState.signedOut());
  }

  Future<void> login({required String email, required String password}) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(
        await _repository.login(email: email, password: password),
      );
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      final admin = await _repository.adminLogin(
        email: email,
        password: password,
      );
      _setState(AuthState(status: AuthStatus.admin, adminEmail: admin.email));
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _setState(const AuthState.signedOut());
  }

  void updateUser(AppUser user) => _setAuthenticatedUser(user);

  void _setAuthenticatedUser(AppUser user) {
    _setState(
      AuthState(
        status: user.preferences.completedOnboarding
            ? AuthStatus.user
            : AuthStatus.needsOnboarding,
        user: user,
      ),
    );
  }

  void _setState(AuthState next) {
    _state = next;
    notifyListeners();
  }
}

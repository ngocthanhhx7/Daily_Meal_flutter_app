import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_state.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
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

  Future<void> loginWithGoogle(String idToken) =>
      _socialLogin(() => _repository.loginWithGoogle(idToken));

  Future<void> loginWithFacebook(String accessToken) =>
      _socialLogin(() => _repository.loginWithFacebook(accessToken));

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(
        await _repository.register(
          email: email,
          password: password,
          displayName: displayName,
        ),
      );
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> requestPasswordResetOtp(String email) async {
    await _repository.requestPasswordResetOtp(email);
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(
        await _repository.verifyPasswordResetOtp(
          email: email,
          otp: otp,
          newPassword: newPassword,
        ),
      );
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<PhoneOtpResponse> requestPhoneOtp(String phone) =>
      _repository.requestPhoneOtp(phone);

  Future<void> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? password,
    String? displayName,
  }) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(
        await _repository.verifyPhoneOtp(
          phone: phone,
          otp: otp,
          password: password,
          displayName: displayName,
        ),
      );
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(
        await _repository.loginWithPhone(phone: phone, password: password),
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

  Future<void> _socialLogin(Future<AppUser> Function() authenticate) async {
    _setState(const AuthState(status: AuthStatus.signedOut, isBusy: true));
    try {
      _setAuthenticatedUser(await authenticate());
    } catch (error) {
      _setState(AuthState.signedOut(errorMessage: error.toString()));
      rethrow;
    }
  }

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

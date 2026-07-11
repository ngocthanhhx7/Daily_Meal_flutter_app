import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_api.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';

class AuthRepository {
  AuthRepository(this._api, this._sessions);

  final AuthApi _api;
  final SessionStore _sessions;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async => _persistUser(await _api.login(email: email, password: password));

  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async => _persistUser(
    await _api.register(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  Future<AppUser> loginWithPhone({
    required String phone,
    required String password,
  }) async =>
      _persistUser(await _api.loginWithPhone(phone: phone, password: password));

  Future<AppUser> registerWithPhone({
    required String phone,
    required String password,
    String? displayName,
  }) async => _persistUser(
    await _api.registerWithPhone(
      phone: phone,
      password: password,
      displayName: displayName,
    ),
  );

  Future<PhoneOtpResponse> requestPhoneOtp(String phone) =>
      _api.requestPhoneOtp(phone);

  Future<AppUser> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? password,
    String? displayName,
  }) async => _persistUser(
    await _api.verifyPhoneOtp(
      phone: phone,
      otp: otp,
      password: password,
      displayName: displayName,
    ),
  );

  Future<OtpRequestResponse> requestPasswordResetOtp(String email) =>
      _api.requestPasswordResetOtp(email);

  Future<AppUser> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async => _persistUser(
    await _api.verifyPasswordResetOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    ),
  );

  Future<AppUser> loginWithGoogle(String idToken) async =>
      _persistUser(await _api.loginWithGoogle(idToken));

  Future<AppUser> loginWithFacebook(String accessToken) async =>
      _persistUser(await _api.loginWithFacebook(accessToken));

  Future<AppUser> linkGoogle(String idToken) => _api.linkGoogle(idToken);

  Future<AdminAuthResult> adminLogin({
    required String email,
    required String password,
  }) async {
    final result = await _api.adminLogin(email: email, password: password);
    await _sessions.save(
      Session.admin(token: result.token, subjectId: result.email),
    );
    await _sessions.clear(SessionKind.user);
    return result;
  }

  Future<Session?> readSession(SessionKind kind) => _sessions.read(kind);

  Future<void> validateAdmin() => _api.validateAdmin();

  Future<AppUser> currentUser() => _api.me();

  Future<void> clear(SessionKind kind) => _sessions.clear(kind);

  Future<void> logout() async {
    await _sessions.clear(SessionKind.user);
    await _sessions.clear(SessionKind.admin);
  }

  Future<AppUser> _persistUser(AuthResult result) async {
    await _sessions.save(
      Session.user(token: result.token, subjectId: result.user.id),
    );
    await _sessions.clear(SessionKind.admin);
    return result.user;
  }
}

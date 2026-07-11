import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/auth_result.dart';
import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<AuthResult> login({required String email, required String password}) =>
      _authPost('/api/auth/login', {'email': email, 'password': password});

  Future<AuthResult> register({
    required String email,
    required String password,
    String? displayName,
  }) => _authPost('/api/auth/register', {
    'email': email,
    'password': password,
    'displayName': ?displayName,
  });

  Future<AuthResult> registerWithPhone({
    required String phone,
    required String password,
    String? displayName,
  }) => _authPost('/api/auth/phone/register', {
    'phone': phone,
    'password': password,
    'displayName': ?displayName,
  });

  Future<AuthResult> loginWithPhone({
    required String phone,
    required String password,
  }) => _authPost('/api/auth/phone/login', {
    'phone': phone,
    'password': password,
  });

  Future<PhoneOtpResponse> requestPhoneOtp(String phone) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/phone/request-otp',
      data: {'phone': phone},
    );
    return PhoneOtpResponse.fromJson(_data(response));
  }

  Future<AuthResult> verifyPhoneOtp({
    required String phone,
    required String otp,
    String? password,
    String? displayName,
  }) => _authPost('/api/auth/phone/verify-otp', {
    'phone': phone,
    'otp': otp,
    'password': ?password,
    'displayName': ?displayName,
  });

  Future<OtpRequestResponse> requestPasswordResetOtp(String email) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/password/forgot/request-otp',
      data: {'email': email},
    );
    return OtpRequestResponse.fromJson(_data(response));
  }

  Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) => _authPost('/api/auth/password/forgot/verify-otp', {
    'email': email,
    'otp': otp,
    'newPassword': newPassword,
  });

  Future<AuthResult> loginWithFacebook(String accessToken) =>
      _authPost('/api/auth/facebook', {'accessToken': accessToken});

  Future<AuthResult> loginWithGoogle(String idToken) =>
      _authPost('/api/auth/google', {'idToken': idToken});

  Future<AppUser> linkGoogle(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/google/link',
      data: {'idToken': idToken},
    );
    return AppUser.fromJson(_data(response)['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    return AppUser.fromJson(_data(response)['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _dio.patch<void>(
    '/api/auth/password',
    data: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );

  Future<AdminAuthResult> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin/login',
      data: {'email': email, 'password': password},
    );
    return AdminAuthResult.fromJson(_data(response));
  }

  Future<void> validateAdmin() async {
    await _dio.get<void>('/api/admin/dashboard');
  }

  Future<AuthResult> _authPost(String path, Map<String, Object?> body) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return AuthResult.fromJson(_data(response));
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Missing response body');
    return data;
  }
}

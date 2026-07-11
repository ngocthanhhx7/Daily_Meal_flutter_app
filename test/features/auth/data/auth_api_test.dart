import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const userJson = {
  'id': 'user-1',
  'email': 'meal@example.com',
  'displayName': 'Meal',
  'isPremium': false,
  'preferences': {
    'interests': <String>[],
    'eatingStyles': <String>[],
    'completedOnboarding': false,
  },
};

class _ContractAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    final Object body = switch (path) {
      '/api/auth/phone/request-otp' => {
        'message': 'sent',
        'requiresPasswordSetup': true,
      },
      '/api/auth/password/forgot/request-otp' => {'message': 'sent'},
      '/api/admin/login' => {
        'token': 'admin-token',
        'admin': {'email': 'admin@dailymeal.site', 'displayName': 'Admin'},
      },
      '/api/auth/me' || '/api/auth/google/link' => {'user': userJson},
      _ => {'token': 'user-token', 'user': userJson},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _ContractAdapter adapter;
  late AuthApi api;

  setUp(() {
    adapter = _ContractAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
      ..httpClientAdapter = adapter;
    api = AuthApi(dio);
  });

  test('uses exact email login and register contracts', () async {
    await api.login(email: 'meal@example.com', password: '123456');
    await api.register(
      email: 'meal@example.com',
      password: '123456',
      displayName: 'Meal',
    );

    expect(adapter.requests[0].path, '/api/auth/login');
    expect(adapter.requests[0].data, {
      'email': 'meal@example.com',
      'password': '123456',
    });
    expect(adapter.requests[1].path, '/api/auth/register');
    expect(adapter.requests[1].data['displayName'], 'Meal');
  });

  test('uses exact phone OTP and login contracts', () async {
    final otp = await api.requestPhoneOtp('+84901234567');
    await api.verifyPhoneOtp(
      phone: '+84901234567',
      otp: '123456',
      password: '123456',
      displayName: 'Chef',
    );
    await api.loginWithPhone(phone: '+84901234567', password: '123456');

    expect(otp.requiresPasswordSetup, isTrue);
    expect(adapter.requests.map((request) => request.path), [
      '/api/auth/phone/request-otp',
      '/api/auth/phone/verify-otp',
      '/api/auth/phone/login',
    ]);
  });

  test('uses exact reset and social token contracts', () async {
    await api.requestPasswordResetOtp('meal@example.com');
    await api.verifyPasswordResetOtp(
      email: 'meal@example.com',
      otp: '123456',
      newPassword: '12345678',
    );
    await api.loginWithGoogle('google-id-token');
    await api.loginWithFacebook('facebook-access-token');
    await api.linkGoogle('google-link-token');

    expect(adapter.requests.map((request) => request.path), [
      '/api/auth/password/forgot/request-otp',
      '/api/auth/password/forgot/verify-otp',
      '/api/auth/google',
      '/api/auth/facebook',
      '/api/auth/google/link',
    ]);
    expect(adapter.requests[2].data, {'idToken': 'google-id-token'});
    expect(adapter.requests[3].data, {'accessToken': 'facebook-access-token'});
  });

  test('decodes current user and admin login envelopes', () async {
    final user = await api.me();
    final admin = await api.adminLogin(
      email: 'admin@dailymeal.site',
      password: 'secret',
    );

    expect(user.id, 'user-1');
    expect(admin.token, 'admin-token');
    expect(admin.email, 'admin@dailymeal.site');
  });
}

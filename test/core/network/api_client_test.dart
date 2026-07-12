import 'dart:typed_data';

import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:daily_meal_flutter_app/core/network/api_client.dart';
import 'package:daily_meal_flutter_app/core/network/auth_token_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TokenProvider implements AuthTokenProvider {
  _TokenProvider(this.token);
  final String? token;

  @override
  Future<String?> readToken() async => token;
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  int statusCode = 200;
  String responseBody = '{}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
    message: 'SocketException: internal-host.local',
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses the configured base URL and injects a bearer token', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient.create(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      tokenProvider: _TokenProvider('jwt-value'),
      adapter: adapter,
    );

    await client.dio.get<void>('/api/auth/me');

    expect(
      adapter.request?.uri.toString(),
      'https://api.dailymeal.site/api/auth/me',
    );
    expect(adapter.request?.headers['Authorization'], 'Bearer jwt-value');
  });

  test('omits Authorization when no token exists', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient.create(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      tokenProvider: _TokenProvider(null),
      adapter: adapter,
    );

    await client.dio.get<void>('/api/payments/premium/plans');

    expect(adapter.request?.headers, isNot(contains('Authorization')));
  });

  test('notifies the session boundary on a 401 response', () async {
    final adapter = _RecordingAdapter()..statusCode = 401;
    var unauthorizedCalls = 0;
    final client = ApiClient.create(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      tokenProvider: _TokenProvider('expired'),
      adapter: adapter,
      onUnauthorized: () async => unauthorizedCalls++,
    );

    await expectLater(
      client.dio.get<void>('/api/auth/me'),
      throwsA(
        isA<DioException>().having(
          (exception) => exception.error,
          'mapped error',
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            AppFailureKind.unauthorized,
          ),
        ),
      ),
    );
    expect(unauthorizedCalls, 1);
  });

  test('does not expire a session for an unauthenticated login 401', () async {
    final adapter = _RecordingAdapter()
      ..statusCode = 401
      ..responseBody = '{"message":"Email hoặc mật khẩu không đúng"}';
    var unauthorizedCalls = 0;
    final client = ApiClient.create(
      baseUrl: Uri.parse('https://api.dailymeal.site'),
      tokenProvider: _TokenProvider(null),
      adapter: adapter,
      onUnauthorized: () async => unauthorizedCalls++,
    );

    await expectLater(
      client.dio.post<void>(
        '/api/auth/login',
        data: {'email': 'meal@example.com', 'password': 'wrong'},
      ),
      throwsA(
        isA<DioException>().having(
          (exception) => exception.error,
          'mapped error',
          isA<AppFailure>()
              .having(
                (failure) => failure.kind,
                'kind',
                AppFailureKind.validation,
              )
              .having(
                (failure) => failure.userMessage,
                'message',
                'Email hoặc mật khẩu không đúng',
              ),
        ),
      ),
    );
    expect(unauthorizedCalls, 0);
  });

  test(
    'maps transport failures before they reach feature controllers',
    () async {
      final client = ApiClient.create(
        baseUrl: Uri.parse('https://api.dailymeal.site'),
        tokenProvider: _TokenProvider(null),
        adapter: _OfflineAdapter(),
      );

      await expectLater(
        client.dio.get<void>('/api/posts/feed'),
        throwsA(
          isA<DioException>().having(
            (exception) => exception.error,
            'mapped error',
            isA<AppFailure>()
                .having(
                  (failure) => failure.kind,
                  'kind',
                  AppFailureKind.network,
                )
                .having(
                  (failure) => failure.userMessage,
                  'safe message',
                  isNot(contains('internal-host.local')),
                ),
          ),
        ),
      );
    },
  );
}

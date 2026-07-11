import 'dart:typed_data';

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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

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
      throwsA(isA<DioException>()),
    );
    expect(unauthorizedCalls, 1);
  });
}

import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unwraps a mapped Dio failure without exposing technical details', () {
    final failure = AppFailure.network(
      technicalMessage: 'SocketException: internal-host.local',
    );
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/posts/feed'),
      error: failure,
      message: 'transport failed',
    );

    final message = userErrorMessage(error);

    expect(message, failure.userMessage);
    expect(message, isNot(contains('internal-host.local')));
    expect(message, isNot(contains('DioException')));
  });

  test('uses a safe generic message for unknown errors', () {
    expect(
      userErrorMessage(StateError('database password leaked')),
      const AppFailure.unknown().userMessage,
    );
  });
}

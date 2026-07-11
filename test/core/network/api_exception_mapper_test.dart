import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:daily_meal_flutter_app/core/network/api_exception_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapper = ApiExceptionMapper();

  test('maps timeout and connection failures', () {
    final request = RequestOptions(path: '/api/posts/feed');
    expect(
      mapper
          .map(
            DioException(
              requestOptions: request,
              type: DioExceptionType.connectionTimeout,
            ),
          )
          .kind,
      AppFailureKind.timeout,
    );
    expect(
      mapper
          .map(
            DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            ),
          )
          .kind,
      AppFailureKind.network,
    );
  });

  test('maps status codes and safe backend validation messages', () {
    final request = RequestOptions(path: '/api/auth/login');
    final unauthorized = DioException(
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 401),
    );
    final validation = DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 400,
        data: {'message': 'Email không hợp lệ', 'code': 'INVALID_EMAIL'},
      ),
    );

    expect(mapper.map(unauthorized).kind, AppFailureKind.unauthorized);
    expect(mapper.map(validation).userMessage, 'Email không hợp lệ');
    expect(mapper.map(validation).code, 'INVALID_EMAIL');
  });
}

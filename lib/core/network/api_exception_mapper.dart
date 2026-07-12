import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:dio/dio.dart';

class ApiExceptionMapper {
  const ApiExceptionMapper();

  AppFailure map(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppFailure.timeout(technicalMessage: exception.message);
      case DioExceptionType.connectionError:
        return AppFailure.network(technicalMessage: exception.message);
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        break;
    }

    final response = exception.response;
    final status = response?.statusCode;
    final data = response?.data;
    final message = data is Map<String, dynamic> && data['message'] is String
        ? data['message'] as String
        : null;
    final code = data is Map<String, dynamic> && data['code'] is String
        ? data['code'] as String
        : null;

    return switch (status) {
      400 => AppFailure.validation(
        message: message ?? 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại.',
        technicalMessage: exception.message,
        code: code,
      ),
      401 when _isAuthenticationAttempt(exception.requestOptions) =>
        AppFailure.validation(
          message: message ?? 'Email hoặc mật khẩu không đúng.',
          technicalMessage: exception.message,
          code: code,
        ),
      401 => AppFailure.unauthorized(technicalMessage: exception.message),
      403 => AppFailure.forbidden(technicalMessage: exception.message),
      404 => AppFailure.notFound(technicalMessage: exception.message),
      409 => AppFailure.conflict(
        message: message,
        technicalMessage: exception.message,
      ),
      final int value when value >= 500 => AppFailure.server(
        technicalMessage: exception.message,
        statusCode: value,
      ),
      _ => AppFailure.unknown(technicalMessage: exception.message),
    };
  }

  bool _isAuthenticationAttempt(RequestOptions request) {
    final authorization = request.headers['Authorization'];
    if (authorization is String && authorization.trim().isNotEmpty) {
      return false;
    }
    return const {
      '/api/auth/login',
      '/api/auth/phone/login',
      '/api/auth/google',
      '/api/auth/facebook',
      '/api/admin/login',
    }.contains(request.path);
  }
}

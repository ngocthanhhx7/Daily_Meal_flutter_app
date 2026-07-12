import 'package:daily_meal_flutter_app/core/network/api_exception_mapper.dart';
import 'package:daily_meal_flutter_app/core/network/auth_token_provider.dart';
import 'package:dio/dio.dart';

typedef UnauthorizedCallback = Future<void> Function();

class ApiClient {
  ApiClient._(this.dio);

  factory ApiClient.create({
    required Uri baseUrl,
    required AuthTokenProvider tokenProvider,
    HttpClientAdapter? adapter,
    UnauthorizedCallback? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {Headers.acceptHeader: Headers.jsonContentType},
      ),
    );
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider.readToken();
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && onUnauthorized != null) {
            await onUnauthorized();
          }
          final failure = const ApiExceptionMapper().map(error);
          handler.reject(
            error.copyWith(error: failure, message: failure.userMessage),
          );
        },
      ),
    );

    return ApiClient._(dio);
  }

  final Dio dio;
}

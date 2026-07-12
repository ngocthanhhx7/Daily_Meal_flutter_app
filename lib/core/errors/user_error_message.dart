import 'package:daily_meal_flutter_app/core/errors/app_failure.dart';
import 'package:daily_meal_flutter_app/core/network/api_exception_mapper.dart';
import 'package:dio/dio.dart';

String userErrorMessage(Object error) {
  if (error case final AppFailure failure) return failure.userMessage;
  if (error case DioException(error: final AppFailure failure)) {
    return failure.userMessage;
  }
  if (error case final DioException exception) {
    return const ApiExceptionMapper().map(exception).userMessage;
  }
  return const AppFailure.unknown().userMessage;
}

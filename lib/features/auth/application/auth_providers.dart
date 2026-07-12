import 'package:daily_meal_flutter_app/app/config/app_config.dart';
import 'package:daily_meal_flutter_app/core/network/api_client.dart';
import 'package:daily_meal_flutter_app/core/network/session_auth_token_provider.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_controller.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_api.dart';
import 'package:daily_meal_flutter_app/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig must be provided during bootstrap.'),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => throw StateError('SessionStore must be provided during bootstrap.'),
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final sessions = ref.watch(sessionStoreProvider);
  return ApiClient.create(
    baseUrl: config.apiBaseUrl,
    tokenProvider: SessionAuthTokenProvider(sessions),
  ).dio;
});

final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  return AuthRepository(
    AuthApi(ref.watch(dioProvider)),
    ref.watch(sessionStoreProvider),
  );
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  controller.startRestore();
  return controller;
});

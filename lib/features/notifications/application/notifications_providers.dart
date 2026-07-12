import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_api.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/web_push_controller.dart';
import 'package:daily_meal_flutter_app/core/notifications/web_push_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepositoryContract>(
      (ref) =>
          NotificationsRepository(NotificationsApi(ref.watch(dioProvider))),
    );
final notificationsControllerProvider =
    ChangeNotifierProvider.autoDispose<NotificationsController>((ref) {
      final controller = NotificationsController(
        ref.watch(notificationsRepositoryProvider),
        ref.watch(realtimeClientProvider),
      );
      controller.initialize().catchError((_) {});
      return controller;
    });

final webPushControllerProvider =
    ChangeNotifierProvider.autoDispose<WebPushController>((ref) {
      final controller = WebPushController(
        ref.watch(notificationsRepositoryProvider),
        BrowserWebPushPlatform(),
      );
      controller.initialize();
      return controller;
    });

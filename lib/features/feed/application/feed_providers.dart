import 'dart:async';

import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/feed/application/feed_controller.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_api.dart';
import 'package:daily_meal_flutter_app/features/feed/data/feed_repository.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final feedRepositoryProvider = Provider<FeedRepositoryContract>((ref) {
  return FeedRepository(FeedApi(ref.watch(dioProvider)));
});

final mediaUrlResolverProvider = Provider<MediaUrlResolver>((ref) {
  return MediaUrlResolver(ref.watch(appConfigProvider).apiBaseUrl);
});

final feedControllerProvider =
    ChangeNotifierProvider.autoDispose<FeedController>((ref) {
      final controller = FeedController(
        ref.watch(feedRepositoryProvider),
        realtime: ref.watch(realtimeClientProvider),
      );
      unawaited(controller.loadInitial().catchError((_) {}));
      return controller;
    });

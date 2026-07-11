import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/auth/application/auth_providers.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_api.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagingRepositoryProvider = Provider<MessagingRepositoryContract>(
  (ref) => MessagingRepository(MessagingApi(ref.watch(dioProvider))),
);

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = SocketIoRealtimeClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    sessions: ref.watch(sessionStoreProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

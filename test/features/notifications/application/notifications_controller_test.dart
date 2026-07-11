import 'dart:async';

import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification notification(String id, {bool read = false}) => AppNotification(
  id: id,
  type: NotificationType.follow,
  body: id,
  read: read,
  createdAt: DateTime.utc(2026, 7, 12),
);

class _Repository implements NotificationsRepositoryContract {
  bool fail = false;
  @override
  Future<List<AppNotification>> load() async => [notification('n1')];
  Future<void> action() async {
    if (fail) throw StateError('network');
  }

  @override
  Future<void> markRead(String id) => action();
  @override
  Future<void> markAllRead() => action();
  @override
  Future<void> delete(String id) => action();
  @override
  Future<void> deleteAll() => action();
}

class _Realtime implements RealtimeClient {
  final stream = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get createdNotifications => stream.stream;
  @override
  Stream<Conversation> get conversationUpdates => const Stream.empty();
  @override
  Stream<ChatMessage> get createdMessages => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  void joinConversation(String conversationId) {}
  @override
  void leaveConversation(String conversationId) {}
  @override
  void dispose() => stream.close();
}

void main() {
  test('upserts realtime notifications and marks all read', () async {
    final realtime = _Realtime();
    final controller = NotificationsController(_Repository(), realtime);
    await controller.initialize();
    realtime.stream.add({
      '_id': 'n2',
      'type': 'message',
      'body': 'new',
      'read': false,
      'createdAt': '2026-07-12T02:00:00Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(controller.notifications.first.id, 'n2');
    expect(controller.unreadCount, 2);
    await controller.markAllRead();
    expect(controller.unreadCount, 0);
    controller.dispose();
    realtime.dispose();
  });

  test('delete rolls back when mutation fails', () async {
    final repository = _Repository();
    final realtime = _Realtime();
    final controller = NotificationsController(repository, realtime);
    await controller.initialize();
    repository.fail = true;
    final pending = controller.delete('n1');
    expect(controller.notifications, isEmpty);
    await expectLater(pending, throwsStateError);
    expect(controller.notifications.single.id, 'n1');
    controller.dispose();
    realtime.dispose();
  });
}

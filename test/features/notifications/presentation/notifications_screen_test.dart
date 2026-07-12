import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/notifications_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:daily_meal_flutter_app/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements NotificationsRepositoryContract {
  @override
  Future<List<AppNotification>> load() async => [
    AppNotification(
      id: 'n1',
      type: NotificationType.like,
      body: 'đã thích bài viết của bạn',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      sender: const NotificationSender(id: 'u1', displayName: 'Bếp Nhà'),
      postId: 'p1',
    ),
  ];
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> markAllRead() async {}
  @override
  Future<void> markRead(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Realtime implements RealtimeClient {
  @override
  Stream<Map<String, dynamic>> get createdNotifications => const Stream.empty();
  @override
  Stream<void> get reconnects => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('renders source notification toolbar, metadata and row delete', (
    tester,
  ) async {
    final controller = NotificationsController(_Repository(), _Realtime());
    addTearDown(controller.dispose);
    await controller.initialize();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: NotificationsScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn có 1 thông báo'), findsOneWidget);
    expect(find.text('Bếp Nhà'), findsOneWidget);
    expect(find.text('5 phút trước'), findsOneWidget);
    expect(find.byKey(const Key('delete-notification-n1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-notification-n1')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có thông báo nào.'), findsOneWidget);
  });
}

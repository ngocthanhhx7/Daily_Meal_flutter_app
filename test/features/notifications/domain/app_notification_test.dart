import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification item(NotificationType type, {NotificationSender? sender}) =>
    AppNotification(
      id: type.name,
      type: type,
      body: type.name,
      read: false,
      createdAt: DateTime.utc(2026),
      sender: sender,
    );

void main() {
  test('maps notification types to safe deep-link destinations', () {
    const sender = NotificationSender(id: 'u1', displayName: 'User');
    expect(
      notificationDestination(item(NotificationType.follow, sender: sender)),
      NotificationDestination.publicProfile,
    );
    expect(
      notificationDestination(item(NotificationType.message)),
      NotificationDestination.inbox,
    );
    expect(
      notificationDestination(item(NotificationType.like)),
      NotificationDestination.home,
    );
    expect(
      notificationDestination(item(NotificationType.comment)),
      NotificationDestination.home,
    );
  });
}

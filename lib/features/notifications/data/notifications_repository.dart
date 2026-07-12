import 'package:daily_meal_flutter_app/features/notifications/data/notifications_api.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';

abstract interface class NotificationsRepositoryContract {
  Future<List<AppNotification>> load();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<String> webPushPublicKey();
  Future<void> registerWebPush(Map<String, dynamic> subscription);
  Future<void> unregisterWebPush(String endpoint);
}

class NotificationsRepository implements NotificationsRepositoryContract {
  NotificationsRepository(this._api);
  final NotificationsApi _api;
  @override
  Future<List<AppNotification>> load() => _api.load();
  @override
  Future<void> markRead(String id) => _api.markRead(id);
  @override
  Future<void> markAllRead() => _api.markAllRead();
  @override
  Future<void> delete(String id) => _api.delete(id);
  @override
  Future<void> deleteAll() => _api.deleteAll();
  @override
  Future<String> webPushPublicKey() => _api.webPushPublicKey();
  @override
  Future<void> registerWebPush(Map<String, dynamic> subscription) =>
      _api.registerWebPush(subscription);
  @override
  Future<void> unregisterWebPush(String endpoint) =>
      _api.unregisterWebPush(endpoint);
}

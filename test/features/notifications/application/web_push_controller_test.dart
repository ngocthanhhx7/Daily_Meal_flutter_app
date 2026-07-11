import 'package:daily_meal_flutter_app/core/notifications/web_push_platform_stub.dart';
import 'package:daily_meal_flutter_app/features/notifications/application/web_push_controller.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

class _Platform implements WebPushPlatform {
  String readinessValue = 'needs-permission';
  String? endpoint;
  @override
  bool get supported => true;
  @override
  String readiness(String publicKey) => readinessValue;
  @override
  Future<Map<String, dynamic>> subscribe(String publicKey) async {
    endpoint = 'https://push.test';
    return {
      'endpoint': endpoint,
      'expirationTime': null,
      'keys': {'p256dh': 'p', 'auth': 'a'},
    };
  }

  @override
  String? registeredEndpoint() => endpoint;
  @override
  void clearEndpoint() => endpoint = null;
}

class _Repository implements NotificationsRepositoryContract {
  Map<String, dynamic>? registered;
  String? unregistered;
  @override
  Future<String> webPushPublicKey() async => 'vapid-key';
  @override
  Future<void> registerWebPush(Map<String, dynamic> subscription) async =>
      registered = subscription;
  @override
  Future<void> unregisterWebPush(String endpoint) async =>
      unregistered = endpoint;
  @override
  Future<List<AppNotification>> load() => throw UnimplementedError();
  @override
  Future<void> markRead(String id) => throw UnimplementedError();
  @override
  Future<void> markAllRead() => throw UnimplementedError();
  @override
  Future<void> delete(String id) => throw UnimplementedError();
  @override
  Future<void> deleteAll() => throw UnimplementedError();
}

void main() {
  test('registers and unregisters browser subscription lifecycle', () async {
    final repository = _Repository();
    final platform = _Platform();
    final controller = WebPushController(repository, platform);
    await controller.initialize();
    expect(controller.status, WebPushStatus.needsPermission);
    await controller.enable();
    expect(controller.status, WebPushStatus.ready);
    expect(repository.registered?['endpoint'], 'https://push.test');
    await controller.disable();
    expect(repository.unregistered, 'https://push.test');
    expect(platform.endpoint, isNull);
  });
}

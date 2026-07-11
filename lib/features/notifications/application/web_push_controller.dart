import 'package:daily_meal_flutter_app/core/notifications/web_push_platform.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:flutter/foundation.dart';

enum WebPushStatus {
  loading,
  unsupported,
  missingPublicKey,
  needsPermission,
  permissionDenied,
  ready,
  failure,
}

class WebPushController extends ChangeNotifier {
  WebPushController(this._repository, this._platform);
  final NotificationsRepositoryContract _repository;
  final WebPushPlatform _platform;
  WebPushStatus status = WebPushStatus.loading;
  String? errorMessage;
  String _publicKey = '';

  Future<void> initialize() async {
    if (!_platform.supported) {
      status = WebPushStatus.unsupported;
      notifyListeners();
      return;
    }
    try {
      _publicKey = await _repository.webPushPublicKey();
      status = _status(_platform.readiness(_publicKey));
    } catch (error) {
      status = WebPushStatus.failure;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> enable() async {
    if (!_platform.supported || _publicKey.isEmpty) return;
    status = WebPushStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.registerWebPush(await _platform.subscribe(_publicKey));
      status = WebPushStatus.ready;
    } catch (error) {
      status = _status(_platform.readiness(_publicKey));
      if (status == WebPushStatus.ready) status = WebPushStatus.failure;
      errorMessage = error.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> disable() async {
    final endpoint = _platform.registeredEndpoint();
    if (endpoint == null) return;
    await _repository.unregisterWebPush(endpoint);
    _platform.clearEndpoint();
    status = WebPushStatus.needsPermission;
    notifyListeners();
  }

  WebPushStatus _status(String value) => switch (value) {
    'ready' => WebPushStatus.ready,
    'needs-permission' => WebPushStatus.needsPermission,
    'permission-denied' => WebPushStatus.permissionDenied,
    'missing-public-key' => WebPushStatus.missingPublicKey,
    _ => WebPushStatus.unsupported,
  };
}

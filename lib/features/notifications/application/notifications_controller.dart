import 'dart:async';

import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/notifications/data/notifications_repository.dart';
import 'package:daily_meal_flutter_app/features/notifications/domain/app_notification.dart';
import 'package:flutter/foundation.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._repository, this._realtime);
  final NotificationsRepositoryContract _repository;
  final RealtimeClient _realtime;
  List<AppNotification> notifications = const [];
  bool loading = false;
  String? errorMessage;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  int get unreadCount => notifications.where((item) => !item.read).length;

  Future<void> initialize() async {
    _subscription ??= _realtime.createdNotifications.listen((json) {
      try {
        _upsert(AppNotification.fromJson(json));
      } catch (_) {}
    });
    unawaited(_realtime.connect());
    await load();
  }

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      notifications = _sort(await _repository.load());
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async => _mutation(
    optimistic: () => notifications = notifications
        .map((item) => item.id == id ? item.withRead(true) : item)
        .toList(growable: false),
    request: () => _repository.markRead(id),
  );
  Future<void> markAllRead() async => _mutation(
    optimistic: () => notifications = notifications
        .map((item) => item.withRead(true))
        .toList(growable: false),
    request: _repository.markAllRead,
  );
  Future<void> delete(String id) async => _mutation(
    optimistic: () => notifications = notifications
        .where((item) => item.id != id)
        .toList(growable: false),
    request: () => _repository.delete(id),
  );
  Future<void> deleteAll() async => _mutation(
    optimistic: () => notifications = const [],
    request: _repository.deleteAll,
  );
  Future<void> _mutation({
    required VoidCallback optimistic,
    required Future<void> Function() request,
  }) async {
    final previous = notifications;
    optimistic();
    notifyListeners();
    try {
      await request();
    } catch (error) {
      notifications = previous;
      errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _upsert(AppNotification value) {
    notifications = _sort([
      value,
      ...notifications.where((item) => item.id != value.id),
    ]);
    notifyListeners();
  }

  List<AppNotification> _sort(List<AppNotification> values) =>
      [...values]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

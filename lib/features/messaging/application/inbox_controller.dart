import 'dart:async';

import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_repository.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:flutter/foundation.dart';

class InboxController extends ChangeNotifier {
  InboxController(this._repository, this._realtime);
  final MessagingRepositoryContract _repository;
  final RealtimeClient _realtime;
  List<Conversation> conversations = const [];
  bool loading = false;
  String? errorMessage;
  StreamSubscription<Conversation>? _subscription;

  Future<void> initialize() async {
    _subscription ??= _realtime.conversationUpdates.listen(_upsert);
    unawaited(_realtime.connect());
    await load();
  }

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      conversations = _sort(await _repository.conversations());
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _upsert(Conversation value) {
    conversations = _sort([
      value,
      ...conversations.where((item) => item.id != value.id),
    ]);
    notifyListeners();
  }

  List<Conversation> _sort(List<Conversation> values) =>
      [...values]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

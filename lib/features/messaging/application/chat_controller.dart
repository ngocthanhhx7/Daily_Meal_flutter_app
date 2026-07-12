import 'dart:async';

import 'package:daily_meal_flutter_app/core/errors/user_error_message.dart';
import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_repository.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  ChatController(
    this._repository,
    this._realtime, {
    required this.conversationId,
    ChatUser? initialOtherUser,
  }) : otherUser = initialOtherUser;
  final MessagingRepositoryContract _repository;
  final RealtimeClient _realtime;
  final String conversationId;
  ChatUser? otherUser;
  List<ChatMessage> messages = const [];
  bool loading = false;
  bool sending = false;
  String? errorMessage;
  StreamSubscription<ChatMessage>? _subscription;
  StreamSubscription<void>? _reconnectSubscription;

  Future<void> initialize() async {
    _subscription ??= _realtime.createdMessages
        .where((message) => message.conversationId == conversationId)
        .listen(_append);
    _reconnectSubscription ??= _realtime.reconnects.listen((_) {
      _realtime.joinConversation(conversationId);
      unawaited(_loadMessages().catchError((_) {}));
    });
    await _realtime.connect();
    _realtime.joinConversation(conversationId);
    await Future.wait([_restoreOtherUser(), _loadMessages()]);
  }

  Future<void> _restoreOtherUser() async {
    if (otherUser != null) return;
    try {
      final conversations = await _repository.conversations();
      for (final conversation in conversations) {
        if (conversation.id == conversationId) {
          otherUser = conversation.otherUser;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Participant metadata is optional; messages and composer remain usable.
    }
  }

  Future<void> _loadMessages() async {
    loading = true;
    notifyListeners();
    try {
      final loaded = await _repository.messages(conversationId);
      messages = _merge([...loaded, ...messages]);
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> send(String body) async {
    final normalized = body.trim();
    if (normalized.isEmpty || normalized.length > 2000 || sending) return false;
    sending = true;
    errorMessage = null;
    notifyListeners();
    try {
      _append(await _repository.send(conversationId, normalized));
      return true;
    } catch (error) {
      errorMessage = userErrorMessage(error);
      rethrow;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void _append(ChatMessage message) {
    messages = _merge([...messages, message]);
    notifyListeners();
  }

  List<ChatMessage> _merge(List<ChatMessage> values) {
    final unique = <String, ChatMessage>{};
    for (final value in values) {
      unique[value.id] = value;
    }
    final result = unique.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  @override
  void dispose() {
    _realtime.leaveConversation(conversationId);
    _subscription?.cancel();
    _reconnectSubscription?.cancel();
    super.dispose();
  }
}

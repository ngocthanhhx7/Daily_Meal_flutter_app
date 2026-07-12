import 'package:daily_meal_flutter_app/features/messaging/data/messaging_api.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';

abstract interface class MessagingRepositoryContract {
  Future<List<Conversation>> conversations();
  Future<Conversation> createConversation(String recipientId);
  Future<List<ChatMessage>> messages(String conversationId);
  Future<ChatMessage> send(String conversationId, String body);
}

class MessagingRepository implements MessagingRepositoryContract {
  MessagingRepository(this._api);
  final MessagingApi _api;
  @override
  Future<List<Conversation>> conversations() => _api.conversations();
  @override
  Future<Conversation> createConversation(String recipientId) =>
      _api.createConversation(recipientId);
  @override
  Future<List<ChatMessage>> messages(String conversationId) =>
      _api.messages(conversationId);
  @override
  Future<ChatMessage> send(String conversationId, String body) =>
      _api.send(conversationId, body);
}

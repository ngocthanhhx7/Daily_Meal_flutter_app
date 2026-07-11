import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:dio/dio.dart';

class MessagingApi {
  MessagingApi(this._dio);
  final Dio _dio;

  Future<List<Conversation>> conversations() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/messages/conversations',
    );
    final raw = response.data?['conversations'];
    if (raw is! List) {
      throw const FormatException('Invalid conversations response');
    }
    return raw
        .whereType<Map>()
        .map((item) => Conversation.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Conversation> createConversation(String recipientId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/messages/conversations',
      data: {'recipientId': recipientId},
    );
    final raw = response.data?['conversation'];
    if (raw is! Map) {
      throw const FormatException('Invalid conversation response');
    }
    return Conversation.fromJson(raw.cast<String, dynamic>());
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/messages/conversations/$conversationId/messages',
    );
    final raw = response.data?['messages'];
    if (raw is! List) {
      throw const FormatException('Invalid messages response');
    }
    return raw
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<ChatMessage> send(String conversationId, String body) async {
    final normalized = body.trim();
    if (normalized.isEmpty || normalized.length > 2000) {
      throw ArgumentError('Message must contain 1-2000 characters');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/messages/conversations/$conversationId/messages',
      data: {'body': normalized},
    );
    final raw = response.data?['message'];
    if (raw is! Map) throw const FormatException('Invalid message response');
    return ChatMessage.fromJson(raw.cast<String, dynamic>());
  }
}

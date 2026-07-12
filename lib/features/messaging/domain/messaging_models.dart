class ChatUser {
  const ChatUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.isPremium = false,
  });
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['displayName'];
    if (id is! String || name is! String) {
      throw const FormatException('Invalid chat user');
    }
    return ChatUser(
      id: id,
      displayName: name,
      avatarUrl: json['avatarUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isPremium;
}

class LastMessage {
  const LastMessage({required this.body, this.senderId, this.sentAt});
  factory LastMessage.fromJson(Map<String, dynamic>? json) => LastMessage(
    body: json?['body'] as String? ?? '',
    senderId: _referenceId(json?['sender']),
    sentAt: DateTime.tryParse(json?['sentAt'] as String? ?? ''),
  );
  final String body;
  final String? senderId;
  final DateTime? sentAt;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    required this.otherUser,
    required this.lastMessage,
    required this.updatedAt,
  });
  factory Conversation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawParticipants = json['participants'];
    final other = json['otherUser'];
    final updated = json['updatedAt'];
    if (id is! String ||
        rawParticipants is! List ||
        other is! Map ||
        updated is! String) {
      throw const FormatException('Invalid conversation');
    }
    return Conversation(
      id: id,
      participants: rawParticipants
          .whereType<Map>()
          .map((item) => ChatUser.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      otherUser: ChatUser.fromJson(other.cast<String, dynamic>()),
      lastMessage: LastMessage.fromJson(
        (json['lastMessage'] as Map?)?.cast<String, dynamic>(),
      ),
      updatedAt: DateTime.parse(updated),
    );
  }
  final String id;
  final List<ChatUser> participants;
  final ChatUser otherUser;
  final LastMessage lastMessage;
  final DateTime updatedAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.createdAt,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final conversationId = json['conversationId'];
    final sender = json['sender'];
    final body = json['body'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        conversationId is! String ||
        sender is! Map ||
        body is! String ||
        createdAt is! String) {
      throw const FormatException('Invalid chat message');
    }
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      sender: ChatUser.fromJson(sender.cast<String, dynamic>()),
      body: body,
      createdAt: DateTime.parse(createdAt),
    );
  }
  final String id;
  final String conversationId;
  final ChatUser sender;
  final String body;
  final DateTime createdAt;
}

String? _referenceId(Object? value) {
  if (value is String) return value;
  if (value is Map) return (value['id'] ?? value['_id']) as String?;
  return null;
}

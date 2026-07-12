import 'dart:async';

import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/chat_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/inbox_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_repository.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:flutter_test/flutter_test.dart';

ChatUser user(String id) => ChatUser(id: id, displayName: id);
Conversation conversation(String id, DateTime time) => Conversation(
  id: id,
  participants: [user('me'), user('other')],
  otherUser: user('other'),
  lastMessage: const LastMessage(body: 'hello'),
  updatedAt: time,
);
ChatMessage message(String id, {String conversationId = 'c1'}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  sender: user('me'),
  body: id,
  createdAt: DateTime.utc(2026, 7, 12),
);

class _Repository implements MessagingRepositoryContract {
  bool failSend = false;
  var conversationLoads = 0;
  var messageLoads = 0;
  @override
  Future<List<Conversation>> conversations() async {
    conversationLoads++;
    return [conversation('old', DateTime.utc(2026))];
  }

  @override
  Future<Conversation> createConversation(String recipientId) async =>
      conversation('c1', DateTime.utc(2026));
  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    messageLoads++;
    return [message('m1')];
  }

  @override
  Future<ChatMessage> send(String conversationId, String body) async {
    if (failSend) throw StateError('network');
    return message('m2');
  }
}

class _Realtime implements RealtimeClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final conversations = StreamController<Conversation>.broadcast();
  final messages = StreamController<ChatMessage>.broadcast();
  final recoveries = StreamController<void>.broadcast();
  String? joined;
  String? left;
  var joinCalls = 0;
  @override
  Stream<void> get reconnects => recoveries.stream;
  @override
  Stream<Conversation> get conversationUpdates => conversations.stream;
  @override
  Stream<ChatMessage> get createdMessages => messages.stream;
  @override
  Stream<Map<String, dynamic>> get createdNotifications => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  void joinConversation(String conversationId) {
    joined = conversationId;
    joinCalls++;
  }

  @override
  void leaveConversation(String conversationId) => left = conversationId;
  @override
  void dispose() {
    conversations.close();
    messages.close();
    recoveries.close();
  }
}

void main() {
  test('inbox upserts and sorts realtime conversation updates', () async {
    final realtime = _Realtime();
    final controller = InboxController(_Repository(), realtime);
    await controller.initialize();
    realtime.conversations.add(conversation('new', DateTime.utc(2027)));
    await Future<void>.delayed(Duration.zero);
    expect(controller.conversations.map((item) => item.id), ['new', 'old']);
    controller.dispose();
    realtime.dispose();
  });

  test('inbox reloads its REST source after reconnect', () async {
    final repository = _Repository();
    final realtime = _Realtime();
    final controller = InboxController(repository, realtime);
    await controller.initialize();

    realtime.recoveries.add(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.conversationLoads, 2);
    controller.dispose();
    realtime.dispose();
  });

  test(
    'chat joins room, deduplicates REST/socket/send and leaves room',
    () async {
      final realtime = _Realtime();
      final controller = ChatController(
        _Repository(),
        realtime,
        conversationId: 'c1',
      );
      await controller.initialize();
      expect(realtime.joined, 'c1');
      realtime.messages.add(message('m1'));
      realtime.messages.add(message('other', conversationId: 'c2'));
      await Future<void>.delayed(Duration.zero);
      await controller.send('hello');
      expect(controller.messages.map((item) => item.id), ['m1', 'm2']);
      controller.dispose();
      expect(realtime.left, 'c1');
      realtime.dispose();
    },
  );

  test('chat rejoins its room and reloads messages after reconnect', () async {
    final repository = _Repository();
    final realtime = _Realtime();
    final controller = ChatController(
      repository,
      realtime,
      conversationId: 'c1',
    );
    await controller.initialize();

    realtime.recoveries.add(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(realtime.joinCalls, 2);
    expect(repository.messageLoads, 2);
    controller.dispose();
    realtime.dispose();
  });
}

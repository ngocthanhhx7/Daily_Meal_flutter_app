import 'dart:async';

import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/core/responsive/adaptive_scaffold.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/chat_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/application/inbox_controller.dart';
import 'package:daily_meal_flutter_app/features/messaging/data/messaging_repository.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:daily_meal_flutter_app/features/messaging/presentation/chat_screen.dart';
import 'package:daily_meal_flutter_app/features/messaging/presentation/inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final me = ChatUser(id: 'me', displayName: 'Tôi');
final other = ChatUser(id: 'other', displayName: 'Bếp Bạn');
Conversation conversation() => Conversation(
  id: 'c1',
  participants: [me, other],
  otherUser: other,
  lastMessage: const LastMessage(body: 'Chào bạn'),
  updatedAt: DateTime.utc(2026, 7, 12),
);
ChatMessage message(String id, String body) => ChatMessage(
  id: id,
  conversationId: 'c1',
  sender: id == 'm1' ? other : me,
  body: body,
  createdAt: DateTime.utc(2026, 7, 12),
);

class _Repository implements MessagingRepositoryContract {
  @override
  Future<List<Conversation>> conversations() async => [conversation()];
  @override
  Future<Conversation> createConversation(String recipientId) async =>
      conversation();
  @override
  Future<List<ChatMessage>> messages(String conversationId) async => [
    message('m1', 'Chào bạn'),
  ];
  @override
  Future<ChatMessage> send(String conversationId, String body) async =>
      message('m2', body);
}

class _EmptyRepository extends _Repository {
  @override
  Future<List<Conversation>> conversations() async => const [];
}

class _Realtime implements RealtimeClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final conversationStream = StreamController<Conversation>.broadcast();
  final messageStream = StreamController<ChatMessage>.broadcast();
  @override
  Stream<void> get reconnects => const Stream.empty();
  @override
  Stream<Conversation> get conversationUpdates => conversationStream.stream;
  @override
  Stream<ChatMessage> get createdMessages => messageStream.stream;
  @override
  Stream<Map<String, dynamic>> get createdNotifications => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Future<void> connect() async {}
  @override
  void joinConversation(String conversationId) {}
  @override
  void leaveConversation(String conversationId) {}
  @override
  void dispose() {
    conversationStream.close();
    messageStream.close();
  }
}

void main() {
  testWidgets('inbox empty state matches the source composition', (
    tester,
  ) async {
    final realtime = _Realtime();
    final controller = InboxController(_EmptyRepository(), realtime);
    await controller.initialize();
    addTearDown(() {
      controller.dispose();
      realtime.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InboxScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.text('Chưa có tin nhắn'), findsOneWidget);
    expect(
      find.text('Mở trang cá nhân người khác và nhấn Nhắn tin để bắt đầu.'),
      findsOneWidget,
    );
  });

  testWidgets('inbox renders responsive conversation list', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final realtime = _Realtime();
    final controller = InboxController(_Repository(), realtime);
    await controller.initialize();
    addTearDown(() {
      controller.dispose();
      realtime.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InboxScreen(
            controller: controller,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AdaptiveScaffold.compactNavigationKey), findsNothing);
    expect(find.text('Bếp Bạn'), findsOneWidget);
    expect(find.text('Chào bạn'), findsOneWidget);
  });

  testWidgets('chat renders messages and sends trimmed input', (tester) async {
    final realtime = _Realtime();
    final controller = ChatController(
      _Repository(),
      realtime,
      conversationId: 'c1',
    );
    await controller.initialize();
    addTearDown(() {
      controller.dispose();
      realtime.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChatScreen(
            conversationId: 'c1',
            otherUser: other,
            controller: controller,
            currentUserId: 'me',
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chào bạn'), findsOneWidget);
    expect(find.byKey(const Key('source-chat-header')), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsWidgets);
    await tester.enterText(find.byType(TextField), '  Hẹn gặp lại  ');
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();
    expect(find.text('Hẹn gặp lại'), findsOneWidget);
    expect(find.byType(TextField).evaluate().single.widget, isA<TextField>());
  });

  testWidgets('chat restores the participant header without route extra', (
    tester,
  ) async {
    final realtime = _Realtime();
    final controller = ChatController(
      _Repository(),
      realtime,
      conversationId: 'c1',
    );
    await controller.initialize();
    addTearDown(() {
      controller.dispose();
      realtime.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChatScreen(
            conversationId: 'c1',
            controller: controller,
            currentUserId: 'me',
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bếp Bạn'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsNothing);
  });
}

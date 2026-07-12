import 'dart:async';

import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

abstract interface class RealtimeClient {
  Stream<Conversation> get conversationUpdates;
  Stream<ChatMessage> get createdMessages;
  Stream<Map<String, dynamic>> get createdNotifications;
  Stream<PostComment> get createdComments;
  Stream<String> get errors;
  Future<void> connect();
  void joinConversation(String conversationId);
  void leaveConversation(String conversationId);
  void joinPost(String postId);
  void leavePost(String postId);
  void dispose();
}

class SocketIoRealtimeClient implements RealtimeClient {
  SocketIoRealtimeClient({required this.baseUrl, required this.sessions});
  final Uri baseUrl;
  final SessionStore sessions;
  io.Socket? _socket;
  final _conversations = StreamController<Conversation>.broadcast();
  final _messages = StreamController<ChatMessage>.broadcast();
  final _notifications = StreamController<Map<String, dynamic>>.broadcast();
  final _comments = StreamController<PostComment>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<Conversation> get conversationUpdates => _conversations.stream;
  @override
  Stream<ChatMessage> get createdMessages => _messages.stream;
  @override
  Stream<Map<String, dynamic>> get createdNotifications =>
      _notifications.stream;
  @override
  Stream<PostComment> get createdComments => _comments.stream;
  @override
  Stream<String> get errors => _errors.stream;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    final session = await sessions.read(SessionKind.user);
    if (session == null) return;
    final socket = io.io(
      baseUrl.origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': session.token})
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket = socket;
    socket.on(
      'conversation:updated',
      (data) => _decode(data, Conversation.fromJson, _conversations),
    );
    socket.on(
      'message:created',
      (data) => _decode(data, ChatMessage.fromJson, _messages),
    );
    socket.on('notification:created', (data) {
      if (data is Map) _notifications.add(data.cast<String, dynamic>());
    });
    socket.on(
      'comment:created',
      (data) => _decode(data, PostComment.fromJson, _comments),
    );
    socket.on('auth:error', (data) => _errors.add(_message(data)));
    socket.on('room:error', (data) => _errors.add(_message(data)));
    socket.onConnectError((data) => _errors.add(data.toString()));
    socket.connect();
  }

  void _decode<T>(
    Object? data,
    T Function(Map<String, dynamic>) decode,
    StreamController<T> target,
  ) {
    try {
      if (data is! Map) throw const FormatException('Invalid realtime payload');
      target.add(decode(data.cast<String, dynamic>()));
    } catch (error) {
      _errors.add(error.toString());
    }
  }

  String _message(Object? data) => data is Map && data['message'] is String
      ? data['message'] as String
      : data.toString();

  @override
  void joinConversation(String conversationId) =>
      _socket?.emit('join-conversation', conversationId);
  @override
  void leaveConversation(String conversationId) =>
      _socket?.emit('leave-conversation', conversationId);
  @override
  void joinPost(String postId) => _socket?.emit('join-post', postId);
  @override
  void leavePost(String postId) => _socket?.emit('leave-post', postId);

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _conversations.close();
    _messages.close();
    _notifications.close();
    _comments.close();
    _errors.close();
  }
}

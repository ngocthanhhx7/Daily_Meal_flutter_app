import 'dart:async';

import 'package:daily_meal_flutter_app/core/storage/session.dart';
import 'package:daily_meal_flutter_app/core/storage/session_store.dart';
import 'package:daily_meal_flutter_app/features/messaging/domain/messaging_models.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

Map<String, dynamic> buildRealtimeSocketOptions(String token) {
  final options = io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(6)
      .setReconnectionDelay(1000)
      .setReconnectionDelayMax(10000)
      .setRandomizationFactor(0.5)
      .enableForceNew()
      .build();
  options['reconnection'] = true;
  return options;
}

abstract interface class RealtimeSocket {
  void on(String event, void Function(Object?) handler);
  void onConnect(void Function() handler);
  void onConnectError(void Function(Object?) handler);
  void connect();
  void emit(String event, Object? data);
  void dispose();
}

class IoRealtimeSocket implements RealtimeSocket {
  IoRealtimeSocket(String origin, Map<String, dynamic> options)
    : _socket = io.io(origin, options);

  final io.Socket _socket;

  @override
  void on(String event, void Function(Object?) handler) =>
      _socket.on(event, handler);

  @override
  void onConnect(void Function() handler) =>
      _socket.onConnect((_) => handler());

  @override
  void onConnectError(void Function(Object?) handler) =>
      _socket.onConnectError(handler);

  @override
  void connect() => _socket.connect();

  @override
  void emit(String event, Object? data) => _socket.emit(event, data);

  @override
  void dispose() => _socket.dispose();
}

typedef RealtimeSocketFactory =
    RealtimeSocket Function(String origin, Map<String, dynamic> options);

abstract interface class RealtimeClient {
  Stream<void> get reconnects;
  Stream<PostStatsUpdate> get postStatsUpdates;
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

class PostStatsUpdate {
  const PostStatsUpdate({required this.postId, required this.stats});

  factory PostStatsUpdate.fromJson(Map<String, dynamic> json) {
    final postId = json['postId'];
    final rawStats = json['stats'];
    if (postId is! String || postId.isEmpty || rawStats is! Map) {
      throw const FormatException('Invalid post stats update');
    }
    final stats = rawStats.cast<String, dynamic>();
    if (stats['likes'] is! num ||
        stats['comments'] is! num ||
        stats['saves'] is! num) {
      throw const FormatException('Incomplete post stats update');
    }
    return PostStatsUpdate(postId: postId, stats: PostStats.fromJson(stats));
  }

  final String postId;
  final PostStats stats;
}

class SocketIoRealtimeClient implements RealtimeClient {
  SocketIoRealtimeClient({
    required this.baseUrl,
    required this.sessions,
    RealtimeSocketFactory? socketFactory,
  }) : _socketFactory = socketFactory ?? IoRealtimeSocket.new;
  final Uri baseUrl;
  final SessionStore sessions;
  final RealtimeSocketFactory _socketFactory;
  RealtimeSocket? _socket;
  final _conversations = StreamController<Conversation>.broadcast();
  final _reconnects = StreamController<void>.broadcast();
  final _postStats = StreamController<PostStatsUpdate>.broadcast();
  final _messages = StreamController<ChatMessage>.broadcast();
  final _notifications = StreamController<Map<String, dynamic>>.broadcast();
  final _comments = StreamController<PostComment>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<void> get reconnects => _reconnects.stream;
  @override
  Stream<PostStatsUpdate> get postStatsUpdates => _postStats.stream;
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
    final socket = _socketFactory(
      baseUrl.origin,
      buildRealtimeSocketOptions(session.token),
    );
    _socket = socket;
    var connectedOnce = false;
    socket.onConnect(() {
      if (connectedOnce) _reconnects.add(null);
      connectedOnce = true;
    });
    socket.on(
      'post:stats-updated',
      (data) => _decode(data, PostStatsUpdate.fromJson, _postStats),
    );
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
    socket.on('auth:error', (data) {
      _errors.add(_message(data));
      socket.dispose();
      if (identical(_socket, socket)) _socket = null;
    });
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
    _reconnects.close();
    _postStats.close();
    _conversations.close();
    _messages.close();
    _notifications.close();
    _comments.close();
    _errors.close();
  }
}

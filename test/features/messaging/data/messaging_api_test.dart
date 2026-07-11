import 'dart:convert';
import 'dart:typed_data';

import 'package:daily_meal_flutter_app/features/messaging/data/messaging_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> user(String id) => {'id': id, 'displayName': 'User $id'};
Map<String, dynamic> conversation() => {
  'id': 'conversation-1',
  'participants': [user('me'), user('other')],
  'otherUser': user('other'),
  'lastMessage': {
    'body': 'Xin chào',
    'sender': 'other',
    'sentAt': '2026-07-12T01:00:00Z',
  },
  'updatedAt': '2026-07-12T01:00:00Z',
};
Map<String, dynamic> message() => {
  'id': 'message-1',
  'conversationId': 'conversation-1',
  'sender': user('me'),
  'body': 'Xin chào',
  'createdAt': '2026-07-12T01:00:00Z',
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch ((options.method, options.path)) {
      ('GET', '/api/messages/conversations') => {
        'conversations': [conversation()],
      },
      ('POST', '/api/messages/conversations') => {
        'conversation': conversation(),
      },
      ('GET', '/api/messages/conversations/conversation-1/messages') => {
        'messages': [message()],
      },
      ('POST', '/api/messages/conversations/conversation-1/messages') => {
        'message': message(),
      },
      _ => throw StateError('${options.method} ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses exact conversation and message REST contracts', () async {
    final adapter = _Adapter();
    final api = MessagingApi(
      Dio(BaseOptions(baseUrl: 'https://api.dailymeal.site'))
        ..httpClientAdapter = adapter,
    );
    expect((await api.conversations()).single.otherUser.id, 'other');
    await api.createConversation('other');
    expect((await api.messages('conversation-1')).single.body, 'Xin chào');
    await api.send('conversation-1', '  Xin chào  ');
    expect(
      adapter.requests
          .singleWhere(
            (item) =>
                item.method == 'POST' &&
                item.path == '/api/messages/conversations',
          )
          .data,
      {'recipientId': 'other'},
    );
    expect(adapter.requests.last.data, {'body': 'Xin chào'});
  });
}

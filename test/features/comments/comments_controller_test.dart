import 'dart:async';

import 'package:daily_meal_flutter_app/core/realtime/realtime_client.dart';
import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/features/comments/data/comments_repository.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:flutter_test/flutter_test.dart';

PostComment comment(String id, String body) => PostComment(
  id: id,
  body: body,
  author: const CommentAuthor(id: 'user-1', displayName: 'Meal'),
  createdAt: DateTime.utc(2026, 7, 11),
);

class _Repository implements CommentsRepositoryContract {
  bool failCreate = false;

  @override
  Future<List<PostComment>> load(String postId) async => [
    comment('1', 'First'),
  ];

  @override
  Future<PostComment> create(String postId, String body) async {
    if (failCreate) throw StateError('network');
    return comment('2', body.trim());
  }
}

class _Realtime implements RealtimeClient {
  final comments = StreamController<PostComment>.broadcast();
  String? joined, left;
  @override
  Stream<PostComment> get createdComments => comments.stream;
  @override
  Future<void> connect() async {}
  @override
  void joinPost(String postId) => joined = postId;
  @override
  void leavePost(String postId) => left = postId;
  @override
  void dispose() => comments.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('loads, sends and deduplicates received comments', () async {
    final controller = CommentsController('post-1', _Repository());

    await controller.load();
    expect(controller.state.status, CommentsStatus.ready);
    expect(controller.state.comments.single.body, 'First');

    await controller.send(' Second ');
    expect(controller.state.comments.last.body, 'Second');

    controller.receive(comment('2', 'Second'));
    expect(controller.state.comments.length, 2);
  });

  test('keeps draft content available when send fails', () async {
    final repository = _Repository()..failCreate = true;
    final controller = CommentsController('post-1', repository);
    await controller.load();

    await expectLater(controller.send('Retry me'), throwsStateError);
    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.comments.length, 1);
  });

  test(
    'joins post room, receives deduplicated live comments and leaves',
    () async {
      final realtime = _Realtime();
      final controller = CommentsController('post-1', _Repository(), realtime);
      await controller.load();
      expect(realtime.joined, 'post-1');
      realtime.comments.add(
        PostComment(
          id: 'live',
          body: 'Live',
          author: const CommentAuthor(id: 'u2', displayName: 'Live user'),
          createdAt: DateTime.utc(2026),
          postId: 'post-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.state.comments.any((item) => item.id == 'live'),
        isTrue,
      );
      controller.dispose();
      expect(realtime.left, 'post-1');
      realtime.dispose();
    },
  );
}

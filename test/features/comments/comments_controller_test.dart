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
}

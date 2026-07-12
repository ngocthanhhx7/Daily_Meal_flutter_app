import 'package:daily_meal_flutter_app/features/comments/application/comments_controller.dart';
import 'package:daily_meal_flutter_app/features/comments/data/comments_repository.dart';
import 'package:daily_meal_flutter_app/features/comments/domain/post_comment.dart';
import 'package:daily_meal_flutter_app/features/comments/presentation/comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements CommentsRepositoryContract {
  @override
  Future<List<PostComment>> load(String postId) async => [
    PostComment(
      id: 'comment-1',
      body: 'Món này đẹp quá',
      author: const CommentAuthor(id: 'user-1', displayName: 'Bếp Nhà'),
      createdAt: DateTime.utc(2026, 7, 11),
    ),
  ];

  @override
  Future<PostComment> create(String postId, String body) async => PostComment(
    id: 'comment-2',
    body: body.trim(),
    author: const CommentAuthor(id: 'me', displayName: 'Tôi'),
    createdAt: DateTime.utc(2026, 7, 11, 1),
  );
}

void main() {
  testWidgets('loads and sends a comment', (tester) async {
    final controller = CommentsController('post-1', _Repository());
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CommentsSheet(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Món này đẹp quá'), findsOneWidget);
    await tester.enterText(find.byKey(CommentsSheet.inputKey), 'Ngon quá!');
    await tester.tap(find.byKey(CommentsSheet.sendKey));
    await tester.pumpAndSettle();

    expect(find.text('Ngon quá!'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(CommentsSheet.inputKey))
          .controller
          ?.text,
      isEmpty,
    );
  });
}

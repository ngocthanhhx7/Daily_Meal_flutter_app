import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/edit_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FeedPost samplePost() => FeedPost.fromJson({
  '_id': 'post-1',
  'author': {'id': 'user-1', 'displayName': 'Meal'},
  'caption': 'Old caption',
  'tags': ['old'],
  'visibility': 'public',
  'createdAt': '2026-07-11T08:00:00Z',
  'updatedAt': '2026-07-11T08:00:00Z',
});

class _Repository implements PostManagementRepositoryContract {
  String? caption;
  List<String>? tags;
  String? deletedId;

  @override
  Future<FeedPost> update(
    String postId, {
    required String caption,
    required List<String> tags,
  }) async {
    this.caption = caption;
    this.tags = tags;
    return FeedPost.fromJson({
      '_id': postId,
      'author': {'id': 'user-1', 'displayName': 'Meal'},
      'caption': caption,
      'tags': tags,
      'visibility': 'public',
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T09:00:00Z',
    });
  }

  @override
  Future<void> delete(String postId) async => deletedId = postId;
}

void main() {
  testWidgets('updates caption and normalized tags', (tester) async {
    final repository = _Repository();
    FeedPost? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: EditPostScreen(
          post: samplePost(),
          repository: repository,
          mediaResolver: MediaUrlResolver(
            Uri.parse('https://api.dailymeal.site'),
          ),
          onUpdated: (post) => updated = post,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(EditPostScreen.captionKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(EditPostScreen.captionKey),
      'New caption',
    );
    await tester.enterText(
      find.byKey(EditPostScreen.tagsKey),
      '#Healthy, HOME',
    );
    await tester.scrollUntilVisible(
      find.byKey(EditPostScreen.saveKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(EditPostScreen.saveKey));
    await tester.pumpAndSettle();

    expect(repository.caption, 'New caption');
    expect(repository.tags, ['healthy', 'home']);
    expect(updated?.caption, 'New caption');
  });

  testWidgets('requires confirmation before deleting', (tester) async {
    final repository = _Repository();
    String? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: EditPostScreen(
          post: samplePost(),
          repository: repository,
          mediaResolver: MediaUrlResolver(
            Uri.parse('https://api.dailymeal.site'),
          ),
          onDeleted: (id) => deleted = id,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(EditPostScreen.deleteKey),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditPostScreen.deleteKey));
    await tester.pumpAndSettle();
    expect(repository.deletedId, isNull);
    expect(find.text('Xóa bài viết?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(repository.deletedId, 'post-1');
    expect(deleted, 'post-1');
  });
}

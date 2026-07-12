import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/data/post_lookup_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/post_editor/data/post_editor_repository.dart';
import 'package:daily_meal_flutter_app/features/post_editor/presentation/edit_post_route_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Lookup implements PostLookupRepositoryContract {
  @override
  Future<FeedPost> findByAuthor({
    required String postId,
    required String authorId,
  }) async => FeedPost.fromJson({
    '_id': postId,
    'author': {'id': authorId, 'displayName': 'Bếp Nhà'},
    'caption': 'Bữa sáng',
    'visibility': 'public',
    'createdAt': '2026-07-11T08:00:00Z',
    'updatedAt': '2026-07-11T08:00:00Z',
  });
}

class _Management implements PostManagementRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('restores edit post by id and author after refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EditPostRouteScreen(
            postId: 'p1',
            authorId: 'u1',
            lookupRepository: _Lookup(),
            managementRepository: _Management(),
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bữa sáng'), findsOneWidget);
    expect(find.text('Chỉnh sửa nội dung'), findsOneWidget);
  });
}

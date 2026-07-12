import 'package:daily_meal_flutter_app/core/network/media_url_resolver.dart';
import 'package:daily_meal_flutter_app/features/feed/data/post_lookup_repository.dart';
import 'package:daily_meal_flutter_app/features/feed/domain/feed_post.dart';
import 'package:daily_meal_flutter_app/features/feed/presentation/recipe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements PostLookupRepositoryContract {
  String? postId, authorId;
  @override
  Future<FeedPost> findByAuthor({
    required String postId,
    required String authorId,
  }) async {
    this.postId = postId;
    this.authorId = authorId;
    return FeedPost.fromJson({
      '_id': postId,
      'author': {'id': authorId, 'displayName': 'Bếp Nhà'},
      'caption': 'Bữa sáng',
      'visibility': 'public',
      'recipes': [
        {
          'imageIndex': 0,
          'title': 'Salad gà',
          'ingredients': ['Ức gà'],
          'steps': ['Trộn salad'],
        },
      ],
      'createdAt': '2026-07-11T08:00:00Z',
      'updatedAt': '2026-07-11T08:00:00Z',
    });
  }
}

void main() {
  testWidgets('restores recipe after refresh through author posts contract', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecipeScreen(
            postId: 'p1',
            authorId: 'u1',
            repository: repository,
            mediaResolver: MediaUrlResolver(
              Uri.parse('https://api.dailymeal.site'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.postId, 'p1');
    expect(repository.authorId, 'u1');
    expect(find.text('Công thức & dinh dưỡng'), findsOneWidget);
    expect(find.text('Salad gà'), findsOneWidget);
  });
}
